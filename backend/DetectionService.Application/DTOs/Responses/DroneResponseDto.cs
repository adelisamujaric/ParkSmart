namespace DetectionService.Application.DTOs.Responses
{
    public class DroneResponseDto
    {
        public Guid Id { get; set; }
        public int Number { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public int BatteryLevel { get; set; }
        public TimeSpan? TimeToCharge { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}