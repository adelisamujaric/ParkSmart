using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DetectionService.Domain.Enums;

namespace DetectionService.Domain.Entities
{
    public class DetectionLog
    {
        public Guid Id { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public Guid? SpotId { get; set; }
        public DetectionCameraType CameraType { get; set; }
        public int? DroneNumber { get; set; }
        public int? CameraNumber { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public string? ImageUrl { get; set; }
        public string? ViolationType { get; set; }
        public Guid? ViolationConfigId { get; set; } 
        public DetectionResult Result { get; set; }
        public DetectionStatus Status { get; set; }
        public string? ReviewNote { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime DetectedAt { get; set; } = DateTime.UtcNow;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
