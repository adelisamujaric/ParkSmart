using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ParkingService.Domain.Enums;

namespace ParkingService.Application.DTOs.Responses
{
    public class ParkingSpotResponseDto
    {
        public Guid Id { get; set; }
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public string SpotNumber { get; set; } = string.Empty;
        public ParkingSpotType Type { get; set; }
        public ParkingSpotStatus Status { get; set; }
        public bool IsReservable { get; set; }
        public int? Floor { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
