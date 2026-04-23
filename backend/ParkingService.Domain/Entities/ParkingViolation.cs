using ParkingService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Domain.Entities
{
    public class Violation
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }

        public Guid? LotId { get; set; }
        public ParkingLot? ParkingLot { get; set; }

        public Guid? SpotId { get; set; }
        public Guid? TicketId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;

        public Guid ViolationConfigId { get; set; }
        public ViolationConfig? ViolationConfig { get; set; }

        public string Description { get; set; } = string.Empty;
        public string? PhotoUrl { get; set; }
        public decimal FineAmount { get; set; }
        public bool IsResolved { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;


        // Navigation properties
        public ParkingSpot? ParkingSpot { get; set; } = null!;
        public Ticket? Ticket { get; set; }
    }
}
