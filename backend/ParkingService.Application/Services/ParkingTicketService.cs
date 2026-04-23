
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;
using ParkingService.Infrastructure.Services;
using Shared.Constants;
using Shared.Exceptions;
using Shared.Messages;
using Shared.RabbitMQ;

namespace ParkingService.Application;

public class ParkingTicketService
{
    private readonly IParkingTicketRepository _ticketRepository;
    private readonly IParkingSpotRepository _parkingSpotRepository;
    private readonly IParkingLotRepository _parkingLotRepository;
    private readonly ILogger<ParkingTicketService> _logger;
    private readonly RabbitMQPublisherSingleton _publisher;
    private readonly UserServiceClient _userServiceClient;


    public ParkingTicketService(
        IParkingTicketRepository ticketRepository,
        IParkingSpotRepository parkingSpotRepository,
        IParkingLotRepository parkingLotRepository, ILogger<ParkingTicketService> logger,
        UserServiceClient userServiceClient, RabbitMQPublisherSingleton publisher)
    {
        _ticketRepository = ticketRepository;
        _parkingSpotRepository = parkingSpotRepository;
        _parkingLotRepository = parkingLotRepository;
        _userServiceClient = userServiceClient;
        _logger = logger;
        _publisher = publisher;
    }
    //------------------------------------------------------------------------------------------------------

    private ParkingTicketResponseDto MapToResponse(Ticket ticket) => new ParkingTicketResponseDto
    {
        Id = ticket.Id,
        UserId = ticket.UserId,
        SpotId = ticket.SpotId,
        SpotNumber = ticket.ParkingSpot?.SpotNumber ?? string.Empty,
        LotName = ticket.ParkingSpot?.ParkingLot?.Name ?? ticket.ParkingLot?.Name ?? string.Empty,
        LotAddress = ticket.ParkingSpot?.ParkingLot?.Address ?? ticket.ParkingLot?.Address ?? string.Empty,
        ReservationId = ticket.ReservationId,
        LicensePlate = ticket.LicensePlate,
        EntryTime = ticket.EntryTime,
        ExitTime = ticket.ExitTime,
        EndTime = ticket.EndTime,
        TotalPrice = ticket.TotalPrice,
        Status = ticket.Status,
        CreatedAt = ticket.CreatedAt,
        PaymentDeadline = ticket.PaymentDeadline,
        LateFee = ticket.LateFee
    };
    //------------------------------------------------------------------------------------------------------
    public async Task<(List<ParkingTicketResponseDto> Items, int TotalCount)> GetAllAsync(int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var items = await _ticketRepository.GetAllAsync(page, pageSize);
        var totalCount = await _ticketRepository.GetTotalCountAsync();
        return (items.Select(MapToResponse).ToList(), totalCount);
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<ParkingTicketResponseDto> GetByIdAsync(Guid id, Guid userId, string role)
    {
        var ticket = await _ticketRepository.GetByIdAsync(id);
        if (ticket == null)
            throw new NotFoundException($"Ticket with ID {id} not found.");

        if (role != Roles.Admin && ticket.UserId != userId)
            throw new AccessDeniedException("You do not have access to this ticket.");

        return MapToResponse(ticket);
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<(List<ParkingTicketResponseDto> Items, int TotalCount)> GetAllByUserIdAsync(Guid userId, int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var items = await _ticketRepository.GetAllByUserIdAsync(userId, page, pageSize);
        var totalCount = await _ticketRepository.GetTotalCountByUserIdAsync(userId);
        return (items.Select(MapToResponse).ToList(), totalCount);
    }
    //------------------------------------------------------------------------------------------------------
    public async Task<ParkingTicketResponseDto?> GetActiveByPlateAsync(string licensePlate)
    {
        var ticket = await _ticketRepository.GetActiveByLicensePlateAsync(licensePlate);
        if (ticket == null) return null;
        return MapToResponse(ticket);
    }
    //------------------------------------------------------------------------------------------------------

    // Poziva AIService kada kamera snimi tablice na ULAZU
    public async Task<ParkingTicketResponseDto> CheckInAsync(CreateParkingTicketDto dto, Guid userId)
    {
        if (string.IsNullOrWhiteSpace(dto.LicensePlate))
            throw new BadRequestException("License plate is required.");

        // Provjeri da auto već nema aktivan ticket
        var existingTicket = await _ticketRepository.GetActiveByLicensePlateAsync(dto.LicensePlate);
        if (existingTicket != null)
            throw new BadRequestException($"Vehicle '{dto.LicensePlate}' already has an active ticket.");

        var spot = await _parkingSpotRepository.GetByIdAsync(dto.SpotId);
        if (spot == null)
            throw new NotFoundException($"Parking spot with ID {dto.SpotId} not found.");

        if (spot.Status == ParkingSpotStatus.OutOfService)
            throw new BadRequestException($"Spot '{spot.SpotNumber}' is currently out of service.");

        if (spot.Status == ParkingSpotStatus.Occupied)
            throw new BadRequestException($"Spot '{spot.SpotNumber}' is currently occupied.");

        var lot = await _parkingLotRepository.GetByIdAsync(spot.LotId);
        if (lot == null)
            throw new NotFoundException("Parking lot not found.");

        if (!lot.IsActive)
            throw new BadRequestException($"Parking lot '{lot.Name}' is currently inactive.");

        DateTime? endTime = null;
        decimal? totalPrice = null;

        if (lot.Type == ParkingLotType.Open)
        {
            // Open lot — korisnik bira trajanje unaprijed 
            if (dto.DurationMinutes == null || dto.DurationMinutes <= 0)
                throw new BadRequestException("Duration in minutes is required for open parking lots.");

            endTime = DateTime.UtcNow.AddMinutes(dto.DurationMinutes.Value);
        }

        var ticket = new Ticket
        {
            UserId = userId,
            SpotId = dto.SpotId,
            ReservationId = dto.ReservationId,
            LicensePlate = dto.LicensePlate.ToUpper().Trim(),
            EntryTime = DateTime.UtcNow,
            EndTime = endTime,
            TotalPrice = totalPrice,
            Status = TicketStatus.Active
        };

        var created = await _ticketRepository.CreateAsync(ticket);
        await _parkingSpotRepository.UpdateStatusAsync(dto.SpotId, ParkingSpotStatus.Occupied);

        await _publisher.PublishAsync(RabbitMQConstants.VehicleEntryNotificationQueue, new VehicleDetectedMessage
        {
            LicensePlate = created.LicensePlate,
            UserId = userId,
            LotId = spot.LotId,
            DetectedAt = DateTime.UtcNow
        });
        var reloaded = await _ticketRepository.GetByIdAsync(created.Id);
        return MapToResponse(reloaded!);
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<ParkingTicketResponseDto> CheckInFromDetectionAsync(VehicleDetectedMessage message)
    {
       
        _logger.LogInformation("CheckInFromDetection called for plate {Plate}, LotId {LotId}", message.LicensePlate, message.LotId);

        if (string.IsNullOrWhiteSpace(message.LicensePlate))
            throw new BadRequestException("License plate is required.");

        var existingTicket = await _ticketRepository.GetActiveByLicensePlateAsync(message.LicensePlate);
        if (existingTicket != null)
            throw new BadRequestException($"Vehicle '{message.LicensePlate}' already has an active ticket.");

        var lot = await _parkingLotRepository.GetByIdAsync(message.LotId);
        if (lot == null)
            throw new NotFoundException("Parking lot not found.");
        if (!lot.IsActive)
            throw new BadRequestException($"Parking lot '{lot.Name}' is currently inactive.");

        // SpotId je opcionalan za closed parking
        if (message.SpotId != null)
        {
            var spot = await _parkingSpotRepository.GetByIdAsync(message.SpotId.Value);
            if (spot == null)
                throw new NotFoundException($"Parking spot not found.");
            if (spot.Status == ParkingSpotStatus.OutOfService)
                throw new BadRequestException($"Spot '{spot.SpotNumber}' is currently out of service.");
            if (spot.Status == ParkingSpotStatus.Occupied)
                throw new BadRequestException($"Spot '{spot.SpotNumber}' is currently occupied.");
            await _parkingSpotRepository.UpdateStatusAsync(message.SpotId.Value, ParkingSpotStatus.Occupied);
        }

        var userId = message.UserId ?? await _userServiceClient.GetUserIdByLicensePlateAsync(message.LicensePlate) ?? Guid.Empty;

        var ticket = new Ticket
        {
            UserId = userId,
            SpotId = message.SpotId,
            LotId = message.LotId,
            LicensePlate = message.LicensePlate.ToUpper().Trim(),
            EntryTime = DateTime.UtcNow,
            Status = TicketStatus.Active
        };

        var created = await _ticketRepository.CreateAsync(ticket);

        // Publish vehicle entry notification
        await _publisher.PublishAsync(RabbitMQConstants.VehicleEntryNotificationQueue, new VehicleDetectedMessage
        {
            LicensePlate = created.LicensePlate,
            UserId = userId,
            LotId = message.LotId,
            DetectedAt = DateTime.UtcNow
        });

        var reloaded = await _ticketRepository.GetByIdAsync(created.Id);
        return MapToResponse(reloaded!);
    }
    //------------------------------------------------------------------------------------------------------

    // Poziva AIService kada kamera snimi tablice na IZLASKU
    public async Task<ParkingTicketResponseDto> CheckOutAsync(string licensePlate)
    {
        var ticket = await _ticketRepository.GetActiveByLicensePlateAsync(licensePlate);
        if (ticket == null)
            throw new NotFoundException($"No active ticket found for vehicle '{licensePlate}'.");

        // Dohvati lot — ili preko SpotId ili direktno preko LotId
        Guid lotId;
        if (ticket.ParkingSpot != null)
            lotId = ticket.ParkingSpot.LotId;
        else if (ticket.LotId != null)
            lotId = ticket.LotId.Value;
        else
            throw new NotFoundException("Cannot determine parking lot for this ticket.");

        var lot = await _parkingLotRepository.GetByIdAsync(lotId);
        if (lot == null)
            throw new NotFoundException("Parking lot not found.");

        ticket.ExitTime = DateTime.UtcNow;
        ticket.PaymentDeadline = DateTime.UtcNow.AddHours(24);

        if (lot.Type == ParkingLotType.Closed)
        {
            var totalMinutes = (decimal)(ticket.ExitTime.Value - ticket.EntryTime).TotalMinutes;
            ticket.TotalPrice = totalMinutes * lot.RatePerMinute;
        }

        ticket.Status = TicketStatus.PendingPayment;
        var updated = await _ticketRepository.UpdateAsync(ticket);

        // Oslobodi spot samo ako postoji
        if (ticket.SpotId != null)
            await _parkingSpotRepository.UpdateStatusAsync(ticket.SpotId.Value, ParkingSpotStatus.Available);


        // Stavi:
        await _publisher.PublishAsync(RabbitMQConstants.TicketClosedQueue, new TicketClosedMessage
        {
            TicketId = updated.Id,
            UserId = updated.UserId,
            LicensePlate = updated.LicensePlate,
            TotalPrice = updated.TotalPrice ?? 0,
            ExitTime = updated.ExitTime!.Value
        });
        await _publisher.PublishAsync(RabbitMQConstants.VehicleExitNotificationQueue, new TicketClosedMessage
        {
            TicketId = updated.Id,
            UserId = updated.UserId,
            LicensePlate = updated.LicensePlate,
            TotalPrice = updated.TotalPrice ?? 0,
            ExitTime = updated.ExitTime!.Value
        });


        return MapToResponse(updated);


    }

    //------------------------------------------------------------------------------------------------------
    public async Task<ParkingTicketResponseDto> ExtendAsync(Guid id, int additionalMinutes, Guid userId, string role)
    {
        var ticket = await _ticketRepository.GetByIdAsync(id);
        if (ticket == null)
            throw new NotFoundException($"Ticket with ID {id} not found.");

        if (role != Roles.Admin && ticket.UserId != userId)
            throw new AccessDeniedException("You do not have access to this ticket.");

        if (ticket.Status != TicketStatus.Active)
            throw new BadRequestException("Only active tickets can be extended.");

        var lot = await _parkingLotRepository.GetByIdAsync(ticket.ParkingSpot!.LotId);
        if (lot == null)
            throw new NotFoundException("Parking lot not found.");

        if (lot.Type != ParkingLotType.Open)
            throw new BadRequestException("Only tickets for open parking lots can be extended.");

        if (additionalMinutes <= 0)
            throw new BadRequestException("Additional minutes must be greater than 0.");

        var additionalPrice = (decimal)additionalMinutes * lot.RatePerMinute;

        ticket.EndTime = ticket.EndTime!.Value.AddMinutes(additionalMinutes);
        ticket.TotalPrice = (ticket.TotalPrice ?? 0) + additionalPrice;

        var updated = await _ticketRepository.UpdateAsync(ticket);
        return MapToResponse(updated);
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<ParkingTicketResponseDto> PayAsync(Guid id, Guid userId, string role)
    {
        var ticket = await _ticketRepository.GetByIdAsync(id);
        if (ticket == null)
            throw new NotFoundException($"Ticket with ID {id} not found.");

        if (role != Roles.Admin && ticket.UserId != userId)
            throw new AccessDeniedException("You do not have access to this ticket.");

        if (ticket.Status != TicketStatus.PendingPayment)
            throw new BadRequestException("Only tickets pending payment can be paid.");

        ticket.Status = TicketStatus.Paid;
        var updated = await _ticketRepository.UpdateAsync(ticket);
        return MapToResponse(updated);
    }
    //------------------------------------------------------------------------------------------------------

   
    public async Task<List<ParkingTicketResponseDto>> GetActiveByUserIdAsync(Guid userId)
    {
        var tickets = await _ticketRepository.GetActiveByUserIdAsync(userId);
        return tickets.Select(MapToResponse).ToList();
    }
}