
using Microsoft.EntityFrameworkCore;
using ParkingService.Infrastructure.Data;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;

namespace ParkingService.Infrastructure.Repositories;

public class ParkingViolationRepository : IParkingViolationRepository
{
    private readonly ParkingDbContext _context;

    public ParkingViolationRepository(ParkingDbContext context)
    {
        _context = context;
    }
    //--------------------------------------------------------------------------------------------------------------------------
    public async Task<Violation?> GetByIdAsync(Guid id)
    {
        return await _context.Violations
            .Include(v => v.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Include(v => v.Ticket)
            .FirstOrDefaultAsync(v => v.Id == id);
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<List<Violation>> GetAllByLicensePlateAsync(string licensePlate, int page, int pageSize)
    {
        return await _context.Violations
            .Include(v => v.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Where(v => v.LicensePlate == licensePlate.ToUpper().Trim())
            .OrderByDescending(v => v.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<List<Violation>> GetAllUnresolvedAsync(int page, int pageSize)
    {
        return await _context.Violations
            .Include(v => v.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Where(v => !v.IsResolved)
            .OrderByDescending(v => v.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalCountByLicensePlateAsync(string licensePlate)
    {
        return await _context.Violations
            .Where(v => v.LicensePlate == licensePlate.ToUpper().Trim())
            .CountAsync();
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalUnresolvedCountAsync()
    {
        return await _context.Violations
            .Where(v => !v.IsResolved)
            .CountAsync();
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<Violation> CreateAsync(Violation violation)
    {
        violation.Id = Guid.NewGuid();
        violation.CreatedAt = DateTime.UtcNow;
        violation.UpdatedAt = DateTime.UtcNow;

        _context.Violations.Add(violation);
        await _context.SaveChangesAsync();
        return violation;
    }
    //--------------------------------------------------------------------------------------------------------------------------

    public async Task<Violation> UpdateAsync(Violation violation)
    {
        violation.UpdatedAt = DateTime.UtcNow;
        _context.Violations.Update(violation);
        await _context.SaveChangesAsync();
        return violation;
    }
    //--------------------------------------------------------------------------------------------------------------------------
   
    public async Task<List<Violation>> GetAllByUserIdAsync(Guid userId)
    {
        return await _context.Violations
            .Include(v => v.ParkingLot)
            .Include(v => v.ViolationConfig)
            .Include(v => v.ParkingSpot)
            .Where(v => v.UserId == userId)
            .OrderByDescending(v => v.CreatedAt)
            .ToListAsync();
    }
}