using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Application.DTOs.Requests
{
    public class UpdateParkingSpotDto
    {
        public string? SpotNumber { get; set; }
        public ParkingSpotType? Type { get; set; }
        public bool? IsReservable { get; set; }
        public int? Floor { get; set; }
    }
}
