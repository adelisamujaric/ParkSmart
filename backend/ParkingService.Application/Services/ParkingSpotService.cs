// Application/ParkingSpotService.cs

using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Interfaces;
using ParkingService.Domain.Enums;
using Shared.Exceptions;

namespace ParkingService.Application;

public class ParkingSpotService
{
    private readonly IParkingSpotRepository _parkingSpotRepository;
    private readonly IParkingLotRepository _parkingLotRepository;

    public ParkingSpotService(IParkingSpotRepository parkingSpotRepository, IParkingLotRepository parkingLotRepository)
    {
        _parkingSpotRepository = parkingSpotRepository;
        _parkingLotRepository = parkingLotRepository;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------
    private ParkingSpotResponseDto MapToResponse(ParkingSpot spot) => new ParkingSpotResponseDto
    {
        Id = spot.Id,
        LotId = spot.LotId,
        LotName = spot.ParkingLot?.Name ?? string.Empty,
        SpotNumber = spot.SpotNumber,
        Type = spot.Type,
        Status = spot.Status,
        Floor = spot.Floor,
        CreatedAt = spot.CreatedAt,
        IsReservable = spot.IsReservable,
        
    };
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingSpotResponseDto> GetByIdAsync(Guid id)
    {
        var spot = await _parkingSpotRepository.GetByIdAsync(id);
        if (spot == null)
            throw new NotFoundException($"Parking spot with ID {id} not found.");

        return MapToResponse(spot);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<(List<ParkingSpotResponseDto> Items, int TotalCount)> GetAllByLotIdAsync(Guid lotId, int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var lot = await _parkingLotRepository.GetByIdAsync(lotId);
        if (lot == null)
            throw new NotFoundException($"Parking lot with ID {lotId} not found.");

        var items = await _parkingSpotRepository.GetAllByLotIdAsync(lotId, page, pageSize);
        var totalCount = await _parkingSpotRepository.GetTotalCountByLotIdAsync(lotId);
        return (items.Select(MapToResponse).ToList(), totalCount);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<List<ParkingSpotResponseDto>> GetAvailableByLotIdAsync(Guid lotId)
    {
        var lot = await _parkingLotRepository.GetByIdAsync(lotId);
        if (lot == null)
            throw new NotFoundException($"Parking lot with ID {lotId} not found.");

        if (!lot.IsActive)
            throw new BadRequestException($"Parking lot '{lot.Name}' is currently inactive.");

        var spots = await _parkingSpotRepository.GetAvailableByLotIdAsync(lotId);

        if (!spots.Any())
            throw new NotFoundException($"No available spots found in parking lot '{lot.Name}'.");

        return spots.Select(MapToResponse).ToList();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingSpotResponseDto> CreateAsync(CreateParkingSpotDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.SpotNumber))
            throw new BadRequestException("Spot number is required.");

        var lot = await _parkingLotRepository.GetByIdAsync(dto.LotId);
        if (lot == null)
            throw new NotFoundException($"Parking lot with ID {dto.LotId} not found.");

        if (!lot.IsActive)
            throw new BadRequestException($"Cannot add spots to inactive parking lot '{lot.Name}'.");

        var existingSpots = await _parkingSpotRepository.GetAllByLotIdAsync(dto.LotId, 1, int.MaxValue);
        if (existingSpots.Any(s => s.SpotNumber == dto.SpotNumber))
            throw new BadRequestException($"Spot number '{dto.SpotNumber}' already exists in this parking lot.");

        var currentCount = await _parkingSpotRepository.GetTotalCountByLotIdAsync(dto.LotId);
        if (currentCount >= lot.TotalSpots)
            throw new BadRequestException($"Parking lot '{lot.Name}' has reached its maximum capacity of {lot.TotalSpots} spots.");

        var spot = new ParkingSpot
        {
            LotId = dto.LotId,
            SpotNumber = dto.SpotNumber,
            Type = dto.Type,
            Floor = dto.Floor,
            Status = ParkingSpotStatus.Available,
            IsReservable = dto.IsReservable,
            
        };

        var created = await _parkingSpotRepository.CreateAsync(spot);

        // reload sa navigation propertyjem
        var reloaded = await _parkingSpotRepository.GetByIdAsync(created.Id);
        return MapToResponse(reloaded!);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingSpotResponseDto> UpdateAsync(Guid id, UpdateParkingSpotDto dto)
    {
        var spot = await _parkingSpotRepository.GetByIdAsync(id);
        if (spot == null)
            throw new NotFoundException($"Parking spot with ID {id} not found.");

        if (spot.Status == ParkingSpotStatus.Occupied)
            throw new BadRequestException("Cannot update a spot that is currently occupied.");

        if (dto.SpotNumber != null)
        {
            var existingSpots = await _parkingSpotRepository.GetAllByLotIdAsync(spot.LotId, 1, int.MaxValue);
            if (existingSpots.Any(s => s.SpotNumber == dto.SpotNumber && s.Id != id))
                throw new BadRequestException($"Spot number '{dto.SpotNumber}' already exists in this parking lot.");

            spot.SpotNumber = dto.SpotNumber;
        }

        if (dto.Type.HasValue) spot.Type = dto.Type.Value;
        if (dto.Floor.HasValue) spot.Floor = dto.Floor.Value;
        if (dto.IsReservable.HasValue) spot.IsReservable = dto.IsReservable.Value;


        var updated = await _parkingSpotRepository.UpdateAsync(spot);
        return MapToResponse(updated);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<bool> DeleteAsync(Guid id)
    {
        var spot = await _parkingSpotRepository.GetByIdAsync(id);
        if (spot == null)
            throw new NotFoundException($"Parking spot with ID {id} not found.");

        if (spot.Status == ParkingSpotStatus.Occupied)
            throw new BadRequestException("Cannot delete a spot that is currently occupied.");

        if (spot.Status == ParkingSpotStatus.Reserved)
            throw new BadRequestException("Cannot delete a spot that has an active reservation.");

        return await _parkingSpotRepository.DeleteAsync(id);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task UpdateStatusAsync(Guid id, ParkingSpotStatus status)
    {
        var spot = await _parkingSpotRepository.GetByIdAsync(id);
        if (spot == null)
            throw new NotFoundException($"Parking spot with ID {id} not found.");

        if (spot.Status == status)
            throw new BadRequestException($"Spot is already in status '{status}'.");

        await _parkingSpotRepository.UpdateStatusAsync(id, status);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

}