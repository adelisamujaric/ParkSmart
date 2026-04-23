using Microsoft.Extensions.Caching.Memory;
using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;
using Shared.Exceptions;

namespace ParkingService.Application;

public class ParkingLotService
{
    private readonly IParkingLotRepository _parkingLotRepository;
    private readonly IMemoryCache _cache; 
    private const string CacheKeyAll = "parking_lots_all";
    private const string CacheKeyById = "parking_lot_";

    public ParkingLotService(
        IParkingLotRepository parkingLotRepository,
        IMemoryCache cache) 
    {
        _parkingLotRepository = parkingLotRepository;
        _cache = cache; 
    }

    private ParkingLotResponseDto MapToResponse(ParkingLot lot) => new ParkingLotResponseDto
    {
        Id = lot.Id,
        Name = lot.Name,
        Address = lot.Address,
        Type = lot.Type,
        TotalSpots = lot.TotalSpots,
        RatePerMinute = lot.RatePerMinute,
        ReservationRatePerMinute = lot.ReservationRatePerMinute,
        OpenTime = lot.OpenTime,
        CloseTime = lot.CloseTime,
        IsActive = lot.IsActive,
        CreatedAt = lot.CreatedAt
    };

    public async Task<ParkingLotResponseDto> GetByIdAsync(Guid id)
    {
        var cacheKey = $"{CacheKeyById}{id}";
        if (_cache.TryGetValue(cacheKey, out ParkingLotResponseDto? cached))
            return cached!;

        var parkingLot = await _parkingLotRepository.GetByIdAsync(id);
        if (parkingLot == null)
            throw new NotFoundException($"Parking lot with ID {id} not found.");

        var response = MapToResponse(parkingLot);
        _cache.Set(cacheKey, response, TimeSpan.FromMinutes(5));
        return response;
    }

    public async Task<(List<ParkingLotResponseDto> Items, int TotalCount)> GetAllAsync(int page, int pageSize)
    {
        if (page <= 0 || pageSize <= 0)
            throw new BadRequestException("Page and page size must be greater than 0.");

        var cacheKey = $"{CacheKeyAll}_{page}_{pageSize}";
        if (_cache.TryGetValue(cacheKey, out (List<ParkingLotResponseDto>, int) cached))
            return cached;

        var items = await _parkingLotRepository.GetAllAsync(page, pageSize);
        var totalCount = await _parkingLotRepository.GetTotalCountAsync();
        var result = (items.Select(MapToResponse).ToList(), totalCount);
        _cache.Set(cacheKey, result, TimeSpan.FromMinutes(5));
        return result;
    }

    public async Task<ParkingLotResponseDto> CreateAsync(CreateParkingLotDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
            throw new BadRequestException("Parking lot name is required.");
        if (string.IsNullOrWhiteSpace(dto.Address))
            throw new BadRequestException("Parking lot address is required.");
        if (!Enum.IsDefined(typeof(ParkingLotType), dto.Type))
            throw new BadRequestException("Invalid parking lot type.");
        if (dto.TotalSpots <= 0)
            throw new BadRequestException("Total spots must be greater than 0.");
        if (dto.RatePerMinute <= 0)
            throw new BadRequestException("Rate per minute must be greater than 0.");
        if (dto.OpenTime >= dto.CloseTime)
            throw new BadRequestException("Open time must be before close time.");

        var parkingLot = new ParkingLot
        {
            Name = dto.Name,
            Address = dto.Address,
            TotalSpots = dto.TotalSpots,
            RatePerMinute = dto.RatePerMinute,
            OpenTime = dto.OpenTime,
            CloseTime = dto.CloseTime
        };

        var created = await _parkingLotRepository.CreateAsync(parkingLot);
        _cache.Remove(CacheKeyAll); // Invalidate cache
        return MapToResponse(created);
    }

    public async Task<ParkingLotResponseDto> UpdateAsync(Guid id, UpdateParkingLotDto dto)
    {
        var existing = await _parkingLotRepository.GetByIdAsync(id);
        if (existing == null)
            throw new NotFoundException($"Parking lot with ID {id} not found.");

        if (dto.TotalSpots.HasValue && dto.TotalSpots <= 0)
            throw new BadRequestException("Total spots must be greater than 0.");
        if (dto.RatePerMinute.HasValue && dto.RatePerMinute <= 0)
            throw new BadRequestException("Rate per minute must be greater than 0.");
        if (dto.OpenTime.HasValue && dto.CloseTime.HasValue && dto.OpenTime >= dto.CloseTime)
            throw new BadRequestException("Open time must be before close time.");

        if (dto.Name != null) existing.Name = dto.Name;
        if (dto.Address != null) existing.Address = dto.Address;
        if (dto.TotalSpots.HasValue) existing.TotalSpots = dto.TotalSpots.Value;
        if (dto.RatePerMinute.HasValue) existing.RatePerMinute = dto.RatePerMinute.Value;
        if (dto.OpenTime.HasValue) existing.OpenTime = dto.OpenTime.Value;
        if (dto.CloseTime.HasValue) existing.CloseTime = dto.CloseTime.Value;
        if (dto.IsActive.HasValue) existing.IsActive = dto.IsActive.Value;

        var updated = await _parkingLotRepository.UpdateAsync(existing);

        // Invalidate cache
        _cache.Remove($"{CacheKeyById}{id}");
        _cache.Remove(CacheKeyAll);

        return MapToResponse(updated);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var existing = await _parkingLotRepository.GetByIdAsync(id);
        if (existing == null)
            throw new NotFoundException($"Parking lot with ID {id} not found.");

        var result = await _parkingLotRepository.DeleteAsync(id);

        // Invalidate cache
        _cache.Remove($"{CacheKeyById}{id}");
        _cache.Remove(CacheKeyAll);

        return result;
    }

    public async Task<(List<ParkingLotResponseDto> Items, int TotalCount)> GetAllIncludingInactiveAsync(int page, int pageSize)
    {
        var items = await _parkingLotRepository.GetAllIncludingInactiveAsync(page, pageSize);
        var totalCount = await _parkingLotRepository.GetTotalCountIncludingInactiveAsync();
        return (items.Select(MapToResponse).ToList(), totalCount);
    }
}