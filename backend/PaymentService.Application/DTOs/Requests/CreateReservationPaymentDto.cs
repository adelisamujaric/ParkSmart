using PaymentService.Domain.Enums;

namespace PaymentService.Application.DTOs.Requests
{
    public class CreateReservationPaymentDto
    {
        public Guid UserId { get; set; }
        public Guid ReservationId { get; set; }
        public decimal Amount { get; set; }
        public PaymentMethod Method { get; set; }
    }
}