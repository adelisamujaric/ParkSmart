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
    public class ViolationPaymentRepository : IViolationPaymentRepository
    {
        private readonly PaymentDbContext _context;

        public ViolationPaymentRepository(PaymentDbContext context)
        {
            _context = context;
        }
        //---------------------------------------------------------------------------------------------------
        public async Task<ViolationPayment> GetByIdAsync(Guid id)
        {
            return await _context.ViolationPayments.FindAsync(id)
                ?? throw new KeyNotFoundException($"ViolationPayment with ID {id} not found.");
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<IEnumerable<ViolationPayment>> GetByUserIdAsync(Guid userId)
        {
            return await _context.ViolationPayments
                .Where(p => p.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<IEnumerable<ViolationPayment>> GetAllAsync()
        {
            return await _context.ViolationPayments
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<ViolationPayment> CreateAsync(ViolationPayment payment)
        {
            payment.Id = Guid.NewGuid();
            payment.CreatedAt = DateTime.UtcNow;
            payment.Status = ViolationPaymentStatus.Pending;
            _context.ViolationPayments.Add(payment);
            await _context.SaveChangesAsync();
            return payment;
        }
        //---------------------------------------------------------------------------------------------------

        public async Task<ViolationPayment> UpdateAsync(ViolationPayment payment)
        {
            _context.ViolationPayments.Update(payment);
            await _context.SaveChangesAsync();
            return payment;
        }
        //---------------------------------------------------------------------------------------------------

        public async Task DeleteAsync(Guid id)
        {
            var payment = await GetByIdAsync(id);
            _context.ViolationPayments.Remove(payment);
            await _context.SaveChangesAsync();
        }
        //---------------------------------------------------------------------------------------------------

    }
}
