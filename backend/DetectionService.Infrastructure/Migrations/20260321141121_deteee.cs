using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DetectionService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class deteee : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CameraNumber",
                table: "DetectionLogs",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DroneNumber",
                table: "DetectionLogs",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CameraNumber",
                table: "DetectionLogs");

            migrationBuilder.DropColumn(
                name: "DroneNumber",
                table: "DetectionLogs");
        }
    }
}
