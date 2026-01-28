using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class AddBranchIdToWarehouse_V2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 47, 9, 488, DateTimeKind.Local).AddTicks(1053));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 47, 9, 488, DateTimeKind.Local).AddTicks(1064));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 47, 9, 488, DateTimeKind.Local).AddTicks(1066));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 47, 9, 488, DateTimeKind.Local).AddTicks(1068));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 47, 9, 488, DateTimeKind.Local).AddTicks(1070));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 47, 9, 488, DateTimeKind.Local).AddTicks(1073));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 45, 16, 383, DateTimeKind.Local).AddTicks(9603));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 45, 16, 383, DateTimeKind.Local).AddTicks(9615));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 45, 16, 383, DateTimeKind.Local).AddTicks(9617));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 45, 16, 383, DateTimeKind.Local).AddTicks(9619));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 45, 16, 383, DateTimeKind.Local).AddTicks(9621));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 45, 16, 383, DateTimeKind.Local).AddTicks(9629));
        }
    }
}
