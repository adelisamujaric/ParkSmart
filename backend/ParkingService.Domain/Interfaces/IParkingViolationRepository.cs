using ParkingService.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Domain.Interfaces
{
    public interface IParkingViolationRepository
    {
        Task<Violation?> GetByIdAsync(Guid id);
        Task<List<Violation>> GetAllByLicensePlateAsync(string licensePlate, int page, int pageSize);
        Task<List<Violation>> GetAllUnresolvedAsync(int page, int pageSize);
        Task<int> GetTotalCountByLicensePlateAsync(string licensePlate);
        Task<int> GetTotalUnresolvedCountAsync();
        Task<Violation> CreateAsync(Violation violation);
        Task<Violation> UpdateAsync(Violation violation);
        Task<List<Violation>> GetAllByUserIdAsync(Guid userId);


    }
}
