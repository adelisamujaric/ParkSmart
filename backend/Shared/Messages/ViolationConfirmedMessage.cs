using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Shared.Messages
{
    public class ViolationConfirmedMessage
    {
        public Guid LogId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid LotId { get; set; }
        public Guid? SpotId { get; set; }
        public Guid? UserId { get; set; }
        public string ViolationType { get; set; } = string.Empty;
        public Guid ViolationConfigId { get; set; }
        public string? ImageUrl { get; set; }
        public decimal FineAmount { get; set; }
        public DateTime ConfirmedAt { get; set; }
    }
}
