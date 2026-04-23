using DetectionService.Domain.Enums;

namespace DetectionService.Application.DTOs.Requests
{
    public class CreateDetectionLogDto
    {
        public Guid LotId { get; set; }
        public Guid? SpotId { get; set; }
        public DetectionCameraType CameraType { get; set; }
        public int? DroneNumber { get; set; }
        public int? CameraNumber { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid? ViolationConfigId { get; set; }


    }
}