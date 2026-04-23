using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Application.DTOs.Requests
{
    public class CreateReservationDto
    {
        public Guid SpotId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
    }
}
