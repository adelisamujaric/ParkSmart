using DetectionService.Domain.Enums;

namespace DetectionService.Application.DTOs.Requests
{
    public class CreateDroneDto
    {
        public int Number { get; set; }
        public Guid LotId { get; set; }
        public int BatteryLevel { get; set; }
        public TimeSpan? TimeToCharge { get; set; }
    }
}