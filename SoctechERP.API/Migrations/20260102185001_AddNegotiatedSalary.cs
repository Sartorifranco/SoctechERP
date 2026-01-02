using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class AddNegotiatedSalary : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "NegotiatedSalary",
                table: "Employees",
                type: "numeric(18,2)",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 15, 50, 1, 224, DateTimeKind.Local).AddTicks(83));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 15, 50, 1, 224, DateTimeKind.Local).AddTicks(119));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 15, 50, 1, 224, DateTimeKind.Local).AddTicks(136));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 15, 50, 1, 224, DateTimeKind.Local).AddTicks(138));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 15, 50, 1, 224, DateTimeKind.Local).AddTicks(140));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 15, 50, 1, 224, DateTimeKind.Local).AddTicks(146));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "NegotiatedSalary",
                table: "Employees");

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 12, 41, 28, 369, DateTimeKind.Local).AddTicks(8925));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 12, 41, 28, 369, DateTimeKind.Local).AddTicks(8938));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 12, 41, 28, 369, DateTimeKind.Local).AddTicks(8940));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 12, 41, 28, 369, DateTimeKind.Local).AddTicks(8952));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 12, 41, 28, 369, DateTimeKind.Local).AddTicks(8954));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 12, 41, 28, 369, DateTimeKind.Local).AddTicks(8956));
        }
    }
}
