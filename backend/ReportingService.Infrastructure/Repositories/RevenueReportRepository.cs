using Microsoft.EntityFrameworkCore;
using ReportingService.Domain.Entities;
using ReportingService.Domain.Enums;
using ReportingService.Domain.Interfaces;

namespace ReportingService.Infrastructure.Repositories
{
    public class RevenueReportRepository : IRevenueReportRepository
    {
        private readonly ParkingReadDbContext _context;

        public RevenueReportRepository(ParkingReadDbContext context)
        {
            _context = context;
        }
        //-------------------------------------------------------------------------------------

        public async Task<List<Ticket>> GetPaidTicketsAsync(DateTime from, DateTime to)
        {
            return await _context.Tickets
                .Include(t => t.ParkingSpot)
                    .ThenInclude(s => s.ParkingLot)
                .Where(t => t.Status == TicketStatus.Paid &&
                            t.ExitTime >= from &&
                            t.ExitTime <= to)
                .ToListAsync();
        }
        //-------------------------------------------------------------------------------------

        public async Task<List<Reservation>> GetCompletedReservationsAsync(DateTime from, DateTime to)
        {
            return await _context.Reservations
                .Include(r => r.ParkingSpot)
                    .ThenInclude(s => s.ParkingLot)
                .Where(r => r.Status == ReservationStatus.Completed &&
                            r.EndTime >= from &&
                            r.EndTime <= to)
                .ToListAsync();
        }
        //-------------------------------------------------------------------------------------

    }
}