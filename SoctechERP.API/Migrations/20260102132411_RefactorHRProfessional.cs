using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class RefactorHRProfessional : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HourlyRate",
                table: "Employees");

            migrationBuilder.RenameColumn(
                name: "HourlyCostSnapshot",
                table: "WorkLogs",
                newName: "RegisteredRateSnapshot");

            migrationBuilder.RenameColumn(
                name: "Role",
                table: "Employees",
                newName: "LastName");

            migrationBuilder.RenameColumn(
                name: "FullName",
                table: "Employees",
                newName: "FirstName");

            migrationBuilder.RenameColumn(
                name: "DNI",
                table: "Employees",
                newName: "CategoryName");

            migrationBuilder.AddColumn<string>(
                name: "Address",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "BirthDate",
                table: "Employees",
                type: "timestamp without time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "CUIL",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "EntryDate",
                table: "Employees",
                type: "timestamp without time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "Frequency",
                table: "Employees",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Union",
                table: "Employees",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<Guid>(
                name: "WageScaleId",
                table: "Employees",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateTable(
                name: "WageScales",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Union = table.Column<int>(type: "integer", nullable: false),
                    CategoryName = table.Column<string>(type: "text", nullable: false),
                    BasicValue = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    ZonePercentage = table.Column<double>(type: "double precision", nullable: false),
                    ValidFrom = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WageScales", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WorkLogs_EmployeeId",
                table: "WorkLogs",
                column: "EmployeeId");

            migrationBuilder.CreateIndex(
                name: "IX_Employees_WageScaleId",
                table: "Employees",
                column: "WageScaleId");

            migrationBuilder.AddForeignKey(
                name: "FK_Employees_WageScales_WageScaleId",
                table: "Employees",
                column: "WageScaleId",
                principalTable: "WageScales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_WorkLogs_Employees_EmployeeId",
                table: "WorkLogs",
                column: "EmployeeId",
                principalTable: "Employees",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Employees_WageScales_WageScaleId",
                table: "Employees");

            migrationBuilder.DropForeignKey(
                name: "FK_WorkLogs_Employees_EmployeeId",
                table: "WorkLogs");

            migrationBuilder.DropTable(
                name: "WageScales");

            migrationBuilder.DropIndex(
                name: "IX_WorkLogs_EmployeeId",
                table: "WorkLogs");

            migrationBuilder.DropIndex(
                name: "IX_Employees_WageScaleId",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Address",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "BirthDate",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "CUIL",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "EntryDate",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Frequency",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "Union",
                table: "Employees");

            migrationBuilder.DropColumn(
                name: "WageScaleId",
                table: "Employees");

            migrationBuilder.RenameColumn(
                name: "RegisteredRateSnapshot",
                table: "WorkLogs",
                newName: "HourlyCostSnapshot");

            migrationBuilder.RenameColumn(
                name: "LastName",
                table: "Employees",
                newName: "Role");

            migrationBuilder.RenameColumn(
                name: "FirstName",
                table: "Employees",
                newName: "FullName");

            migrationBuilder.RenameColumn(
                name: "CategoryName",
                table: "Employees",
                newName: "DNI");

            migrationBuilder.AddColumn<decimal>(
                name: "HourlyRate",
                table: "Employees",
                type: "numeric(18,2)",
                nullable: false,
                defaultValue: 0m);
        }
    }
}
