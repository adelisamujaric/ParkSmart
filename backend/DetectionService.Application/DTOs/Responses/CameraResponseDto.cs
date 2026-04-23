namespace DetectionService.Application.DTOs.Responses
{
    public class CameraResponseDto
    {
        public Guid Id { get; set; }
        public int Number { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public string CameraType { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}