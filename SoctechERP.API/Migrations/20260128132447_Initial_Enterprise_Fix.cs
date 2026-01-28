using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class Initial_Enterprise_Fix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("10000000-7777-7777-7777-777777777777"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("20000000-8888-8888-8888-888888888888"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("30000000-9999-9999-9999-999999999999"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("aaaaaaaa-1111-1111-1111-111111111111"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-2222-2222-2222-222222222222"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("cccccccc-3333-3333-3333-333333333333"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-4444-4444-4444-444444444444"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("eeeeeeee-5555-5555-5555-555555555555"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("ffffffff-6666-6666-6666-666666666666"));

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

            migrationBuilder.DropColumn(
                name: "Address",
                table: "Branches");

            migrationBuilder.DropColumn(
                name: "CompanyId",
                table: "Branches");

            migrationBuilder.DropColumn(
                name: "IsWarehouse",
                table: "Branches");

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Employees",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Branches",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(255)",
                oldMaxLength: 255);

            migrationBuilder.AddColumn<string>(
                name: "Location",
                table: "Branches",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.InsertData(
                table: "Branches",
                columns: new[] { "Id", "IsActive", "Location", "Name" },
                values: new object[] { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"), true, "Córdoba Capital", "Casa Central" });

            migrationBuilder.InsertData(
                table: "SystemModules",
                columns: new[] { "Id", "Code", "Name" },
                values: new object[,]
                {
                    { new Guid("21f40095-1a6c-408f-89d7-fefd431939b8"), "PROJECTS", "Proyectos" },
                    { new Guid("6ef2516e-51d1-4a73-b8d0-8caa511f8e01"), "STOCK_IN", "Stock" },
                    { new Guid("ffe7149f-4d29-413b-a489-d1cc5c2f6fe9"), "DASHBOARD", "Tablero" }
                });

            migrationBuilder.UpdateData(
                table: "Warehouses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-dddd-dddd-dddd-dddddddddddd"),
                columns: new[] { "BranchId", "Location" },
                values: new object[] { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"), "Nave Principal" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Branches",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("21f40095-1a6c-408f-89d7-fefd431939b8"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("6ef2516e-51d1-4a73-b8d0-8caa511f8e01"));

            migrationBuilder.DeleteData(
                table: "SystemModules",
                keyColumn: "Id",
                keyValue: new Guid("ffe7149f-4d29-413b-a489-d1cc5c2f6fe9"));

            migrationBuilder.DropColumn(
                name: "Location",
                table: "Branches");

            migrationBuilder.AlterColumn<string>(
                name: "Address",
                table: "Employees",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Branches",
                type: "character varying(255)",
                maxLength: 255,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "Address",
                table: "Branches",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "CompanyId",
                table: "Branches",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<bool>(
                name: "IsWarehouse",
                table: "Branches",
                type: "boolean",
                nullable: false,
                defaultValue: false);

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

            migrationBuilder.InsertData(
                table: "WageScales",
                columns: new[] { "Id", "BasicValue", "CategoryName", "IsActive", "Union", "ValidFrom", "ZonePercentage" },
                values: new object[,]
                {
                    { new Guid("11111111-1111-1111-1111-111111111111"), 6500m, "Oficial Especializado", true, "UOCRA", new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2897), 0.0 },
                    { new Guid("22222222-2222-2222-2222-222222222222"), 5800m, "Oficial", true, "UOCRA", new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2909), 0.0 },
                    { new Guid("33333333-3333-3333-3333-333333333333"), 5200m, "Medio Oficial", true, "UOCRA", new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2912), 0.0 },
                    { new Guid("44444444-4444-4444-4444-444444444444"), 4900m, "Ayudante", true, "UOCRA", new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2914), 0.0 },
                    { new Guid("55555555-5555-5555-5555-555555555555"), 950000m, "Administrativo A", true, "UECARA", new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2916), 0.0 },
                    { new Guid("66666666-6666-6666-6666-666666666666"), 1100000m, "Administrativo B", true, "UECARA", new DateTime(2026, 1, 28, 10, 1, 50, 385, DateTimeKind.Local).AddTicks(2918), 0.0 }
                });

            migrationBuilder.UpdateData(
                table: "Warehouses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-dddd-dddd-dddd-dddddddddddd"),
                columns: new[] { "BranchId", "Location" },
                values: new object[] { new Guid("00000000-0000-0000-0000-000000000000"), "Casa Central" });
        }
    }
}
