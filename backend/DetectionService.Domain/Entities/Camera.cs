using DetectionService.Domain.Enums;

namespace DetectionService.Domain.Entities
{
    public class Camera
    {
        public Guid Id { get; set; }
        public int Number { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public DetectionCameraType CameraType { get; set; }
        public CameraStatus Status { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}