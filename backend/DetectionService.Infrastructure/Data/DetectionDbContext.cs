using DetectionService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DetectionService.Infrastructure.Data
{
    public class DetectionDbContext : DbContext
    {
        public DetectionDbContext(DbContextOptions<DetectionDbContext> options) : base(options) { }

        public DbSet<DetectionLog> DetectionLogs => Set<DetectionLog>();
        public DbSet<Drone> Drones { get; set; }
        public DbSet<Camera> Cameras { get; set; }
        //--------------------------------------------------------------------

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<DetectionLog>().ToTable("DetectionLogs");

        }
    }
}
