using PaymentService.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PaymentService.Domain.Interfaces
{
    public interface IViolationPaymentRepository
    {
        Task<ViolationPayment> GetByIdAsync(Guid id);
        Task<IEnumerable<ViolationPayment>> GetByUserIdAsync(Guid userId);
        Task<IEnumerable<ViolationPayment>> GetAllAsync();
        Task<ViolationPayment> CreateAsync(ViolationPayment payment);
        Task<ViolationPayment> UpdateAsync(ViolationPayment payment);
        Task DeleteAsync(Guid id);
    }
}
