using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class AddEnterpriseSecurity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SystemModules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SystemModules", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "UserPermissions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ModuleId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserPermissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserPermissions_SystemModules_ModuleId",
                        column: x => x.ModuleId,
                        principalTable: "SystemModules",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserPermissions_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "SystemModules",
                columns: new[] { "Id", "Code", "Name" },
                values: new object[,]
                {
                    { new Guid("10000000-7777-7777-7777-777777777777"), "PROJECTS", "Obras y Proyectos" },
                    { new Guid("20000000-8888-8888-8888-888888888888"), "HR", "RRHH y Personal" },
                    { new Guid("30000000-9999-9999-9999-999999999999"), "ADMIN_USERS", "Gestión de Usuarios" },
                    { new Guid("aaaaaaaa-1111-1111-1111-111111111111"), "DASHBOARD", "Tablero de Control" },
                    { new Guid("bbbbbbbb-2222-2222-2222-222222222222"), "STOCK_IN", "Entrada Mercadería (Stock)" },
                    { new Guid("cccccccc-3333-3333-3333-333333333333"), "STOCK_OUT", "Salida / Consumo (Stock)" },
                    { new Guid("dddddddd-4444-4444-4444-444444444444"), "PURCHASE_ORDERS", "Órdenes de Compra" },
                    { new Guid("eeeeeeee-5555-5555-5555-555555555555"), "TREASURY", "Tesorería (Caja)" },
                    { new Guid("ffffffff-6666-6666-6666-666666666666"), "SALES", "Ventas y Facturación" }
                });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 26, 12, 27, 32, 792, DateTimeKind.Local).AddTicks(2283));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 26, 12, 27, 32, 792, DateTimeKind.Local).AddTicks(2294));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 26, 12, 27, 32, 792, DateTimeKind.Local).AddTicks(2296));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 26, 12, 27, 32, 792, DateTimeKind.Local).AddTicks(2298));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 26, 12, 27, 32, 792, DateTimeKind.Local).AddTicks(2300));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 26, 12, 27, 32, 792, DateTimeKind.Local).AddTicks(2310));

            migrationBuilder.CreateIndex(
                name: "IX_UserPermissions_ModuleId",
                table: "UserPermissions",
                column: "ModuleId");

            migrationBuilder.CreateIndex(
                name: "IX_UserPermissions_UserId",
                table: "UserPermissions",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "UserPermissions");

            migrationBuilder.DropTable(
                name: "SystemModules");

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 15, 16, 27, 33, 574, DateTimeKind.Local).AddTicks(7259));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 15, 16, 27, 33, 574, DateTimeKind.Local).AddTicks(7271));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 15, 16, 27, 33, 574, DateTimeKind.Local).AddTicks(7274));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 15, 16, 27, 33, 574, DateTimeKind.Local).AddTicks(7276));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 15, 16, 27, 33, 574, DateTimeKind.Local).AddTicks(7278));

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                column: "ValidFrom",
                value: new DateTime(2026, 1, 15, 16, 27, 33, 574, DateTimeKind.Local).AddTicks(7280));
        }
    }
}
