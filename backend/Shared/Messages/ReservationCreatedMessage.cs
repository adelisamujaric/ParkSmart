public class ReservationCreatedMessage
{
    public Guid ReservationId { get; set; }
    public Guid UserId { get; set; }
    public string LicensePlate { get; set; } = string.Empty;
    public string LotName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}