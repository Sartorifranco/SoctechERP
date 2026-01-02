using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class SeedWageScales : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.InsertData(
                table: "WageScales",
                columns: new[] { "Id", "BasicValue", "CategoryName", "IsActive", "Union", "ValidFrom", "ZonePercentage" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), 6500m, "Oficial Especializado", true, 0, new DateTime(2026, 1, 2, 11, 53, 58, 677, DateTimeKind.Local).AddTicks(9601), 0.0 },
                    { new Guid("22222222-2222-2222-2222-222222222222"), 5800m, "Oficial", true, 0, new DateTime(2026, 1, 2, 11, 53, 58, 677, DateTimeKind.Local).AddTicks(9614), 0.0 },
                    { new Guid("33333333-3333-3333-3333-333333333333"), 5200m, "Medio Oficial", true, 0, new DateTime(2026, 1, 2, 11, 53, 58, 677, DateTimeKind.Local).AddTicks(9616), 0.0 },
                    { new Guid("44444444-4444-4444-4444-444444444444"), 4900m, "Ayudante", true, 0, new DateTime(2026, 1, 2, 11, 53, 58, 677, DateTimeKind.Local).AddTicks(9618), 0.0 },
                    { new Guid("55555555-5555-5555-5555-555555555555"), 950000m, "Administrativo A", true, 1, new DateTime(2026, 1, 2, 11, 53, 58, 677, DateTimeKind.Local).AddTicks(9620), 0.0 },
                    { new Guid("66666666-6666-6666-6666-666666666666"), 1100000m, "Administrativo B", true, 1, new DateTime(2026, 1, 2, 11, 53, 58, 677, DateTimeKind.Local).AddTicks(9622), 0.0 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"));

            migrationBuilder.DeleteData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"));

            migrationBuilder.DeleteData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"));

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Employees",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "");
        }
    }
}
