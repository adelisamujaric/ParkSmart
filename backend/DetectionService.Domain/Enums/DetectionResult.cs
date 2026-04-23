using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DetectionService.Domain.Enums
{
    public enum DetectionResult
    {
        EntryGranted = 0,      // Entry kamera - auto smije ući
        ExitGranted = 1,       // Exit kamera - auto smije izaći  
        VehicleValid = 2,      // Dron - auto ima validan ticket
        ViolationDetected = 3, // Dron - prekršaj detektovan
        UnknownVehicle = 4     // Tablica nije prepoznata
    }
}
