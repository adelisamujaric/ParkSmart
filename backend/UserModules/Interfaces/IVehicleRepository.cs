using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UserService.Modules.Entities;

namespace UserService.Modules.Interfaces
{
    public interface IVehicleRepository
    {
        Task<Vehicle?> GetVehicleById(Guid id);
        Task<Vehicle?> GetVehicleByLicence(string licence);
        Task<Vehicle> CreateVehicle(Vehicle vehicle);
        Task<Vehicle> UpdateVehicle(Vehicle vehicle);
        Task DeleteVehicle(Guid id);
        Task<List<Vehicle>> GetAllVehicles(int page, int pageSize);
        Task<int> GetTotalCount();
        Task<List<Vehicle>> GetVehiclesByUserId(Guid userId);
        Task<Vehicle?> GetVehicleByLicenceWithOwner(string licensePlate);
    }
}
