using DetectionService.Domain.Entities;
using DetectionService.Domain.Enums;
using DetectionService.Domain.Interfaces;
using DetectionService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DetectionService.Infrastructure.Repositories
{
    public class DetectionLogRepository : IDetectionLogRepository
    {
        private readonly DetectionDbContext _context;

        public DetectionLogRepository(DetectionDbContext context)
        {
            _context = context;
        }
        //-----------------------------------------------------------------------------------
        public async Task<DetectionLog> CreateAsync(DetectionLog log)
        {
            _context.DetectionLogs.Add(log);
            await _context.SaveChangesAsync();
            return log;
        }
        //-----------------------------------------------------------------------------------

        public async Task<DetectionLog?> GetByIdAsync(Guid id)
        {
            return await _context.DetectionLogs.FindAsync(id);
        }
        //-----------------------------------------------------------------------------------

        public async Task<DetectionLog> UpdateAsync(DetectionLog log)
        {
            _context.DetectionLogs.Update(log);
            await _context.SaveChangesAsync();
            return log;
        }
        //-----------------------------------------------------------------------------------

        public async Task<List<DetectionLog>> GetByLotIdAsync(Guid lotId)
        {
            return await _context.DetectionLogs
                .Where(d => d.LotId == lotId)
                .OrderByDescending(d => d.DetectedAt)
                .ToListAsync();
        }
        //-----------------------------------------------------------------------------------

        public async Task<List<DetectionLog>> GetByLicensePlateAsync(string licensePlate)
        {
            return await _context.DetectionLogs
                .Where(d => d.LicensePlate == licensePlate)
                .OrderByDescending(d => d.DetectedAt)
                .ToListAsync();
        }
        //-----------------------------------------------------------------------------------

        public async Task<List<DetectionLog>> GetPendingReviewsAsync()
        {
            return await _context.DetectionLogs
                .Where(d => d.Status == DetectionStatus.PendingReview)
                .OrderByDescending(d => d.DetectedAt)
                .ToListAsync();
        }
        //-----------------------------------------------------------------------------------
        public async Task<List<DetectionLog>> GetAllAsync()
        {
            return await _context.DetectionLogs
                .OrderByDescending(d => d.DetectedAt)
                .ToListAsync();
        }
    }
}