using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DetectionService.Domain.Enums;

namespace DetectionService.Application.DTOs.Requests
{
    public class AnalyzeImageRequestDto
    {
        public string Image { get; set; } = string.Empty; // base64
        public DetectionCameraType CameraType { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public Guid? SpotId { get; set; }
    }
}
