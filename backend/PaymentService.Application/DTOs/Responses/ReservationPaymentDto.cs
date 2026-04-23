using PaymentService.Domain.Enums;

namespace PaymentService.Application.DTOs.Responses
{
    public class ReservationPaymentDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid ReservationId { get; set; }
        public decimal Amount { get; set; }
        public PaymentStatus Status { get; set; }
        public PaymentMethod Method { get; set; }
        public string StripePaymentIntentId { get; set; } = string.Empty;
        public string StripeClientSecret { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
    }
}