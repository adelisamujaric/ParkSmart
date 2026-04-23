using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Application.DTOs.Responses
{
    public class ParkingTicketResponseDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? SpotId { get; set; }
        public string SpotNumber { get; set; } = string.Empty;
        public string LotName { get; set; } = string.Empty;
        public string LotAddress { get; set; } = string.Empty;
        public Guid? ReservationId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public DateTime EntryTime { get; set; }
        public DateTime? ExitTime { get; set; }
        public DateTime? EndTime { get; set; }
        public decimal? TotalPrice { get; set; }
        public DateTime? PaymentDeadline { get; set; }
        public decimal LateFee { get; set; }
        public TicketStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
