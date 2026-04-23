using DetectionService.Domain.Entities;
using DetectionService.Domain.Interfaces;
using DetectionService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace DetectionService.Infrastructure.Repositories
{
    public class DroneRepository : IDroneRepository
    {
        private readonly DetectionDbContext _context;

        public DroneRepository(DetectionDbContext context)
        {
            _context = context;
        }
        //--------------------------------------------------------------------
        public async Task<List<Drone>> GetAllAsync()
            => await _context.Drones.ToListAsync();
        //--------------------------------------------------------------------

        public async Task<Drone?> GetByIdAsync(Guid id)
            => await _context.Drones.FindAsync(id);
        //--------------------------------------------------------------------

        public async Task<Drone> CreateAsync(Drone drone)
        {
            _context.Drones.Add(drone);
            await _context.SaveChangesAsync();
            return drone;
        }
        //--------------------------------------------------------------------

        public async Task<Drone> UpdateAsync(Drone drone)
        {
            _context.Drones.Update(drone);
            await _context.SaveChangesAsync();
            return drone;
        }
        //--------------------------------------------------------------------

        public async Task DeleteAsync(Guid id)
        {
            var drone = await _context.Drones.FindAsync(id);
            if (drone != null)
            {
                _context.Drones.Remove(drone);
                await _context.SaveChangesAsync();
            }
        }
        //--------------------------------------------------------------------

    }
}