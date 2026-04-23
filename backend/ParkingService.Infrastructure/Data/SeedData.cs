using ParkingService.Domain.Entities;
using ParkingService.Domain.Enums;
using ParkingService.Infrastructure.Data;

public static class SeedData
{
    public static void Initialize(ParkingDbContext db)
    {
        // ── ViolationConfigs ───────────────────────────────────────────────
        if (!db.ViolationConfigs.Any())
        {
            db.ViolationConfigs.AddRange(
                new ViolationConfig
                {
                    Id = Guid.Parse("18DDD194-234F-42EC-A806-39116C9DBF77"),
                    TypeName = "Prekršaj - Invalidsko mjesto",
                    Description = "Parkirali ste na invalidsko mjesto bez invalidske oznake",
                    FineAmount = 1000.00m,
                    CreatedAt = new DateTime(2026, 4, 3, 15, 21, 14),
                    UpdatedAt = new DateTime(2026, 4, 3, 15, 21, 14)
                },
                new ViolationConfig
                {
                    Id = Guid.Parse("E51E3AFD-EC1E-47F4-A042-4CE79238B183"),
                    TypeName = "Prekršaj - Istekao tiket",
                    Description = "Vas tiket je istekao",
                    FineAmount = 15.00m,
                    CreatedAt = new DateTime(2026, 4, 3, 15, 21, 59),
                    UpdatedAt = new DateTime(2026, 4, 3, 15, 22, 30)
                },
                new ViolationConfig
                {
                    Id = Guid.Parse("FAB2DAC1-661D-4B3D-AF38-834DD7146AFA"),
                    TypeName = "Prekršaj - Automobil nije na parking mjestu",
                    Description = "Mjesto na kojem ste parkirani nije označeno kao parking mjesto",
                    FineAmount = 20.00m,
                    CreatedAt = new DateTime(2026, 4, 6, 13, 51, 29),
                    UpdatedAt = new DateTime(2026, 4, 6, 13, 51, 29)
                },
                new ViolationConfig
                {
                    Id = Guid.Parse("45ED7BE3-C817-4025-B88E-C0FEC6C79163"),
                    TypeName = "Prekršaj - Van okvira parking mjesta",
                    Description = "Parkirali ste izvan okvira parking mjesta",
                    FineAmount = 15.00m,
                    CreatedAt = new DateTime(2026, 4, 6, 13, 50, 17),
                    UpdatedAt = new DateTime(2026, 4, 6, 13, 50, 17)
                }
            );
            db.SaveChanges();
        }

        // ── ParkingLots ────────────────────────────────────────────────────
        if (!db.ParkingLots.Any())
        {
            db.ParkingLots.AddRange(
                new ParkingLot
                {
                    Id = Guid.Parse("9D869D35-B576-47C6-881D-67603EDF3368"),
                    Name = "Zona C",
                    Address = "Dzemala Bijedica 127, 71000 Sarajevo",
                    Type = (ParkingLotType)0,
                    TotalSpots = 10,
                    RatePerMinute = 0.0200m,
                    ReservationRatePerMinute = 0.0050m,
                    OpenTime = new TimeOnly(5, 0),
                    CloseTime = new TimeOnly(23, 0),
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 3, 11, 12, 16),
                    UpdatedAt = new DateTime(2026, 3, 23, 18, 28, 31)
                },
                new ParkingLot
                {
                    Id = Guid.Parse("DB101DE5-8448-4C64-B6C8-83F42390572E"),
                    Name = "Zona B",
                    Address = "Dzemala Bijedica 127, 71000 Sarajevo",
                    Type = (ParkingLotType)0,
                    TotalSpots = 4,
                    RatePerMinute = 0.0200m,
                    ReservationRatePerMinute = null,
                    OpenTime = new TimeOnly(5, 0),
                    CloseTime = new TimeOnly(23, 0),
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 3, 11, 11, 39),
                    UpdatedAt = new DateTime(2026, 3, 3, 11, 11, 39)
                },
                new ParkingLot
                {
                    Id = Guid.Parse("4A965BC7-71B5-41A3-BA11-EC05E1AA00AE"),
                    Name = "Zona D",
                    Address = "Dzemala Bijedica 127, 71000 Sarajevo",
                    Type = (ParkingLotType)0,
                    TotalSpots = 5,
                    RatePerMinute = 0.0200m,
                    ReservationRatePerMinute = null,
                    OpenTime = new TimeOnly(8, 0),
                    CloseTime = new TimeOnly(22, 0),
                    IsActive = false,
                    CreatedAt = new DateTime(2026, 4, 9, 8, 33, 46),
                    UpdatedAt = new DateTime(2026, 4, 9, 8, 34, 0)
                },
                new ParkingLot
                {
                    Id = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97"),
                    Name = "Zona A",
                    Address = "Dzemala Bijedica 127, 71000 Sarajevo",
                    Type = (ParkingLotType)1,
                    TotalSpots = 16,
                    RatePerMinute = 0.0300m,
                    ReservationRatePerMinute = null,
                    OpenTime = new TimeOnly(5, 0),
                    CloseTime = new TimeOnly(23, 0),
                    IsActive = true,
                    CreatedAt = new DateTime(2026, 3, 3, 9, 54, 42),
                    UpdatedAt = new DateTime(2026, 3, 3, 11, 13, 33)
                }
            );
            db.SaveChanges();
        }

        // ── ParkingSpots ───────────────────────────────────────────────────
        if (!db.ParkingSpots.Any())
        {
            var lotA = Guid.Parse("DD005F9D-6D3B-45DC-AED4-F9BDB909FE97");
            var lotB = Guid.Parse("DB101DE5-8448-4C64-B6C8-83F42390572E");
            var lotC = Guid.Parse("9D869D35-B576-47C6-881D-67603EDF3368");
            var lotD = Guid.Parse("4A965BC7-71B5-41A3-BA11-EC05E1AA00AE");

            db.ParkingSpots.AddRange(
                // Zona B
                new ParkingSpot { Id = Guid.Parse("3ABD6589-56FD-4412-88F5-0D24D7DE98ED"), LotId = lotB, SpotNumber = "B1", Type = (ParkingSpotType)1, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 49, 8), UpdatedAt = new DateTime(2026, 4, 5, 12, 31, 11) },
                new ParkingSpot { Id = Guid.Parse("313E73BD-399E-4892-909D-37FBDCE0B827"), LotId = lotB, SpotNumber = "B3", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 49, 25), UpdatedAt = new DateTime(2026, 4, 5, 13, 33, 42) },
                new ParkingSpot { Id = Guid.Parse("A8A44950-B15F-4663-8642-541DFA46B472"), LotId = lotB, SpotNumber = "B2", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 49, 18), UpdatedAt = new DateTime(2026, 4, 1, 18, 1, 4) },
                new ParkingSpot { Id = Guid.Parse("EF2BB084-B152-4FFE-8FB6-E8D6AE276872"), LotId = lotB, SpotNumber = "B4", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 49, 31), UpdatedAt = new DateTime(2026, 4, 2, 9, 50, 56) },

                // Zona A
                new ParkingSpot { Id = Guid.Parse("135606DB-6D1D-4FB1-827E-26274E75B9A7"), LotId = lotA, SpotNumber = "A14", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 41), UpdatedAt = new DateTime(2026, 4, 2, 14, 59, 59) },
                new ParkingSpot { Id = Guid.Parse("1A4D3BBF-062C-412F-91F8-2E67F3E788B3"), LotId = lotA, SpotNumber = "A7", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 0), UpdatedAt = new DateTime(2026, 4, 10, 9, 45, 24) },
                new ParkingSpot { Id = Guid.Parse("2FBAB5F4-0BE6-41CB-B3D9-2F6DB524EB3E"), LotId = lotA, SpotNumber = "A8", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 5), UpdatedAt = new DateTime(2026, 4, 1, 17, 48, 34) },
                new ParkingSpot { Id = Guid.Parse("DAD51B4D-5FA4-40C4-B39F-2F775DD0EC93"), LotId = lotA, SpotNumber = "A2", Type = (ParkingSpotType)1, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 50, 13), UpdatedAt = new DateTime(2026, 3, 3, 11, 50, 13) },
                new ParkingSpot { Id = Guid.Parse("95C8E5D0-1F02-4E37-9BEE-499F27739098"), LotId = lotA, SpotNumber = "A9", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 15), UpdatedAt = new DateTime(2026, 4, 10, 9, 47, 21) },
                new ParkingSpot { Id = Guid.Parse("2734F8FB-3617-4AD4-AF11-4F9EC0AEBA60"), LotId = lotA, SpotNumber = "A1", Type = (ParkingSpotType)1, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 50, 5), UpdatedAt = new DateTime(2026, 3, 3, 11, 50, 5) },
                new ParkingSpot { Id = Guid.Parse("3701BECA-BDBF-4276-9EA8-5261101E5D53"), LotId = lotA, SpotNumber = "A12", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 34), UpdatedAt = new DateTime(2026, 4, 2, 15, 20, 32) },
                new ParkingSpot { Id = Guid.Parse("ED51D713-3F14-40E3-B2F8-5CD0A87B7227"), LotId = lotA, SpotNumber = "A15", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 46), UpdatedAt = new DateTime(2026, 4, 5, 15, 39, 25) },
                new ParkingSpot { Id = Guid.Parse("672966E3-2830-4A3C-A3A7-84DB34C3A9C2"), LotId = lotA, SpotNumber = "A13", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 37), UpdatedAt = new DateTime(2026, 3, 3, 11, 51, 37) },
                new ParkingSpot { Id = Guid.Parse("685A78EF-3C59-4F38-9129-865D209A12EB"), LotId = lotA, SpotNumber = "A11", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 29), UpdatedAt = new DateTime(2026, 4, 1, 17, 21, 18) },
                new ParkingSpot { Id = Guid.Parse("755265C1-7E63-409D-86BA-953564F3FAEA"), LotId = lotA, SpotNumber = "A10", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 25), UpdatedAt = new DateTime(2026, 3, 3, 11, 51, 25) },
                new ParkingSpot { Id = Guid.Parse("28634B25-63B2-4634-908C-959ED2141888"), LotId = lotA, SpotNumber = "A6", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 50, 53), UpdatedAt = new DateTime(2026, 3, 3, 11, 50, 53) },
                new ParkingSpot { Id = Guid.Parse("FCA5B1A4-4330-4028-A7D8-A3E4B84862F8"), LotId = lotA, SpotNumber = "A5", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 50, 49), UpdatedAt = new DateTime(2026, 3, 3, 11, 50, 49) },
                new ParkingSpot { Id = Guid.Parse("804367FD-F061-46E0-B3CE-A51B8477480D"), LotId = lotA, SpotNumber = "A4", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 50, 36), UpdatedAt = new DateTime(2026, 3, 3, 11, 50, 36) },
                new ParkingSpot { Id = Guid.Parse("D8486CE9-7C60-478F-965C-B137659ED71B"), LotId = lotA, SpotNumber = "A16", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 51, 49), UpdatedAt = new DateTime(2026, 3, 3, 11, 51, 49) },
                new ParkingSpot { Id = Guid.Parse("43D459BF-48A4-4464-B9F1-F3E69880517D"), LotId = lotA, SpotNumber = "A3", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 50, 28), UpdatedAt = new DateTime(2026, 3, 3, 11, 50, 28) },

                // Zona C
                new ParkingSpot { Id = Guid.Parse("86BBF54F-96D7-4A9C-8BAA-32FA8D8D7667"), LotId = lotC, SpotNumber = "C1", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = true, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 26, 21), UpdatedAt = new DateTime(2026, 4, 10, 15, 59, 26) },
                new ParkingSpot { Id = Guid.Parse("E80AE2E0-1301-4717-9E77-459EDFF0396C"), LotId = lotC, SpotNumber = "C2", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = true, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 26, 30), UpdatedAt = new DateTime(2026, 4, 5, 15, 56, 12) },
                new ParkingSpot { Id = Guid.Parse("7674275A-AC6E-4120-9EC5-6F14B3291DBC"), LotId = lotC, SpotNumber = "C10", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 27, 39), UpdatedAt = new DateTime(2026, 4, 9, 12, 22, 38) },
                new ParkingSpot { Id = Guid.Parse("98ABDC96-96B4-4A5D-90A5-829BF2BF3D1E"), LotId = lotC, SpotNumber = "C7", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 27, 18), UpdatedAt = new DateTime(2026, 4, 9, 14, 26, 27) },
                new ParkingSpot { Id = Guid.Parse("BFE78973-31DF-4B3A-949B-8FF1C29C1EE6"), LotId = lotC, SpotNumber = "C3", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = true, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 26, 39), UpdatedAt = new DateTime(2026, 4, 5, 15, 10, 9) },
                new ParkingSpot { Id = Guid.Parse("1CA468C8-1EE9-4956-8C25-99B42238AC1E"), LotId = lotC, SpotNumber = "C9", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 27, 31), UpdatedAt = new DateTime(2026, 4, 2, 12, 2, 7) },
                new ParkingSpot { Id = Guid.Parse("9A5510CD-54FC-4E92-B93E-A1DFB76BE86E"), LotId = lotC, SpotNumber = "C6", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 27, 14), UpdatedAt = new DateTime(2026, 4, 2, 15, 36, 0) },
                new ParkingSpot { Id = Guid.Parse("5C70FF9D-AF99-4221-800D-BB8E37588CB1"), LotId = lotC, SpotNumber = "C8", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 27, 21), UpdatedAt = new DateTime(2026, 4, 4, 16, 40, 17) },
                new ParkingSpot { Id = Guid.Parse("AF259763-3B87-4B79-8E12-C33312D5CE24"), LotId = lotC, SpotNumber = "C5", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 20, 1), UpdatedAt = new DateTime(2026, 4, 4, 16, 47, 50) },
                new ParkingSpot { Id = Guid.Parse("B9322716-3B1D-4207-88AC-FE9C78C0C0DE"), LotId = lotC, SpotNumber = "C4", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = 0, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 3, 3, 11, 26, 53), UpdatedAt = new DateTime(2026, 4, 5, 12, 25, 8) },

                // Zona D
                new ParkingSpot { Id = Guid.Parse("B13C5290-51CD-420C-ABEA-332EEB4F3FBF"), LotId = lotD, SpotNumber = "D5", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = null, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 4, 9, 8, 33, 47), UpdatedAt = new DateTime(2026, 4, 9, 8, 33, 47) },
                new ParkingSpot { Id = Guid.Parse("34EE416A-2567-481A-941E-34BDADDFD20B"), LotId = lotD, SpotNumber = "D1", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = null, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 4, 9, 8, 33, 47), UpdatedAt = new DateTime(2026, 4, 9, 8, 33, 47) },
                new ParkingSpot { Id = Guid.Parse("903C074C-F417-4208-AE47-7E5D45B38DC5"), LotId = lotD, SpotNumber = "D4", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = null, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 4, 9, 8, 33, 47), UpdatedAt = new DateTime(2026, 4, 9, 8, 33, 47) },
                new ParkingSpot { Id = Guid.Parse("7E239678-D187-4E65-89E7-A5621A753881"), LotId = lotD, SpotNumber = "D3", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = null, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 4, 9, 8, 33, 47), UpdatedAt = new DateTime(2026, 4, 9, 8, 33, 47) },
                new ParkingSpot { Id = Guid.Parse("9BD3AB50-7761-4F38-9F23-FC1ECF22CF99"), LotId = lotD, SpotNumber = "D2", Type = (ParkingSpotType)0, Status = (ParkingSpotStatus)0, Floor = null, IsReservable = false, IsDeleted = false, CreatedAt = new DateTime(2026, 4, 9, 8, 33, 47), UpdatedAt = new DateTime(2026, 4, 9, 8, 33, 47) }
            );
            db.SaveChanges();
        }
    }
}