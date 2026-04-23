using Microsoft.EntityFrameworkCore;
using ReportingService.Domain.Entities;
using ReportingService.Domain.Enums;
using ReportingService.Domain.Interfaces;

namespace ReportingService.Infrastructure.Repositories
{
    public class OccupancyReportRepository : IOccupancyReportRepository
    {
        private readonly ParkingReadDbContext _context;

        public OccupancyReportRepository(ParkingReadDbContext context)
        {
            _context = context;
        }
        //-------------------------------------------------------------------------------------

        public async Task<List<Ticket>> GetActiveTicketsByHourAsync(DateTime from, DateTime to)
        {
            return await _context.Tickets
                .Include(t => t.ParkingSpot)
                    .ThenInclude(s => s.ParkingLot)
                .Where(t => t.EntryTime >= from && t.EntryTime <= to)
                .ToListAsync();
        }
        //-------------------------------------------------------------------------------------

        public async Task<List<ParkingLot>> GetParkingLotsWithSpotsAsync()
        {
            return await _context.ParkingLots
                .Include(l => l.ParkingSpots.Where(s => !s.IsDeleted))
                .Where(l => l.IsActive)
                .ToListAsync();
        }
        //-------------------------------------------------------------------------------------

    }
}