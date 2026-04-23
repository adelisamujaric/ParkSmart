using ParkingService.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Domain.Interfaces
{
    public interface IParkingSpotRepository
    {
        Task<ParkingSpot?> GetByIdAsync(Guid id);
        Task<List<ParkingSpot>> GetAllByLotIdAsync(Guid lotId, int page, int pageSize);
        Task<List<ParkingSpot>> GetAvailableByLotIdAsync(Guid lotId);
        Task<int> GetTotalCountByLotIdAsync(Guid lotId);
        Task<ParkingSpot> CreateAsync(ParkingSpot spot);
        Task<ParkingSpot> UpdateAsync(ParkingSpot spot);
        Task<bool> DeleteAsync(Guid id);
        Task<bool> ExistsAsync(Guid id);
        Task UpdateStatusAsync(Guid id, ParkingSpotStatus status);
    }
}
