using PaymentService.Domain.Entities;
using PaymentService.Domain.Enums;
using PaymentService.Domain.Interfaces;
using PaymentService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace PaymentService.Infrastructure.Repositories
{
    public class ReservationPaymentRepository : IReservationPaymentRepository
    {
        private readonly PaymentDbContext _context;
        public ReservationPaymentRepository(PaymentDbContext context)
        {
            _context = context;
        }

        public async Task<ReservationPayment> GetByIdAsync(Guid id)
        {
            return await _context.ReservationPayments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Payment with ID {id} not found.");
        }

        public async Task<IEnumerable<ReservationPayment>> GetByUserIdAsync(Guid userId)
        {
            return await _context.ReservationPayments
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<ReservationPayment>> GetAllAsync()
        {
            return await _context.ReservationPayments
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }

        public async Task<ReservationPayment> CreateAsync(ReservationPayment payment)
        {
            payment.Id = Guid.NewGuid();
            payment.CreatedAt = DateTime.UtcNow;
            payment.Status = PaymentStatus.Pending;
            _context.ReservationPayments.Add(payment);
            await _context.SaveChangesAsync();
            return payment;
        }

        public async Task<ReservationPayment> UpdateAsync(ReservationPayment payment)
        {
            _context.ReservationPayments.Update(payment);
            await _context.SaveChangesAsync();
            return payment;
        }

        public async Task DeleteAsync(Guid id)
        {
            var payment = await GetByIdAsync(id);
            _context.ReservationPayments.Remove(payment);
            await _context.SaveChangesAsync();
        }
    }
}