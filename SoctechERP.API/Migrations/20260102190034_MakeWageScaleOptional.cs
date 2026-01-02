using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class MakeWageScaleOptional : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Employees_WageScales_WageScaleId",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "CategoryName",
                table: "Employees");

            migrationBuilder.AlterColumn<Guid>(
                name: "WageScaleId",
                table: "Employees",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

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

            migrationBuilder.AddForeignKey(
                name: "FK_Employees_WageScales_WageScaleId",
                table: "Employees",
                column: "WageScaleId",
                principalTable: "WageScales",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Employees_WageScales_WageScaleId",
                table: "Employees");

            migrationBuilder.AlterColumn<Guid>(
                name: "WageScaleId",
                table: "Employees",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CategoryName",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

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

            migrationBuilder.AddForeignKey(
                name: "FK_Employees_WageScales_WageScaleId",
                table: "Employees",
                column: "WageScaleId",
                principalTable: "WageScales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
