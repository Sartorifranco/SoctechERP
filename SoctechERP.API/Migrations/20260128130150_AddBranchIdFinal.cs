using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class AddBranchIdFinal : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2897));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2909));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2912));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2914));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2916));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2918));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 58, 47, 680, DateTimeKind.Local).AddTicks(1324));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 58, 47, 680, DateTimeKind.Local).AddTicks(1337));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 58, 47, 680, DateTimeKind.Local).AddTicks(1339));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 58, 47, 680, DateTimeKind.Local).AddTicks(1341));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 58, 47, 680, DateTimeKind.Local).AddTicks(1343));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 28, 9, 58, 47, 680, DateTimeKind.Local).AddTicks(1345));
        }
    }
}
