using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Shared.Messages
{
    public class VehicleDetectedMessage
    {
        public Guid LogId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid LotId { get; set; }
        public Guid? SpotId { get; set; }
        public Guid? UserId { get; set; } // nullable - možda nije poznat
        public string DetectionCameraType { get; set; } = string.Empty;
        public string Result { get; set; } = string.Empty;
        public DateTime DetectedAt { get; set; }
    }
}
