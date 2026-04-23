namespace Shared.Messages
{
    public class PaymentCompletedMessage
    {
        public Guid TicketId { get; set; }
        public Guid UserId { get; set; }
        public decimal Amount { get; set; }
    }
}