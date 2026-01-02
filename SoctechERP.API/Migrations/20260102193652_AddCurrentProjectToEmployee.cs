using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class AddCurrentProjectToEmployee : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "CurrentProjectId",
                table: "Employees",
                type: "uuid",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 36, 52, 349, DateTimeKind.Local).AddTicks(5584));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 36, 52, 349, DateTimeKind.Local).AddTicks(5597));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 36, 52, 349, DateTimeKind.Local).AddTicks(5599));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 36, 52, 349, DateTimeKind.Local).AddTicks(5602));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 36, 52, 349, DateTimeKind.Local).AddTicks(5604));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 36, 52, 349, DateTimeKind.Local).AddTicks(5614));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CurrentProjectId",
                table: "Employees");

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 0, 34, 220, DateTimeKind.Local).AddTicks(5207));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 0, 34, 220, DateTimeKind.Local).AddTicks(5219));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 0, 34, 220, DateTimeKind.Local).AddTicks(5221));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 0, 34, 220, DateTimeKind.Local).AddTicks(5223));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 0, 34, 220, DateTimeKind.Local).AddTicks(5225));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 2, 16, 0, 34, 220, DateTimeKind.Local).AddTicks(5227));
        }
    }
}
