using ParkingService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Application.DTOs.Requests
{
    public class CreateParkingViolationDto
    {
        public Guid UserId { get; set; }
        public Guid? SpotId { get; set; }
        public Guid? TicketId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid ViolationConfigId { get; set; }
        public string Description { get; set; } = string.Empty;
        public string? PhotoUrl { get; set; }
        public decimal FineAmount { get; set; }
    }
}
