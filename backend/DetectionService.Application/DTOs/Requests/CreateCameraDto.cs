using DetectionService.Domain.Enums;

namespace DetectionService.Application.DTOs.Requests
{
    public class CreateCameraDto
    {
        public int Number { get; set; }
        public Guid LotId { get; set; }
        public DetectionCameraType CameraType { get; set; }
    }
}