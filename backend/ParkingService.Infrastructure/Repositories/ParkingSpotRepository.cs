// Infrastructure/Repositories/ParkingSpotRepository.cs

using Microsoft.EntityFrameworkCore;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Interfaces;
using ParkingService.Infrastructure.Data;
using ParkingService.Domain.Enums;

namespace ParkingService.Infrastructure.Repositories;

public class ParkingSpotRepository : IParkingSpotRepository
{
    private readonly ParkingDbContext _context;

    public ParkingSpotRepository(ParkingDbContext context)
    {
        _context = context;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingSpot?> GetByIdAsync(Guid id)
    {
        return await _context.ParkingSpots
            .Include(s => s.ParkingLot)
            .FirstOrDefaultAsync(s => s.Id == id);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<List<ParkingSpot>> GetAllByLotIdAsync(Guid lotId, int page, int pageSize)
    {
        return await _context.ParkingSpots
            .Include(s => s.ParkingLot)
            .Where(s => s.LotId == lotId)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<List<ParkingSpot>> GetAvailableByLotIdAsync(Guid lotId)
    {
        return await _context.ParkingSpots
            .Where(s => s.LotId == lotId && s.Status == ParkingSpotStatus.Available)
            .ToListAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalCountByLotIdAsync(Guid lotId)
    {
        return await _context.ParkingSpots
            .Where(s => s.LotId == lotId)
            .CountAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingSpot> CreateAsync(ParkingSpot spot)
    {
        spot.Id = Guid.NewGuid();
        spot.CreatedAt = DateTime.UtcNow;
        spot.UpdatedAt = DateTime.UtcNow;

        _context.ParkingSpots.Add(spot);
        await _context.SaveChangesAsync();
        return spot;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingSpot> UpdateAsync(ParkingSpot spot)
    {
        spot.UpdatedAt = DateTime.UtcNow;
        _context.ParkingSpots.Update(spot);
        await _context.SaveChangesAsync();
        return spot;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<bool> DeleteAsync(Guid id)
    {
        var spot = await _context.ParkingSpots.FindAsync(id);
        if (spot == null) return false;

        spot.IsDeleted = true;
        spot.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<bool> ExistsAsync(Guid id)
    {
        return await _context.ParkingSpots.AnyAsync(s => s.Id == id);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task UpdateStatusAsync(Guid id, ParkingSpotStatus status)
    {
        var spot = await _context.ParkingSpots.FindAsync(id);
        if (spot == null) return;

        spot.Status = status;
        spot.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

}