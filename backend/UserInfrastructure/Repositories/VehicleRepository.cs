using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UserService.Infrastructure.Data;
using UserService.Modules.Entities;
using UserService.Modules.Interfaces;

namespace UserService.Infrastructure.Repositories
{
    public class VehicleRepository : IVehicleRepository
    {
        private readonly UserDbContext _context;

        public VehicleRepository(UserDbContext context)
        {
            _context = context;
        }
        //----------------------------------------------------------------------------
        public async Task<List<Vehicle>> GetAllVehicles(int page, int pageSize)
        {
            return await _context.Vehicles
        .Where(u => u.IsActive)
        .OrderBy(u => u.CreatedAt)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync();
        }
        //---------------------------------------------------------------------------

        public async Task<int> GetTotalCount()
        {
            return await _context.Vehicles.Where(u => u.IsActive).CountAsync();
        }
        //---------------------------------------------------------------------------

        public async Task<Vehicle?> GetVehicleById(Guid id)
        {
            return await _context.Vehicles.FindAsync(id);
        }
        //----------------------------------------------------------------------------
        public async Task<Vehicle?> GetVehicleByLicence(string licencePlate)
        {
            return await _context.Vehicles
                .FirstOrDefaultAsync(u => u.LicensePlate == licencePlate && u.IsActive);
        }
        //----------------------------------------------------------------------------
        public async Task<List<Vehicle>> GetVehiclesByUserId(Guid userId)
        {
            return await _context.Vehicles
                .Where(v => v.UserId == userId && v.IsActive)
                .ToListAsync();
        }
        //----------------------------------------------------------------------------

        public async Task<Vehicle?> GetVehicleByLicenceWithOwner(string licensePlate)
        {
            return await _context.Vehicles
                .Include(v => v.User)  // ← Eager load User
                .FirstOrDefaultAsync(v => v.LicensePlate == licensePlate);
        }
        //----------------------------------------------------------------------------

        public async Task<Vehicle> CreateVehicle(Vehicle vehicle)
        {
            _context.Vehicles.Add(vehicle);
            await _context.SaveChangesAsync();
            return vehicle;
        }
        //---------------------------------------------------------------------------

        public async Task<Vehicle> UpdateVehicle(Vehicle vehicle)
        {
            _context.Vehicles.Update(vehicle);
            await _context.SaveChangesAsync();
            return vehicle;
        }
        //---------------------------------------------------------------------------

        public async Task DeleteVehicle(Guid id)
        {
            var vehicle = await GetVehicleById(id);
            if (vehicle != null)
            {
                _context.Vehicles.Remove(vehicle);
                await _context.SaveChangesAsync();
            }
        }
        //----------------------------------------------------------------------------


    }
}
