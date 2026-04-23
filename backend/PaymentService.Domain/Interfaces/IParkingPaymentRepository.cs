using PaymentService.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PaymentService.Domain.Interfaces
{
    public interface IParkingPaymentRepository
    {
        Task<ParkingPayment> GetByIdAsync(Guid id);
        Task<IEnumerable<ParkingPayment>> GetByUserIdAsync(Guid userId);
        Task<IEnumerable<ParkingPayment>> GetAllAsync();
        Task<ParkingPayment> CreateAsync(ParkingPayment payment);
        Task<ParkingPayment> UpdateAsync(ParkingPayment payment);
        Task DeleteAsync(Guid id);
    }
}
