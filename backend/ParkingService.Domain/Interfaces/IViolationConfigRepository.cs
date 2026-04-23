using ParkingService.Domain.Entities;

namespace ParkingService.Domain.Interfaces
{
    public interface IViolationConfigRepository
    {
        Task<List<ViolationConfig>> GetAllAsync();
        Task<ViolationConfig?> GetByIdAsync(Guid id);
        Task<ViolationConfig> CreateAsync(ViolationConfig config);
        Task<ViolationConfig> UpdateAsync(ViolationConfig config);
        Task DeleteAsync(Guid id);
    }
}