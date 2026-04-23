namespace DetectionService.Application.DTOs.Responses
{
    public class DetectionLogResponseDto
    {
        public Guid Id { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public Guid? SpotId { get; set; }
        public string DetectionCameraType { get; set; } = string.Empty;
        public int? DroneNumber { get; set; }
        public int? CameraNumber { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public string Result { get; set; } = string.Empty;
        public string? ViolationType { get; set; }
        public Guid? ViolationConfigId { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public string? ReviewNote { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime DetectedAt { get; set; }
    }
}