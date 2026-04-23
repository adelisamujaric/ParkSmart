using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Application.DTOs.Requests
{
    public class CreateParkingTicketDto
    {
        public Guid SpotId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public Guid? ReservationId { get; set; }
        public int? DurationMinutes { get; set; } 
    }
}

