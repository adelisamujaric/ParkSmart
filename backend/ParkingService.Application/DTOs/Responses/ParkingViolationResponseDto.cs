using ParkingService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Application.DTOs.Responses
{
    public class ParkingViolationResponseDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid? SpotId { get; set; }
        public string SpotNumber { get; set; } = string.Empty;
        public string LotName { get; set; } = string.Empty;
        public Guid? TicketId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid ViolationConfigId { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public decimal ConfigFineAmount { get; set; }
        public string Description { get; set; } = string.Empty;
        public string? PhotoUrl { get; set; }
        public decimal FineAmount { get; set; }
      
        public bool IsResolved { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
