using Microsoft.EntityFrameworkCore;
using ParkingService.Domain.Entities;
using System.Collections.Generic;
using System.Reflection.Emit;

namespace ParkingService.Infrastructure.Data;

public class ParkingDbContext : DbContext
{
    public ParkingDbContext(DbContextOptions<ParkingDbContext> options) : base(options) { }

    public DbSet<ParkingLot> ParkingLots { get; set; }
    public DbSet<ParkingSpot> ParkingSpots { get; set; }
    public DbSet<Reservation> Reservations { get; set; }
    public DbSet<Ticket> ParkingTickets { get; set; }
    public DbSet<Violation> Violations { get; set; }
    public DbSet<ViolationConfig> ViolationConfigs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ParkingLot
        modelBuilder.Entity<ParkingLot>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Address).IsRequired().HasMaxLength(250);
            entity.Property(e => e.RatePerMinute).HasColumnType("decimal(10,4)");
            entity.Property(e => e.ReservationRatePerMinute).HasColumnType("decimal(10,4)");
        });

        // ParkingSpot
        modelBuilder.Entity<ParkingSpot>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SpotNumber).IsRequired().HasMaxLength(10);
            entity.HasOne(e => e.ParkingLot)
                  .WithMany(e => e.ParkingSpots)
                  .HasForeignKey(e => e.LotId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Reservation
        modelBuilder.Entity<Reservation>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.LicensePlate).IsRequired().HasMaxLength(20);
            entity.Property(e => e.TotalPrice).HasColumnType("decimal(10,2)");
            entity.HasOne(e => e.ParkingSpot)
                  .WithMany(e => e.Reservations)
                  .HasForeignKey(e => e.SpotId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // ParkingTicket
        modelBuilder.Entity<Ticket>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.LicensePlate).IsRequired().HasMaxLength(20);
            entity.Property(e => e.TotalPrice).HasColumnType("decimal(10,2)");
            entity.HasOne(e => e.ParkingSpot)
                  .WithMany(e => e.Tickets)
                  .HasForeignKey(e => e.SpotId)
                  .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(e => e.Reservation)
                  .WithOne(e => e.Ticket)
                  .HasForeignKey<Ticket>(e => e.ReservationId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(e => e.ParkingLot)
                  .WithMany()
                  .HasForeignKey(e => e.LotId)
                  .OnDelete(DeleteBehavior.SetNull);


        });

        // Violation
        modelBuilder.Entity<Violation>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.LicensePlate).IsRequired().HasMaxLength(20);
            entity.Property(e => e.FineAmount).HasColumnType("decimal(10,2)");
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.PhotoUrl).HasMaxLength(500);
            entity.HasOne(e => e.ParkingSpot)
                  .WithMany(e => e.Violations)
                  .HasForeignKey(e => e.SpotId)
                  .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(e => e.Ticket)
                  .WithMany(e => e.Violations)
                  .HasForeignKey(e => e.TicketId)
                  .OnDelete(DeleteBehavior.SetNull);
            entity.HasOne(e => e.ViolationConfig)
                  .WithMany(e => e.Violations)
                  .HasForeignKey(e => e.ViolationConfigId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ViolationConfig>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TypeName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Description).HasMaxLength(500);
            entity.Property(e => e.FineAmount).HasColumnType("decimal(10,2)");
        });
    }
}