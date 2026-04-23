using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Shared.Messages
{
    public class ViolationCreatedMessage
    {
        public Guid ViolationId { get; set; }
        public Guid UserId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public decimal FineAmount { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
