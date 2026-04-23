using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Domain.Entities
{
    public class ParkingSpot
    {
        public Guid Id { get; set; }
        public Guid LotId { get; set; }
        public string SpotNumber { get; set; } = string.Empty;
        public ParkingSpotType Type { get; set; } = ParkingSpotType.Normal;
        public ParkingSpotStatus Status { get; set; } = ParkingSpotStatus.Available;
        public bool IsReservable { get; set; }
        public int? Floor { get; set; }
        public bool IsDeleted { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public ParkingLot ParkingLot { get; set; } = null!;
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
        public ICollection<Violation> Violations { get; set; } = new List<Violation>();
    }
}
