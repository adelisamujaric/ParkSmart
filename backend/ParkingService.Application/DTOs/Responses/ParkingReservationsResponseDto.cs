using ParkingService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Application.DTOs.Responses
{
    public class ParkingReservationResponseDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public Guid SpotId { get; set; }
        public string SpotNumber { get; set; } = string.Empty;
        public string LotName { get; set; } = string.Empty;
        public string LicensePlate { get; set; } = string.Empty;
        public string LotAddress { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public decimal TotalPrice { get; set; }
        public ReservationStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
