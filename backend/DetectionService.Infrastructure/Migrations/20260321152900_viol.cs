using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DetectionService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class viol : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ViolationType",
                table: "DetectionLogs",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ViolationType",
                table: "DetectionLogs");
        }
    }
}
