using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkLogFinancials : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Notes",
                table: "WorkLogs");

            migrationBuilder.DropColumn(
                name: "ProjectPhaseId",
                table: "WorkLogs");

            migrationBuilder.DropColumn(
                name: "BirthDate",
                table: "Employees");

            migrationBuilder.RenameColumn(
                name: "RegisteredRateSnapshot",
                table: "WorkLogs",
                newName: "TotalCost");

            migrationBuilder.RenameColumn(
                name: "CUIL",
                table: "Employees",
                newName: "Cuil");

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "WorkLogs",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<decimal>(
                name: "HourlyRateSnapshot",
                table: "WorkLogs",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AlterColumn<double>(
                name: "NegotiatedSalary",
                table: "Employees",
                type: "double precision",
                precision: 18,
                scale: 2,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(18,2)",
                oldPrecision: 18,
                oldScale: 2,
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Dni",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Phone",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 12, 15, 40, 5, 477, DateTimeKind.Local).AddTicks(4063));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 12, 15, 40, 5, 477, DateTimeKind.Local).AddTicks(4081));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 12, 15, 40, 5, 477, DateTimeKind.Local).AddTicks(4083));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 12, 15, 40, 5, 477, DateTimeKind.Local).AddTicks(4085));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 12, 15, 40, 5, 477, DateTimeKind.Local).AddTicks(4087));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 12, 15, 40, 5, 477, DateTimeKind.Local).AddTicks(4095));

            migrationBuilder.CreateIndex(
                name: "IX_WorkLogs_ProjectId",
                table: "WorkLogs",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_Employees_CurrentProjectId",
                table: "Employees",
                column: "CurrentProjectId");

            migrationBuilder.AddForeignKey(
                name: "FK_Employees_Projects_CurrentProjectId",
                table: "Employees",
                column: "CurrentProjectId",
                principalTable: "Projects",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_WorkLogs_Projects_ProjectId",
                table: "WorkLogs",
                column: "ProjectId",
                principalTable: "Projects",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Employees_Projects_CurrentProjectId",
                table: "Employees");

            migrationBuilder.DropForeignKey(
                name: "FK_WorkLogs_Projects_ProjectId",
                table: "WorkLogs");

            migrationBuilder.DropIndex(
                name: "IX_WorkLogs_ProjectId",
                table: "WorkLogs");

            migrationBuilder.DropIndex(
                name: "IX_Employees_CurrentProjectId",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "WorkLogs");

            migrationBuilder.DropColumn(
                name: "HourlyRateSnapshot",
                table: "WorkLogs");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Dni",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Phone",
                table: "Employees");

            migrationBuilder.RenameColumn(
                name: "TotalCost",
                table: "WorkLogs",
                newName: "RegisteredRateSnapshot");

            migrationBuilder.RenameColumn(
                name: "Cuil",
                table: "Employees",
                newName: "CUIL");

            migrationBuilder.AddColumn<string>(
                name: "Notes",
                table: "WorkLogs",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ProjectPhaseId",
                table: "WorkLogs",
                type: "uuid",
                nullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "NegotiatedSalary",
                table: "Employees",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true,
                oldClrType: typeof(double),
                oldType: "double precision",
                oldPrecision: 18,
                oldScale: 2,
                oldNullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "BirthDate",
                table: "Employees",
                type: "timestamp without time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 6, 15, 56, 5, 244, DateTimeKind.Local).AddTicks(2156));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 6, 15, 56, 5, 244, DateTimeKind.Local).AddTicks(2170));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 6, 15, 56, 5, 244, DateTimeKind.Local).AddTicks(2172));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 6, 15, 56, 5, 244, DateTimeKind.Local).AddTicks(2174));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 6, 15, 56, 5, 244, DateTimeKind.Local).AddTicks(2176));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 6, 15, 56, 5, 244, DateTimeKind.Local).AddTicks(2178));
        }
    }
}
