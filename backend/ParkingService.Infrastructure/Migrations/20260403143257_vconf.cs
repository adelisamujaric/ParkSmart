using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ParkingService.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class vconf : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Type",
                table: "Violations");

            migrationBuilder.AddColumn<Guid>(
                name: "ViolationConfigId",
                table: "Violations",
                type: "uniqueidentifier",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_Violations_ViolationConfigId",
                table: "Violations",
                column: "ViolationConfigId");

            migrationBuilder.AddForeignKey(
                name: "FK_Violations_ViolationConfigs_ViolationConfigId",
                table: "Violations",
                column: "ViolationConfigId",
                principalTable: "ViolationConfigs",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Violations_ViolationConfigs_ViolationConfigId",
                table: "Violations");

            migrationBuilder.DropIndex(
                name: "IX_Violations_ViolationConfigId",
                table: "Violations");

            migrationBuilder.DropColumn(
                name: "ViolationConfigId",
                table: "Violations");

            migrationBuilder.AddColumn<int>(
                name: "Type",
                table: "Violations",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }
    }
}
