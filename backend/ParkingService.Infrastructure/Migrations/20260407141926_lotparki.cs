using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ParkingService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class lotparki : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "LotId",
                table: "Violations",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ParkingLotId",
                table: "Violations",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Violations_ParkingLotId",
                table: "Violations",
                column: "ParkingLotId");

            migrationBuilder.AddForeignKey(
                name: "FK_Violations_ParkingLots_ParkingLotId",
                table: "Violations",
                column: "ParkingLotId",
                principalTable: "ParkingLots",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Violations_ParkingLots_ParkingLotId",
                table: "Violations");

            migrationBuilder.DropIndex(
                name: "IX_Violations_ParkingLotId",
                table: "Violations");

            migrationBuilder.DropColumn(
                name: "LotId",
                table: "Violations");

            migrationBuilder.DropColumn(
                name: "ParkingLotId",
                table: "Violations");
        }
    }
}
