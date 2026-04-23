using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DetectionService.Application.DTOs.Requests
{
    public class ReviewDetectionRequest
    {
        public bool Confirmed { get; set; }
        public string? ReviewNote { get; set; }
    }
}
