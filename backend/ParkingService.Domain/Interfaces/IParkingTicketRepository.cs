using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Entities;

namespace ParkingService.Domain.Interfaces
{
    public interface IParkingTicketRepository
    {
        Task<Ticket?> GetByIdAsync(Guid id);
        Task<Ticket?> GetActiveByLicensePlateAsync(string licensePlate);
        Task<List<Ticket>> GetAllByUserIdAsync(Guid userId, int page, int pageSize);
        Task<int> GetTotalCountByUserIdAsync(Guid userId);
        Task<Ticket> CreateAsync(Ticket ticket);
        Task<Ticket> UpdateAsync(Ticket ticket);
        Task<List<Ticket>> GetActiveTicketsAsync();
        Task<List<Ticket>> GetExpiringTicketsAsync(int minutesBeforeExpiry);
        Task<List<Ticket>> GetAllAsync(int page, int pageSize);
        Task<int> GetTotalCountAsync();
        Task<List<Ticket>> GetOverdueTicketsAsync();
        Task<List<Ticket>> GetExpiredActiveTicketsAsync();
        Task<List<Ticket>> GetActiveByUserIdAsync(Guid userId);
    }
}
