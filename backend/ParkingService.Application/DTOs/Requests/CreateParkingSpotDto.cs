using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;

namespace ParkingService.Application.DTOs.Requests
{
    public class CreateParkingSpotDto
    {
        public Guid LotId { get; set; }
        public string SpotNumber { get; set; } = string.Empty;
        public ParkingSpotType Type { get; set; } = ParkingSpotType.Normal;
        public bool IsReservable { get; set; }
        public int? Floor { get; set; }
    }
}
