namespace Shared.Messages
{
    public class ViolationPaymentCompletedMessage
    {
        public Guid ViolationId { get; set; }
        public Guid UserId { get; set; }
        public decimal Amount { get; set; }
    }
}