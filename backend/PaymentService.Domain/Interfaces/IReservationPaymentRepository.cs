using PaymentService.Domain.Entities;

namespace PaymentService.Domain.Interfaces
{
    public interface IReservationPaymentRepository
    {
        Task<ReservationPayment> GetByIdAsync(Guid id);
        Task<IEnumerable<ReservationPayment>> GetByUserIdAsync(Guid userId);
        Task<IEnumerable<ReservationPayment>> GetAllAsync();
        Task<ReservationPayment> CreateAsync(ReservationPayment payment);
        Task<ReservationPayment> UpdateAsync(ReservationPayment payment);
        Task DeleteAsync(Guid id);
    }
}