using DetectionService.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DetectionService.Domain.Interfaces
{
    public interface IDetectionLogRepository
    {
        Task<DetectionLog> CreateAsync(DetectionLog log);
        Task<DetectionLog?> GetByIdAsync(Guid id);
        Task<DetectionLog> UpdateAsync(DetectionLog log);
        Task<List<DetectionLog>> GetByLotIdAsync(Guid lotId);
        Task<List<DetectionLog>> GetByLicensePlateAsync(string licensePlate);
        Task<List<DetectionLog>> GetPendingReviewsAsync();
        Task<List<DetectionLog>> GetAllAsync();
    }
}
