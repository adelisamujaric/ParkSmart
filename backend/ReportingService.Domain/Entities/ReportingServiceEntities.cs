using ReportingService.Domain.Enums;
using System.ComponentModel.DataAnnotations.Schema;

namespace ReportingService.Domain.Entities
{
    public class ParkingLot
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public ParkingLotType Type { get; set; }
        public int TotalSpots { get; set; }
        public decimal RatePerMinute { get; set; }
        public decimal? ReservationRatePerMinute { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public ICollection<ParkingSpot> ParkingSpots { get; set; } = new List<ParkingSpot>();
    }

    public class ParkingSpot
    {
        public Guid Id { get; set; }
        public Guid LotId { get; set; }
        [ForeignKey("LotId")]
        public ParkingLot ParkingLot { get; set; } = null!;
        public string SpotNumber { get; set; } = string.Empty;
        public bool IsDeleted { get; set; }
        public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Violation> Violations { get; set; } = new List<Violation>();
    }

    public class Ticket
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid SpotId { get; set; }
        [ForeignKey("SpotId")]
        public ParkingSpot ParkingSpot { get; set; } = null!;
        public Guid? ReservationId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public DateTime EntryTime { get; set; }
        public DateTime? ExitTime { get; set; }
        public DateTime? EndTime { get; set; }
        public decimal? TotalPrice { get; set; }
        public TicketStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public ICollection<Violation> Violations { get; set; } = new List<Violation>();
    }

    public class Reservation
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid SpotId { get; set; }
        [ForeignKey("SpotId")]
        public ParkingSpot ParkingSpot { get; set; } = null!;
        public string LicensePlate { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public ReservationStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class ViolationConfig
    {
        public Guid Id { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal FineAmount { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class Violation
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? SpotId { get; set; }

        [ForeignKey("SpotId")]
        public ParkingSpot? ParkingSpot { get; set; } = null!;

        public Guid? LotId { get; set; }
        public ParkingLot? ParkingLot { get; set; }

        public Guid? TicketId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid ViolationConfigId { get; set; }  
        public string Description { get; set; } = string.Empty;  
        public string? PhotoUrl { get; set; }  
        public decimal FineAmount { get; set; }
        
        public bool IsResolved { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public ViolationConfig? ViolationConfig { get; set; }
    }
}