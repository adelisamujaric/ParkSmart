using Microsoft.EntityFrameworkCore;
using UserService.Infrastructure.Data;
using UserService.Modules.Entities;
using UserService.Modules.Enums;

public static class SeedData
{
    public static void Initialize(UserDbContext db)
    {
        // ── Users ──────────────────────────────────────────────────────────
        if (!db.Users.Any())
        {
            var users = new List<User>
            {
                new User
                {
                    Id = Guid.Parse("1FE72A71-9B88-4BD4-90C5-17BD32D09CD7"),
                    FirstName = "Adelisa",
                    LastName = "Mujaric",
                    Address = "Dzemala Bijedica 160",
                    City = "Sarajevo",
                    PostalCode = "71000",
                    Country = "Bosna i Hercegovina",
                    PhoneNumber = null,
                    Email = "user@email.com",
                    PasswordHash = "$2a$11$Sqg5q5mttbDqlOhWLPzc3ePQ09G7Ox7b/zVgiDNtmcZz/2UCtF0xS",
                    Role = (UserRoles)0,
                    CreatedAt = new DateTime(2026, 3, 3, 13, 30, 50),
                    IsActive = true,
                    IsEmailVerified = true,
                    IsDisabled = false
                },
                new User
                {
                    Id = Guid.Parse("1B678C33-9ADC-4074-9DBC-C7C89CA3107A"),
                    FirstName = "admin",
                    LastName = "admin",
                    Address = null,
                    City = null,
                    PostalCode = null,
                    Country = null,
                    PhoneNumber = null,
                    Email = "admin@email.com",
                    PasswordHash = "$2a$11$O7rfigq76rcExspUqrHB4.7E/8phvphc8UmopTr2qe8PHxoG0CMKa",
                    Role = (UserRoles)1,
                    CreatedAt = new DateTime(2026, 3, 21, 15, 9, 38),
                    IsActive = true,
                    IsEmailVerified = true,
                    IsDisabled = false
                }
            };

            db.Users.AddRange(users);
            db.SaveChanges();
        }

        // ── Vehicles ───────────────────────────────────────────────────────
        if (!db.Vehicles.Any())
        {
            var userId = Guid.Parse("1FE72A71-9B88-4BD4-90C5-17BD32D09CD7");

            var vehicles = new List<Vehicle>
            {
                new Vehicle { Id = Guid.Parse("7EE98C03-ED7D-43F7-A2DA-409DB114422E"), LicensePlate = "F25-Z-397", Brand = "VW",     Model = "New Beetle",    UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 8,  44), IsActive = true },
                new Vehicle { Id = Guid.Parse("BA91D60A-755D-40B9-A353-467C451DADE1"), LicensePlate = "E59-X-895", Brand = "Skoda",  Model = "Octavia",       UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 13, 28), IsActive = true },
                new Vehicle { Id = Guid.Parse("13C86E3E-217E-4F77-A44E-6ED347E155BB"), LicensePlate = "M86-C-722", Brand = "Audi",   Model = "TT",            UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 7,  8),  IsActive = true },
                new Vehicle { Id = Guid.Parse("79DFA0AF-F61B-46D3-82C1-7D90CADD3ACE"), LicensePlate = "J23-U-391", Brand = "VW",     Model = "New Beetle",    UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 8,  6),  IsActive = true },
                new Vehicle { Id = Guid.Parse("4D39BA04-FDF2-4028-93E7-8BED66A79DA8"), LicensePlate = "T66-W-166", Brand = "Porsche",Model = "Cayman S",      UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 9,  36), IsActive = true },
                new Vehicle { Id = Guid.Parse("95E4A502-21CC-4DC4-85F4-97B3E73B9886"), LicensePlate = "E88-N-947", Brand = "Mini",   Model = "Mini Cooper",   UserId = userId, CreatedAt = new DateTime(2026, 3, 31, 9, 34, 18), IsActive = true },
                new Vehicle { Id = Guid.Parse("C3A31549-6403-42AE-841E-A0838EE61AFD"), LicensePlate = "A77-N-711", Brand = "Nissan", Model = "370Z",          UserId = userId, CreatedAt = new DateTime(2026, 3, 3, 13, 33, 59), IsActive = true },
                new Vehicle { Id = Guid.Parse("C5475389-A626-4894-91C3-C77AC32E4873"), LicensePlate = "J52-H-693", Brand = "Tesla",  Model = "Model Y",       UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 11, 38), IsActive = true },
                new Vehicle { Id = Guid.Parse("EBF00D95-C469-4E46-8EA3-DE99FBA19339"), LicensePlate = "T19-K-454", Brand = "Porsche",Model = "Taycan Turbo S",UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 10, 19), IsActive = true },
                new Vehicle { Id = Guid.Parse("9F0642C6-3A47-49E6-8154-E91E149C26AC"), LicensePlate = "K84-M-612", Brand = "VW",     Model = "Golf IV",       UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 10, 54), IsActive = true },
                new Vehicle { Id = Guid.Parse("73203459-3CDB-489E-A0DE-F2D7B69AB3F4"), LicensePlate = "M82-J-389", Brand = "BMW",    Model = "7",             UserId = userId, CreatedAt = new DateTime(2026, 4, 5, 11, 13, 59), IsActive = true },
            };

            db.Vehicles.AddRange(vehicles);
            db.SaveChanges();
        }
    }
}