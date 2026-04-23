
using Microsoft.Extensions.Configuration;
using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;
using Shared.Constants;
using Shared.Exceptions;
using Shared.RabbitMQ;

namespace ParkingService.Application;

public class ReservationService
{
    private readonly IParkingReservationRepository _reservationRepository;
    private readonly IParkingSpotRepository _parkingSpotRepository;
    private readonly IParkingLotRepository _parkingLotRepository;
    private readonly RabbitMQPublisherSingleton _publisher;

    public ReservationService(
        IParkingReservationRepository reservationRepository,
        IParkingSpotRepository parkingSpotRepository,
        IParkingLotRepository parkingLotRepository, RabbitMQPublisherSingleton publisher)
    {
        _reservationRepository = reservationRepository;
        _parkingSpotRepository = parkingSpotRepository;
        _parkingLotRepository = parkingLotRepository;
        _publisher = publisher;

    }
    //---------------------------------------------------------------------------------------------------------------------------
    private ParkingReservationResponseDto MapToResponse(Reservation reservation) => new ParkingReservationResponseDto
    {
        Id = reservation.Id,
        UserId = reservation.UserId,
        SpotId = reservation.SpotId,
        SpotNumber = reservation.ParkingSpot?.SpotNumber ?? string.Empty,
        LotName = reservation.ParkingSpot?.ParkingLot?.Name ?? string.Empty,
        LotAddress = reservation.ParkingSpot?.ParkingLot?.Address ?? string.Empty,
        LicensePlate = reservation.LicensePlate,
        StartTime = reservation.StartTime,
        EndTime = reservation.EndTime,
        TotalPrice = reservation.TotalPrice,
        Status = reservation.Status,
        CreatedAt = reservation.CreatedAt
    };
    //---------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingReservationResponseDto> GetByIdAsync(Guid id, Guid userId, string role)
    {
        var reservation = await _reservationRepository.GetByIdAsync(id);
        if (reservation == null)
            throw new NotFoundException($"Reservation with ID {id} not found.");

        if (role != Roles.Admin && reservation.UserId != userId)
                throw new AccessDeniedException("You do not have access to this reservation.");

        return MapToResponse(reservation);
    }
    //---------------------------------------------------------------------------------------------------------------------------

    public async Task<(List<ParkingReservationResponseDto> Items, int TotalCount)> GetAllByUserIdAsync(Guid userId, int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var items = await _reservationRepository.GetAllByUserIdAsync(userId, page, pageSize);
        var totalCount = await _reservationRepository.GetTotalCountByUserIdAsync(userId);
        return (items.Select(MapToResponse).ToList(), totalCount);
    }
    //---------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingReservationResponseDto> CreateAsync(CreateReservationDto dto, Guid userId)
    {
        if (string.IsNullOrWhiteSpace(dto.LicensePlate))
            throw new BadRequestException("License plate is required.");

        if (dto.StartTime >= dto.EndTime)
            throw new BadRequestException("Start time must be before end time.");

        if (dto.StartTime < DateTime.UtcNow)
            throw new BadRequestException("Start time cannot be in the past.");

        if ((dto.EndTime - dto.StartTime).TotalMinutes < 5)
            throw new BadRequestException("Reservation must be at least 5 minutes long.");

        var spot = await _parkingSpotRepository.GetByIdAsync(dto.SpotId);
        if (spot == null)
            throw new NotFoundException($"Parking spot with ID {dto.SpotId} not found.");

        if (!spot.IsReservable)
            throw new BadRequestException($"Spot '{spot.SpotNumber}' is not available for reservation.");

        if (spot.Status == ParkingSpotStatus.OutOfService)
            throw new BadRequestException($"Spot '{spot.SpotNumber}' is currently out of service.");

        var lot = await _parkingLotRepository.GetByIdAsync(spot.LotId);
        if (lot == null)
            throw new NotFoundException("Parking lot not found.");

        if (!lot.IsActive)
            throw new BadRequestException($"Parking lot '{lot.Name}' is currently inactive.");

        var hasConflict = await _reservationRepository.HasConflictingReservationAsync(dto.SpotId, dto.StartTime, dto.EndTime);
        if (hasConflict)
            throw new BadRequestException($"Spot '{spot.SpotNumber}' is already reserved for the selected time period.");

        var totalMinutes = (decimal)(dto.EndTime - dto.StartTime).TotalMinutes;

        if (lot.ReservationRatePerMinute == null)
            throw new BadRequestException($"Parking lot '{lot.Name}' does not have a reservation rate configured.");

        var totalPrice = totalMinutes * lot.ReservationRatePerMinute.Value;

        var reservation = new Reservation
        {
            UserId = userId,
            SpotId = dto.SpotId,
            LicensePlate = dto.LicensePlate.ToUpper().Trim(),
            StartTime = dto.StartTime,
            EndTime = dto.EndTime,
            TotalPrice = totalPrice,
            Status = ReservationStatus.Confirmed
        };

        var created = await _reservationRepository.CreateAsync(reservation);
        await _parkingSpotRepository.UpdateStatusAsync(dto.SpotId, ParkingSpotStatus.Reserved);

        // Pošalji notifikaciju
        await _publisher.PublishAsync(RabbitMQConstants.ReservationCreatedQueue, new ReservationCreatedMessage
        {
            ReservationId = created.Id,
            UserId = userId,
            LicensePlate = created.LicensePlate,
            LotName = lot.Name,
            StartTime = created.StartTime,
            EndTime = created.EndTime
        });



        var reloaded = await _reservationRepository.GetByIdAsync(created.Id);
        return MapToResponse(reloaded!);
    }
    //---------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingReservationResponseDto> CancelAsync(Guid id, Guid userId, string role)
    {
        var reservation = await _reservationRepository.GetByIdAsync(id);
        if (reservation == null)
            throw new NotFoundException($"Reservation with ID {id} not found.");

        if (role != Roles.Admin && reservation.UserId != userId)
            throw new AccessDeniedException("You do not have access to this reservation.");

        if (reservation.Status == ReservationStatus.Cancelled)
            throw new BadRequestException("Reservation is already cancelled.");

        if (reservation.Status == ReservationStatus.Completed)
            throw new BadRequestException("Cannot cancel a completed reservation.");

        reservation.Status = ReservationStatus.Cancelled;
        var updated = await _reservationRepository.UpdateAsync(reservation);
        await _parkingSpotRepository.UpdateStatusAsync(reservation.SpotId, ParkingSpotStatus.Available);

        return MapToResponse(updated);
    }
    //---------------------------------------------------------------------------------------------------------------------------

    public async Task ExpireReservationsAsync()
    {
        var expired = await _reservationRepository.GetExpiredReservationsAsync();
        foreach (var reservation in expired)
        {
            reservation.Status = ReservationStatus.Expired;
            await _reservationRepository.UpdateAsync(reservation);
            await _parkingSpotRepository.UpdateStatusAsync(reservation.SpotId, ParkingSpotStatus.Available);
        }
    }
    //---------------------------------------------------------------------------------------------------------------------------
    public async Task<ParkingReservationResponseDto> PayAsync(Guid id, Guid userId, string role)
    {
        var reservation = await _reservationRepository.GetByIdAsync(id);
        if (reservation == null)
            throw new NotFoundException($"Reservation with ID {id} not found.");

        if (role != Roles.Admin && reservation.UserId != userId)
            throw new AccessDeniedException("You do not have access to this reservation.");

        if (reservation.Status != ReservationStatus.Confirmed &&
            reservation.Status != ReservationStatus.Expired)
            throw new BadRequestException("Only active or expired reservations can be paid.");

        reservation.Status = ReservationStatus.Completed;
        var updated = await _reservationRepository.UpdateAsync(reservation);
        return MapToResponse(updated);
    }
}