
using Microsoft.EntityFrameworkCore;
using ParkingService.Infrastructure.Data;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;

namespace ParkingService.Infrastructure.Repositories;

public class ParkingTicketRepository : IParkingTicketRepository
{
    private readonly ParkingDbContext _context;

    public ParkingTicketRepository(ParkingDbContext context)
    {
        _context = context;
    }
    //------------------------------------------------------------------------------------------------------
    public async Task<Ticket?> GetByIdAsync(Guid id)
    {
        return await _context.ParkingTickets
            .Include(t => t.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Include(t => t.ParkingLot) 
            .Include(t => t.Reservation)
            .FirstOrDefaultAsync(t => t.Id == id);
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<Ticket?> GetActiveByLicensePlateAsync(string licensePlate)
    {
        return await _context.ParkingTickets
            .Include(t => t.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .FirstOrDefaultAsync(t => t.LicensePlate == licensePlate.ToUpper().Trim()
                && t.Status == TicketStatus.Active);
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<List<Ticket>> GetAllByUserIdAsync(Guid userId, int page, int pageSize)
    {
        return await _context.ParkingTickets
            .Include(t => t.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Include(t => t.ParkingLot) 
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalCountByUserIdAsync(Guid userId)
    {
        return await _context.ParkingTickets
            .Where(t => t.UserId == userId)
            .CountAsync();
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<Ticket> CreateAsync(Ticket ticket)
    {
        ticket.Id = Guid.NewGuid();
        ticket.CreatedAt = DateTime.UtcNow;
        ticket.UpdatedAt = DateTime.UtcNow;

        _context.ParkingTickets.Add(ticket);
        await _context.SaveChangesAsync();
        return ticket;
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<Ticket> UpdateAsync(Ticket ticket)
    {
        ticket.UpdatedAt = DateTime.UtcNow;
        _context.ParkingTickets.Update(ticket);
        await _context.SaveChangesAsync();
        return ticket;
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<List<Ticket>> GetActiveTicketsAsync()
    {
        return await _context.ParkingTickets
            .Include(t => t.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Where(t => t.Status == TicketStatus.Active)
            .ToListAsync();
    }
    //------------------------------------------------------------------------------------------------------
    public async Task<List<Ticket>> GetExpiringTicketsAsync(int minutesBeforeExpiry)
    {
        var now = DateTime.UtcNow;
        var upperThreshold = now.AddMinutes(minutesBeforeExpiry);
        var lowerThreshold = now.AddMinutes(minutesBeforeExpiry - 1);

        return await _context.ParkingTickets
            .Where(t => t.Status == TicketStatus.Active
                     && t.EndTime != null
                     && t.EndTime > lowerThreshold
                     && t.EndTime <= upperThreshold)
            .ToListAsync();
    }
    //------------------------------------------------------------------------------------------------------
    public async Task<List<Ticket>> GetAllAsync(int page, int pageSize)
    {
        return await _context.ParkingTickets
            .Include(t => t.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Include(t => t.ParkingLot)
            .OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<int> GetTotalCountAsync()
    {
        return await _context.ParkingTickets.CountAsync();
    }
    //------------------------------------------------------------------------------------------------------

    public async Task<List<Ticket>> GetOverdueTicketsAsync()
    {
        return await _context.ParkingTickets
            .Where(t => t.Status == TicketStatus.PendingPayment
                     && t.PaymentDeadline != null
                     && t.PaymentDeadline < DateTime.UtcNow)
            .ToListAsync();
    }
    //------------------------------------------------------------------------------------------------------
    public async Task<List<Ticket>> GetExpiredActiveTicketsAsync()
    {
        return await _context.ParkingTickets
            .Include(t => t.ParkingSpot)
            .ThenInclude(s => s.ParkingLot)
            .Where(t => t.Status == TicketStatus.Active
                     && t.EndTime != null
                     && t.EndTime < DateTime.UtcNow)
            .ToListAsync();
    }

    public async Task<List<Ticket>> GetActiveByUserIdAsync(Guid userId)
    {
        return await _context.ParkingTickets
            .Where(t => t.UserId == userId && t.Status == TicketStatus.Active)
            .Include(t => t.ParkingSpot)
                .ThenInclude(s => s!.ParkingLot)
            .ToListAsync();
    }


}