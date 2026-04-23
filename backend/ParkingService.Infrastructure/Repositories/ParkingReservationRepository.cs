// Infrastructure/Repositories/ReservationRepository.cs

using Microsoft.EntityFrameworkCore;
using ParkingService.Domain.Enums;
using ParkingService.Infrastructure.Data;
using ParkingService.Domain.Interfaces;
using ParkingService.Domain.Entities;

namespace ParkingService.Infrastructure.Repositories;

public class ParkingReservationRepository : IParkingReservationRepository
{
    private readonly ParkingDbContext _context;

    public ParkingReservationRepository(ParkingDbContext context)
    {
        _context = context;
    }
//-----------------------------------------------------------------------------------------------------------
    public async Task<Reservation?> GetByIdAsync(Guid id)
    {
        return await _context.Reservations
            .Include(r => r.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .FirstOrDefaultAsync(r => r.Id == id);
    }
    //-----------------------------------------------------------------------------------------------------------

    public async Task<List<Reservation>> GetAllByUserIdAsync(Guid userId, int page, int pageSize)
    {
        return await _context.Reservations
            .Include(r => r.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //-----------------------------------------------------------------------------------------------------------

    public async Task<List<Reservation>> GetAllBySpotIdAsync(Guid spotId)
    {
        return await _context.Reservations
            .Where(r => r.SpotId == spotId && r.Status == ReservationStatus.Confirmed)
            .ToListAsync();
    }

    public async Task<int> GetTotalCountByUserIdAsync(Guid userId)
    {
        return await _context.Reservations
            .Where(r => r.UserId == userId)
            .CountAsync();
    }
    //-----------------------------------------------------------------------------------------------------------

    public async Task<Reservation> CreateAsync(Reservation reservation)
    {
        reservation.Id = Guid.NewGuid();
        reservation.CreatedAt = DateTime.UtcNow;
        reservation.UpdatedAt = DateTime.UtcNow;

        _context.Reservations.Add(reservation);
        await _context.SaveChangesAsync();
        return reservation;
    }
    //-----------------------------------------------------------------------------------------------------------

    public async Task<Reservation> UpdateAsync(Reservation reservation)
    {
        reservation.UpdatedAt = DateTime.UtcNow;
        _context.Reservations.Update(reservation);
        await _context.SaveChangesAsync();
        return reservation;
    }
    //-----------------------------------------------------------------------------------------------------------

    public async Task<bool> HasConflictingReservationAsync(Guid spotId, DateTime startTime, DateTime endTime, Guid? excludeReservationId = null)
    {
        return await _context.Reservations
            .Where(r => r.SpotId == spotId
                && r.Status == ReservationStatus.Confirmed
                && r.Id != excludeReservationId
                && r.StartTime < endTime
                && r.EndTime > startTime)
            .AnyAsync();
    }
    //-----------------------------------------------------------------------------------------------------------

    public async Task<List<Reservation>> GetExpiredReservationsAsync()
    {
        return await _context.Reservations
            .Where(r => r.Status == ReservationStatus.Confirmed
                     && r.EndTime < DateTime.UtcNow)
            .ToListAsync();
    }
    //-----------------------------------------------------------------------------------------------------------
    public async Task<List<Reservation>> GetExpiringReservationsAsync(int minutesAhead)
    {
        var now = DateTime.UtcNow;
        var threshold = now.AddMinutes(minutesAhead);

        return await _context.Reservations
            .Where(r => r.Status == ReservationStatus.Confirmed
                     && r.EndTime > now
                     && r.EndTime <= threshold)
            .ToListAsync();
    }
}