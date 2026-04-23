using DetectionService.Domain.Entities;
using DetectionService.Domain.Enums;
using DetectionService.Infrastructure.Data;

public static class SeedData
{
    public static void Initialize(DetectionDbContext db)
    {
        // ── Cameras ────────────────────────────────────────────────────────
        if (!db.Cameras.Any())
        {
            db.Cameras.AddRange(
                new Camera
                {
                    Id = Guid.Parse("9C0C6227-B13B-4D10-AACC-4F1D6FEF11C6"),
                    Number = 1,
                    LotId = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    LotName = "Zona A",
                    CameraType = DetectionCameraType.Entry,
                    Status = CameraStatus.Active,
                    CreatedAt = new DateTime(2026, 3, 21, 11, 19, 56)
                },
                new Camera
                {
                    Id = Guid.Parse("03948509-8A46-4802-8E8C-4B91EA72981D"),
                    Number = 2,
                    LotId = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    LotName = "Zona A",
                    CameraType = DetectionCameraType.Exit,
                    Status = CameraStatus.Active,
                    CreatedAt = new DateTime(2026, 3, 21, 13, 18, 1)
                },
                new Camera
                {
                    Id = Guid.Parse("B83205C4-9639-41BF-9881-0E582BFEE279"),
                    Number = 3,
                    LotId = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    LotName = "Zona A",
                    CameraType = DetectionCameraType.Entry,
                    Status = CameraStatus.Offline,
                    CreatedAt = new DateTime(2026, 4, 9, 8, 29, 58)
                },
                new Camera
                {
                    Id = Guid.Parse("C0E721E7-AE00-46FC-B0EE-D4DEAE77C8F5"),
                    Number = 4,
                    LotId = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    LotName = "Zona A",
                    CameraType = DetectionCameraType.Exit,
                    Status = CameraStatus.Offline,
                    CreatedAt = new DateTime(2026, 4, 9, 8, 30, 41)
                }
            );
            db.SaveChanges();
        }

        // ── Drones ─────────────────────────────────────────────────────────
        if (!db.Drones.Any())
        {
            db.Drones.AddRange(
                new Drone
                {
                    Id = Guid.Parse("7712B8CD-F9A6-4EB2-AADD-A3DDD74809A7"),
                    Number = 1,
                    LotId = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    LotName = "Zona A",
                    Status = DroneStatus.Active,
                    BatteryLevel = 50,
                    TimeToCharge = new TimeSpan(1, 0, 0),
                    CreatedAt = new DateTime(2026, 3, 21, 11, 21, 41)
                },
                new Drone
                {
                    Id = Guid.Parse("CB409382-C9DA-4121-B55F-3CF34D4A383C"),
                    Number = 2,
                    LotId = Guid.Parse("DB101DE5-8448-4C64-B6C8-83F42390572E"),
                    LotName = "Zona B",
                    Status = DroneStatus.Active,
                    BatteryLevel = 100,
                    TimeToCharge = null,
                    CreatedAt = new DateTime(2026, 3, 21, 13, 7, 59)
                },
                new Drone
                {
                    Id = Guid.Parse("31B27637-F490-4DB5-8A86-6E77DCC756F9"),
                    Number = 3,
                    LotId = Guid.Parse("9D869D35-B576-47C6-881D-67603EDF3368"),
                    LotName = "Zona C",
                    Status = DroneStatus.Active,
                    BatteryLevel = 20,
                    TimeToCharge = null,
                    CreatedAt = new DateTime(2026, 3, 21, 13, 12, 36)
                },
                new Drone
                {
                    Id = Guid.Parse("E06324C1-2C5E-4459-A7A4-6FD6C3E7268B"),
                    Number = 4,
                    LotId = Guid.Parse("DB101DE5-8448-4C64-B6C8-83F42390572E"),
                    LotName = "Zona B",
                    Status = DroneStatus.Inactive,
                    BatteryLevel = 70,
                    TimeToCharge = null,
                    CreatedAt = new DateTime(2026, 4, 9, 8, 27, 34)
                },
                new Drone
                {
                    Id = Guid.Parse("A69E9CE0-D98C-4AAB-B116-26F7D2C52272"),
                    Number = 5,
                    LotId = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    LotName = "Zona A",
                    Status = DroneStatus.Charging,
                    BatteryLevel = 10,
                    TimeToCharge = null,
                    CreatedAt = new DateTime(2026, 4, 9, 8, 28, 5)
                }
            );
            db.SaveChanges();
        }
    }
}