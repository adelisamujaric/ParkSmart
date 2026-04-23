using Microsoft.EntityFrameworkCore;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Interfaces;
using ParkingService.Infrastructure.Data;

namespace ParkingService.Infrastructure.Repositories
{
    public class ViolationConfigRepository : IViolationConfigRepository
    {
        private readonly ParkingDbContext _context;

        public ViolationConfigRepository(ParkingDbContext context)
        {
            _context = context;
        }

        public async Task<List<ViolationConfig>> GetAllAsync()
        {
            return await _context.ViolationConfigs.OrderBy(v => v.TypeName).ToListAsync();
        }

        public async Task<ViolationConfig?> GetByIdAsync(Guid id)
        {
            return await _context.ViolationConfigs.FirstOrDefaultAsync(v => v.Id == id);
        }

        public async Task<ViolationConfig> CreateAsync(ViolationConfig config)
        {
            config.Id = Guid.NewGuid();
            config.CreatedAt = DateTime.UtcNow;
            config.UpdatedAt = DateTime.UtcNow;
            _context.ViolationConfigs.Add(config);
            await _context.SaveChangesAsync();
            return config;
        }

        public async Task<ViolationConfig> UpdateAsync(ViolationConfig config)
        {
            config.UpdatedAt = DateTime.UtcNow;
            _context.ViolationConfigs.Update(config);
            await _context.SaveChangesAsync();
            return config;
        }

        public async Task DeleteAsync(Guid id)
        {
            var config = await _context.ViolationConfigs.FindAsync(id);
            if (config != null)
            {
                _context.ViolationConfigs.Remove(config);
                await _context.SaveChangesAsync();
            }
        }
    }
}