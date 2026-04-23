using DetectionService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DetectionService.Application.DTOs.Responses
{
    public class AnalyzeImageResponseDto
    {
        public Guid LogId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public DetectionResult Result { get; set; }
        public DetectionStatus Status { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime DetectedAt { get; set; }
    }
}
