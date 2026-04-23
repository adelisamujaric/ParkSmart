
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Interfaces;
using Shared.Exceptions;
using Shared.Messages;
using Shared.RabbitMQ;

namespace ParkingService.Application;

public class ViolationService
{
    private readonly IParkingViolationRepository _violationRepository;
    private readonly IParkingSpotRepository _parkingSpotRepository;
    private readonly IViolationConfigRepository _violationConfigRepository;
    private readonly ILogger<ViolationService> _logger;
    private readonly RabbitMQPublisherSingleton _publisher; 

    public ViolationService(
        IParkingViolationRepository violationRepository,
        IParkingSpotRepository parkingSpotRepository,
        IViolationConfigRepository violationConfigRepository,
        ILogger<ViolationService> logger,
        RabbitMQPublisherSingleton publisher) 
    {
        _violationRepository = violationRepository;
        _parkingSpotRepository = parkingSpotRepository;
        _violationConfigRepository = violationConfigRepository;
        _logger = logger;
        _publisher = publisher; 
    }
    //--------------------------------------------------------------------------------------------------------------------------

    private ParkingViolationResponseDto MapToResponse(Violation violation) => new ParkingViolationResponseDto
    {
        Id = violation.Id,
        UserId = violation.UserId,
        SpotNumber = violation.ParkingSpot?.SpotNumber ?? string.Empty,
        LotName = violation.ParkingSpot?.ParkingLot?.Name ?? string.Empty,
        TicketId = violation.TicketId,
        LicensePlate = violation.LicensePlate,
        Description = violation.Description,
        PhotoUrl = violation.PhotoUrl,
        FineAmount = violation.FineAmount,
       
        IsResolved = violation.IsResolved,
        CreatedAt = violation.CreatedAt,
        ViolationConfigId = violation.ViolationConfigId,
        TypeName = violation.ViolationConfig?.TypeName ?? string.Empty,
    };
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingViolationResponseDto> GetByIdAsync(Guid id)
    {
        var violation = await _violationRepository.GetByIdAsync(id);
        if (violation == null)
            throw new NotFoundException($"Violation with ID {id} not found.");

        return MapToResponse(violation);
    }
    //--------------------------------------------------------------------------------------------------------------------------
    public async Task<(List<ParkingViolationResponseDto> Items, int TotalCount)> GetAllByLicensePlateAsync(string licensePlate, int page, int pageSize)
    {
        if (string.IsNullOrWhiteSpace(licensePlate))
            throw new BadRequestException("License plate is required.");

        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var items = await _violationRepository.GetAllByLicensePlateAsync(licensePlate, page, pageSize);
        var totalCount = await _violationRepository.GetTotalCountByLicensePlateAsync(licensePlate);

        return (items.Select(MapToResponse).ToList(), totalCount);
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<(List<ParkingViolationResponseDto> Items, int TotalCount)> GetAllUnresolvedAsync(int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var items = await _violationRepository.GetAllUnresolvedAsync(page, pageSize);
        var totalCount = await _violationRepository.GetTotalUnresolvedCountAsync();
        return (items.Select(MapToResponse).ToList(), totalCount);
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingViolationResponseDto> CreateAsync(CreateParkingViolationDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.LicensePlate))
            throw new BadRequestException("License plate is required.");


        decimal fineAmount = dto.FineAmount;
        string description = dto.Description ?? "Prekršaj";

        if (dto.ViolationConfigId != Guid.Empty)
        {
            var config = await _violationConfigRepository.GetByIdAsync(dto.ViolationConfigId);
            if (config != null)
            {
                fineAmount = config.FineAmount;
                description = config.Description;
            }
        }

        var violation = new Violation
        {
            UserId = dto.UserId,
            SpotId = dto.SpotId,
            TicketId = dto.TicketId,
            LicensePlate = dto.LicensePlate.ToUpper().Trim(),
            ViolationConfigId = dto.ViolationConfigId,
            Description = description,
            PhotoUrl = dto.PhotoUrl,
            FineAmount = fineAmount,
            IsResolved = false
        };

        var created = await _violationRepository.CreateAsync(violation);
        var reloaded = await _violationRepository.GetByIdAsync(created.Id);

        return MapToResponse(reloaded!);
    }
    //--------------------------------------------------------------------------------------------------------------------------
    public async Task<ParkingViolationResponseDto> CreateViolationFromDetectionAsync(ViolationConfirmedMessage message)
    {
        
        _logger.LogInformation("Creating violation from detection for plate {Plate}, SpotId {SpotId}", message.LicensePlate, message.SpotId);


        if (string.IsNullOrWhiteSpace(message.LicensePlate))
            throw new BadRequestException("License plate is required.");


        decimal fineAmount = message.FineAmount;
        string description = "Prekrsaj detektovan";

        if (message.ViolationConfigId != Guid.Empty)
        {
            var config = await _violationConfigRepository.GetByIdAsync(message.ViolationConfigId);
            if (config != null)
            {
                fineAmount = config.FineAmount;
                description = config.Description; 
            }
        }

        var violation = new Violation
        {
            UserId = message.UserId ?? Guid.Empty,
            SpotId = message.SpotId,
            LotId = message.LotId,
            LicensePlate = message.LicensePlate.ToUpper().Trim(),
            ViolationConfigId = message.ViolationConfigId,
            Description = description,
            PhotoUrl = message.ImageUrl,
            FineAmount = fineAmount,
            IsResolved = false
        };

        var created = await _violationRepository.CreateAsync(violation);
        var reloaded = await _violationRepository.GetByIdAsync(created.Id);

        // Publish violation.created event
        await _publisher.PublishAsync(RabbitMQConstants.ViolationCreatedQueue, new ViolationCreatedMessage
        {
            ViolationId = reloaded!.Id,
            UserId = reloaded.UserId,
            LicensePlate = reloaded.LicensePlate,
            FineAmount = reloaded.FineAmount,
            CreatedAt = reloaded.CreatedAt
        });

        return MapToResponse(reloaded!);
    }
   
    
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingViolationResponseDto> ResolveAsync(Guid id)
    {
        var violation = await _violationRepository.GetByIdAsync(id);
        if (violation == null)
            throw new NotFoundException($"Violation with ID {id} not found.");

        if (violation.IsResolved)
            throw new BadRequestException("Violation is already resolved.");

        violation.IsResolved = true;
        var updated = await _violationRepository.UpdateAsync(violation);
        return MapToResponse(updated);
    }
    //--------------------------------------------------------------------------------------------------------------------------
    public async Task<ParkingViolationResponseDto> ConfirmAsync(Guid id)
    {
        var violation = await _violationRepository.GetByIdAsync(id);
        if (violation == null)
            throw new NotFoundException($"Violation with ID {id} not found.");

        violation.UpdatedAt = DateTime.UtcNow;
        var updated = await _violationRepository.UpdateAsync(violation);
        return MapToResponse(updated);
    }

    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<List<ParkingViolationResponseDto>> GetAllByUserIdAsync(Guid userId)
    {
        var violations = await _violationRepository.GetAllByUserIdAsync(userId);
        return violations.Select(v => new ParkingViolationResponseDto
        {
            Id = v.Id,
            UserId = v.UserId,
            SpotId = v.SpotId,
            SpotNumber = v.ParkingSpot?.SpotNumber ?? string.Empty,
            LotName = v.ParkingLot?.Name ?? string.Empty,
            TicketId = v.TicketId,
            LicensePlate = v.LicensePlate,
            ViolationConfigId = v.ViolationConfigId,
            TypeName = v.ViolationConfig?.TypeName ?? string.Empty,
            ConfigFineAmount = v.ViolationConfig?.FineAmount ?? 0,
            Description = v.Description,
            PhotoUrl = v.PhotoUrl,
            FineAmount = v.FineAmount,
            IsResolved = v.IsResolved,
            CreatedAt = v.CreatedAt,
        }).ToList();
    }

}