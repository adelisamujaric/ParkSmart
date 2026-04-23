using DetectionService.Domain.Entities;

namespace DetectionService.Domain.Interfaces
{
    public interface ICameraRepository
    {
        Task<List<Camera>> GetAllAsync();
        Task<Camera?> GetByIdAsync(Guid id);
        Task<Camera> CreateAsync(Camera camera);
        Task<Camera> UpdateAsync(Camera camera);
        Task DeleteAsync(Guid id);
    }
}