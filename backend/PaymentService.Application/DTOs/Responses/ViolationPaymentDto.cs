using PaymentService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PaymentService.Application.DTOs.Responses
{
    public class ViolationPaymentDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid ViolationId { get; set; }
        public decimal Amount { get; set; }
        public ViolationPaymentStatus Status { get; set; }
        public string? StripePaymentIntentId { get; set; }
        public string? StripeClientSecret { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }
    }
}
