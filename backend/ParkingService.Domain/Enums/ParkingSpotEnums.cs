using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Domain.Enums
{
    public enum ParkingSpotType
    {
        Normal = 0,
        Disabled = 1,
        ElectricVehicle = 2
    }

    public enum ParkingSpotStatus
    {
        Available = 0,
        Occupied = 1,
        Reserved = 2,
        OutOfService = 3
    }
}
