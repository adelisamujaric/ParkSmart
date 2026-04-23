using PaymentService.Domain.Entities;
using PaymentService.Domain.Enums;
using PaymentService.Domain.Interfaces;
using PaymentService.Infrastructure.Data;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace PaymentService.Infrastructure.Repositories
{
    public class ParkingPaymentRepository : IParkingPaymentRepository
    {
        private readonly PaymentDbContext _context;

        public ParkingPaymentRepository(PaymentDbContext context)
        {
            _context = context;
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<ParkingPayment> GetByIdAsync(Guid id)
        {
            return await _context.ParkingPayments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Payment with ID {id} not found.");
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<IEnumerable<ParkingPayment>> GetByUserIdAsync(Guid userId)
        {
            return await _context.ParkingPayments
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<IEnumerable<ParkingPayment>> GetAllAsync()
        {
            return await _context.ParkingPayments
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<ParkingPayment> CreateAsync(ParkingPayment payment)
        {
            payment.Id = Guid.NewGuid();
            payment.CreatedAt = DateTime.UtcNow;
            payment.Status = PaymentStatus.Pending;
            _context.ParkingPayments.Add(payment);
            await _context.SaveChangesAsync();
            return payment;
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<ParkingPayment> UpdateAsync(ParkingPayment payment)
        {
            _context.ParkingPayments.Update(payment);
            await _context.SaveChangesAsync();
            return payment;
        }
        //---------------------------------------------------------------------------------------------------

        public async Task DeleteAsync(Guid id)
        {
            var payment = await GetByIdAsync(id);
            _context.ParkingPayments.Remove(payment);
            await _context.SaveChangesAsync();
        }
        //---------------------------------------------------------------------------------------------------

    }
}
