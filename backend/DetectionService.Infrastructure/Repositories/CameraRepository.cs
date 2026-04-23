using DetectionService.Domain.Entities;
using DetectionService.Domain.Interfaces;
using DetectionService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DetectionService.Infrastructure.Repositories
{
    public class CameraRepository : ICameraRepository
    {
        private readonly DetectionDbContext _context;

        public CameraRepository(DetectionDbContext context)
        {
            _context = context;
        }
        //--------------------------------------------------------------------

        public async Task<List<Camera>> GetAllAsync()
            => await _context.Cameras.ToListAsync();
        //--------------------------------------------------------------------

        public async Task<Camera?> GetByIdAsync(Guid id)
            => await _context.Cameras.FindAsync(id);
        //--------------------------------------------------------------------

        public async Task<Camera> CreateAsync(Camera camera)
        {
            _context.Cameras.Add(camera);
            await _context.SaveChangesAsync();
            return camera;
        }
        //--------------------------------------------------------------------

        public async Task<Camera> UpdateAsync(Camera camera)
        {
            _context.Cameras.Update(camera);
            await _context.SaveChangesAsync();
            return camera;
        }
        //--------------------------------------------------------------------

        public async Task DeleteAsync(Guid id)
        {
            var camera = await _context.Cameras.FindAsync(id);
            if (camera != null)
            {
                _context.Cameras.Remove(camera);
                await _context.SaveChangesAsync();
            }
        }
        //--------------------------------------------------------------------

    }
}