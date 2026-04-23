using DetectionService.Domain.Entities;

namespace DetectionService.Domain.Interfaces
{
    public interface IDroneRepository
    {
        Task<List<Drone>> GetAllAsync();
        Task<Drone?> GetByIdAsync(Guid id);
        Task<Drone> CreateAsync(Drone drone);
        Task<Drone> UpdateAsync(Drone drone);
        Task DeleteAsync(Guid id);
    }
}