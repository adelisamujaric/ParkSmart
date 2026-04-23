using ParkingService.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Domain.Interfaces
{
    public interface IParkingReservationRepository
    {
        Task<Reservation?> GetByIdAsync(Guid id);
        Task<List<Reservation>> GetAllByUserIdAsync(Guid userId, int page, int pageSize);
        Task<List<Reservation>> GetAllBySpotIdAsync(Guid spotId);
        Task<int> GetTotalCountByUserIdAsync(Guid userId);
        Task<Reservation> CreateAsync(Reservation reservation);
        Task<Reservation> UpdateAsync(Reservation reservation);
        Task<bool> HasConflictingReservationAsync(Guid spotId, DateTime startTime, DateTime endTime, Guid? excludeReservationId = null);
        Task<List<Reservation>> GetExpiredReservationsAsync();
        Task<List<Reservation>> GetExpiringReservationsAsync(int minutesAhead);
    }
}
