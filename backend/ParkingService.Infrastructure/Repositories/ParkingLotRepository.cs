// Infrastructure/Repositories/ParkingLotRepository.cs

using Microsoft.EntityFrameworkCore;
using ParkingService.Domain.Interfaces;
using ParkingService.Domain.Entities;
using ParkingService.Infrastructure.Data;

namespace ParkingService.Infrastructure.Repositories;

public class ParkingLotRepository : IParkingLotRepository
{
    private readonly ParkingDbContext _context;

    public ParkingLotRepository(ParkingDbContext context)
    {
        _context = context;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingLot?> GetByIdAsync(Guid id)
    {
        return await _context.ParkingLots
            .Include(l => l.ParkingSpots)
            .FirstOrDefaultAsync(l => l.Id == id);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<List<ParkingLot>> GetAllAsync(int page, int pageSize)
    {
        return await _context.ParkingLots
            .Include(l => l.ParkingSpots)
            .Where(l => l.IsActive)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalCountAsync()
    {
        return await _context.ParkingLots
            .Where(l => l.IsActive)
            .CountAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingLot> CreateAsync(ParkingLot parkingLot)
    {
        parkingLot.Id = Guid.NewGuid();
        parkingLot.CreatedAt = DateTime.UtcNow;
        parkingLot.UpdatedAt = DateTime.UtcNow;

        _context.ParkingLots.Add(parkingLot);
        await _context.SaveChangesAsync();
        return parkingLot;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<ParkingLot> UpdateAsync(ParkingLot parkingLot)
    {
        parkingLot.UpdatedAt = DateTime.UtcNow;
        _context.ParkingLots.Update(parkingLot);
        await _context.SaveChangesAsync();
        return parkingLot;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<bool> DeleteAsync(Guid id)
    {
        var parkingLot = await _context.ParkingLots.FindAsync(id);
        if (parkingLot == null) return false;

        parkingLot.IsActive = false;
        parkingLot.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<bool> ExistsAsync(Guid id)
    {
        return await _context.ParkingLots.AnyAsync(l => l.Id == id);
    }
    //----------------------------------------------------------------------------------------------------------------------------------------
    public async Task<List<ParkingLot>> GetAllIncludingInactiveAsync(int page, int pageSize)
    {
        return await _context.ParkingLots
            .Include(l => l.ParkingSpots)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //----------------------------------------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalCountIncludingInactiveAsync()
    {
        return await _context.ParkingLots.CountAsync();
    }
}