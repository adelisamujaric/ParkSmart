using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using PaymentService.Domain.Enums;

namespace PaymentService.Domain.Entities
{
    public class ParkingPayment
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid TicketId { get; set; }
        public decimal Amount { get; set; }
        public PaymentStatus Status { get; set; }
        public PaymentMethod Method { get; set; }
        public string? StripePaymentIntentId { get; set; }
        public string? StripeClientSecret { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
    }
}
