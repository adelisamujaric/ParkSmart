using Microsoft.EntityFrameworkCore;
using ReportingService.Domain.Entities;
using ReportingService.Domain.Interfaces;

namespace ReportingService.Infrastructure.Repositories
{
    public class ViolationsReportRepository : IViolationsReportRepository
    {
        private readonly ParkingReadDbContext _context;

        public ViolationsReportRepository(ParkingReadDbContext context)
        {
            _context = context;
        }
        //-------------------------------------------------------------------------------------

        public async Task<List<Violation>> GetViolationsAsync(DateTime from, DateTime to)
        {
            return await _context.Violations
                .Include(v => v.ViolationConfig)
                .Include(v => v.ParkingLot) 
                .Where(v => v.CreatedAt >= from && v.CreatedAt <= to)
                .ToListAsync();
        }
        //-------------------------------------------------------------------------------------

    }
}