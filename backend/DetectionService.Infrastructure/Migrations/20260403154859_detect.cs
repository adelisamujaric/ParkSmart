using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DetectionService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class detect : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ViolationConfigId",
                table: "DetectionLogs",
                type: "uniqueidentifier",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ViolationConfigId",
                table: "DetectionLogs");
        }
    }
}
