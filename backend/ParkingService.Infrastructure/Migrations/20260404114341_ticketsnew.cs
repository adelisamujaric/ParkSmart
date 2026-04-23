using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ParkingService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class ticketsnew : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "LotId",
                table: "ParkingTickets",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ParkingTickets_LotId",
                table: "ParkingTickets",
                column: "LotId");

            migrationBuilder.AddForeignKey(
                name: "FK_ParkingTickets_ParkingLots_LotId",
                table: "ParkingTickets",
                column: "LotId",
                principalTable: "ParkingLots",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ParkingTickets_ParkingLots_LotId",
                table: "ParkingTickets");

            migrationBuilder.DropIndex(
                name: "IX_ParkingTickets_LotId",
                table: "ParkingTickets");

            migrationBuilder.DropColumn(
                name: "LotId",
                table: "ParkingTickets");
        }
    }
}
