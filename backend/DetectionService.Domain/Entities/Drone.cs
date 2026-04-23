using DetectionService.Domain.Enums;

namespace DetectionService.Domain.Entities
{
    public class Drone
    {
        public Guid Id { get; set; }
        public int Number { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public DroneStatus Status { get; set; }
        public int BatteryLevel { get; set; }
        public TimeSpan? TimeToCharge { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}