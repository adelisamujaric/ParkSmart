using ParkingService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations.Schema;

namespace ParkingService.Domain.Entities
{
    public class Ticket
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? LotId { get; set; }
        public ParkingLot? ParkingLot { get; set; }
        public Guid? SpotId { get; set; }
        public Guid? ReservationId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public DateTime EntryTime { get; set; } = DateTime.UtcNow;
        public DateTime? ExitTime { get; set; }
        public DateTime? EndTime { get; set; }
        public decimal? TotalPrice { get; set; }
        public DateTime? PaymentDeadline { get; set; }
       
        [Column(TypeName = "decimal(18,2)")]
        public decimal LateFee { get; set; } = 0;
        public TicketStatus Status { get; set; } = TicketStatus.Active;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public ParkingSpot? ParkingSpot { get; set; } = null!;
        public Reservation? Reservation { get; set; }
        public ICollection<Violation> Violations { get; set; } = new List<Violation>();
    }
}
