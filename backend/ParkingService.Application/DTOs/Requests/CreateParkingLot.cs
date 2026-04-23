using ParkingService.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Application.DTOs.Requests
{
    public class CreateParkingLotDto
    {
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public ParkingLotType Type { get; set; }
        public int TotalSpots { get; set; }
        public decimal RatePerMinute { get; set; }
        public decimal? ReservationRatePerMinute { get; set; }
        public TimeOnly OpenTime { get; set; }
        public TimeOnly CloseTime { get; set; }
    }
}
