
using ParkingService.Domain.Entities;

namespace ParkingService.Domain.Interfaces;

public interface IParkingLotRepository
{
    Task<ParkingLot?> GetByIdAsync(Guid id);
    Task<List<ParkingLot>> GetAllAsync(int page, int pageSize);
    Task<int> GetTotalCountAsync();
    Task<ParkingLot> CreateAsync(ParkingLot parkingLot);
    Task<ParkingLot> UpdateAsync(ParkingLot parkingLot);
    Task<bool> DeleteAsync(Guid id);
    Task<bool> ExistsAsync(Guid id);
    Task<List<ParkingLot>> GetAllIncludingInactiveAsync(int page, int pageSize);
    Task<int> GetTotalCountIncludingInactiveAsync();
}