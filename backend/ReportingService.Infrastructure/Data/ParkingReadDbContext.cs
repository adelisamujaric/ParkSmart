using Microsoft.EntityFrameworkCore;
using ReportingService.Domain.Entities;

namespace ReportingService.Infrastructure
{
    public class ParkingReadDbContext : DbContext
    {
        public ParkingReadDbContext(DbContextOptions<ParkingReadDbContext> options) : base(options) { }

        public DbSet<ParkingLot> ParkingLots => Set<ParkingLot>();
        public DbSet<ParkingSpot> ParkingSpots => Set<ParkingSpot>();
        public DbSet<Ticket> Tickets => Set<Ticket>();
        public DbSet<Reservation> Reservations => Set<Reservation>();
        public DbSet<Violation> Violations => Set<Violation>();
        public DbSet<ViolationConfig> ViolationConfigs => Set<ViolationConfig>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ParkingLot>().ToTable("ParkingLots");
            modelBuilder.Entity<ParkingSpot>().ToTable("ParkingSpots");
            modelBuilder.Entity<Ticket>().ToTable("ParkingTickets");
            modelBuilder.Entity<Reservation>().ToTable("Reservations");
            modelBuilder.Entity<Violation>().ToTable("Violations");
            modelBuilder.Entity<ViolationConfig>().ToTable("ViolationConfigs");
        }
    }
}