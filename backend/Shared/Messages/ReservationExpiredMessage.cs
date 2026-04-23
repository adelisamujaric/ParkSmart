public class ReservationExpiredMessage
{
    public Guid ReservationId { get; set; }
    public Guid UserId { get; set; }
    public string LicensePlate { get; set; } = string.Empty;
    public decimal TotalPrice { get; set; }
    public DateTime EndTime { get; set; }
}