using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Shared.Messages
{
    public class TicketExpiringMessage
    {
        public Guid TicketId { get; set; }
        public Guid UserId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public DateTime EndTime { get; set; }
        public int MinutesRemaining { get; set; }
    }
}
