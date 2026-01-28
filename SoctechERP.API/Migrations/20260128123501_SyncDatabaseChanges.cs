using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SoctechERP.API.Migrations
{
    /// <inheritdoc />
    public partial class SyncDatabaseChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_StockMovements_Warehouses_SourceWarehouseId",
                table: "StockMovements");

            migrationBuilder.DropForeignKey(
                name: "FK_StockMovements_Warehouses_TargetWarehouseId",
                table: "StockMovements");

            migrationBuilder.AddColumn<Guid>(
                name: "BranchId",
                table: "Warehouses",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AlterColumn<string>(
                name: "Union",
                table: "WageScales",
                type: "text",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<string>(
                name: "InvoiceType",
                table: "SupplierInvoices",
                type: "character varying(5)",
                maxLength: 5,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "InvoiceNumber",
                table: "SupplierInvoices",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "SupplierInvoices",
                type: "timestamp without time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<Guid>(
                name: "CreatedByUserId",
                table: "SupplierInvoices",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<DateTime>(
                name: "ReceptionDate",
                table: "SupplierInvoices",
                type: "timestamp without time zone",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "MovementType",
                table: "StockMovements",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AddColumn<Guid>(
                name: "RelatedGoodsReceiptId",
                table: "StockMovements",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ProjectId",
                table: "PurchaseOrders",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Projects",
                type: "timestamp without time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<decimal>(
                name: "Budget",
                table: "ProjectPhases",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                oldClrType: typeof(double),
                oldType: "double precision");

            migrationBuilder.AddColumn<decimal>(
                name: "ActualLaborCost",
                table: "ProjectPhases",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "ActualMaterialCost",
                table: "ProjectPhases",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "BudgetedMaterialCost",
                table: "ProjectPhases",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "ProjectPhases",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "RequiresConsumptionControl",
                table: "Products",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "GoodsReceipts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    PurchaseOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProviderId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProviderName = table.Column<string>(type: "text", nullable: false),
                    RemitoNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ReceptionDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    TargetWarehouseId = table.Column<Guid>(type: "uuid", nullable: false),
                    TargetBranchId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReceivedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReceivedLatitude = table.Column<double>(type: "double precision", nullable: true),
                    ReceivedLongitude = table.Column<double>(type: "double precision", nullable: true),
                    DigitalSignatureUrl = table.Column<string>(type: "text", nullable: true),
                    EvidencePhotoUrl = table.Column<string>(type: "text", nullable: true),
                    Comments = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GoodsReceipts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "InvoiceExceptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SupplierInvoiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    ItemName = table.Column<string>(type: "text", nullable: false),
                    ExpectedValue = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    ActualValue = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    VarianceTotalAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsResolved = table.Column<bool>(type: "boolean", nullable: false),
                    ResolvedAt = table.Column<DateTime>(type: "timestamp without time zone", nullable: true),
                    ResolvedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ManagerComment = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_InvoiceExceptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_InvoiceExceptions_SupplierInvoices_SupplierInvoiceId",
                        column: x => x.SupplierInvoiceId,
                        principalTable: "SupplierInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StockWithdrawals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProjectPhaseId = table.Column<Guid>(type: "uuid", nullable: false),
                    WarehouseId = table.Column<Guid>(type: "uuid", nullable: false),
                    RequestedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ApprovedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    WithdrawalDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    WithdrawalNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    DigitalSignatureUrl = table.Column<string>(type: "text", nullable: true),
                    Latitude = table.Column<double>(type: "double precision", nullable: true),
                    Longitude = table.Column<double>(type: "double precision", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StockWithdrawals", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SupplierInvoiceItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SupplierInvoiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    Description = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    UnitPrice = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalLineAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SupplierInvoiceItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SupplierInvoiceItems_SupplierInvoices_SupplierInvoiceId",
                        column: x => x.SupplierInvoiceId,
                        principalTable: "SupplierInvoices",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "GoodsReceiptItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    GoodsReceiptId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductName = table.Column<string>(type: "text", nullable: false),
                    QuantityOrdered = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 4, nullable: false),
                    QuantityReceived = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 4, nullable: false),
                    QuantityRejected = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 4, nullable: false),
                    Condition = table.Column<int>(type: "integer", nullable: false),
                    RejectionReason = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GoodsReceiptItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_GoodsReceiptItems_GoodsReceipts_GoodsReceiptId",
                        column: x => x.GoodsReceiptId,
                        principalTable: "GoodsReceipts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "StockWithdrawalItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    StockWithdrawalId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductName = table.Column<string>(type: "text", nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    UnitCostSnapshot = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    TotalCost = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StockWithdrawalItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StockWithdrawalItems_StockWithdrawals_StockWithdrawalId",
                        column: x => x.StockWithdrawalId,
                        principalTable: "StockWithdrawals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { "UOCRA", new DateTime(2026, 1, 28, 9, 35, 1, 245, DateTimeKind.Local).AddTicks(1595) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { "UOCRA", new DateTime(2026, 1, 28, 9, 35, 1, 245, DateTimeKind.Local).AddTicks(1605) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { "UOCRA", new DateTime(2026, 1, 28, 9, 35, 1, 245, DateTimeKind.Local).AddTicks(1607) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { "UOCRA", new DateTime(2026, 1, 28, 9, 35, 1, 245, DateTimeKind.Local).AddTicks(1618) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { "UECARA", new DateTime(2026, 1, 28, 9, 35, 1, 245, DateTimeKind.Local).AddTicks(1620) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { "UECARA", new DateTime(2026, 1, 28, 9, 35, 1, 245, DateTimeKind.Local).AddTicks(1622) });

            migrationBuilder.UpdateData(
                table: "Warehouses",
                keyColumn: "Id",
                keyValue: new Guid("dddddddd-dddd-dddd-dddd-dddddddddddd"),
                column: "BranchId",
                value: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_GoodsReceiptItems_GoodsReceiptId",
                table: "GoodsReceiptItems",
                column: "GoodsReceiptId");

            migrationBuilder.CreateIndex(
                name: "IX_InvoiceExceptions_SupplierInvoiceId",
                table: "InvoiceExceptions",
                column: "SupplierInvoiceId");

            migrationBuilder.CreateIndex(
                name: "IX_StockWithdrawalItems_StockWithdrawalId",
                table: "StockWithdrawalItems",
                column: "StockWithdrawalId");

            migrationBuilder.CreateIndex(
                name: "IX_SupplierInvoiceItems_SupplierInvoiceId",
                table: "SupplierInvoiceItems",
                column: "SupplierInvoiceId");

            migrationBuilder.AddForeignKey(
                name: "FK_StockMovements_Warehouses_SourceWarehouseId",
                table: "StockMovements",
                column: "SourceWarehouseId",
                principalTable: "Warehouses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_StockMovements_Warehouses_TargetWarehouseId",
                table: "StockMovements",
                column: "TargetWarehouseId",
                principalTable: "Warehouses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_StockMovements_Warehouses_SourceWarehouseId",
                table: "StockMovements");

            migrationBuilder.DropForeignKey(
                name: "FK_StockMovements_Warehouses_TargetWarehouseId",
                table: "StockMovements");

            migrationBuilder.DropTable(
                name: "GoodsReceiptItems");

            migrationBuilder.DropTable(
                name: "InvoiceExceptions");

            migrationBuilder.DropTable(
                name: "StockWithdrawalItems");

            migrationBuilder.DropTable(
                name: "SupplierInvoiceItems");

            migrationBuilder.DropTable(
                name: "GoodsReceipts");

            migrationBuilder.DropTable(
                name: "StockWithdrawals");

            migrationBuilder.DropColumn(
                name: "BranchId",
                table: "Warehouses");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "SupplierInvoices");

            migrationBuilder.DropColumn(
                name: "CreatedByUserId",
                table: "SupplierInvoices");

            migrationBuilder.DropColumn(
                name: "ReceptionDate",
                table: "SupplierInvoices");

            migrationBuilder.DropColumn(
                name: "RelatedGoodsReceiptId",
                table: "StockMovements");

            migrationBuilder.DropColumn(
                name: "ProjectId",
                table: "PurchaseOrders");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Projects");

            migrationBuilder.DropColumn(
                name: "ActualLaborCost",
                table: "ProjectPhases");

            migrationBuilder.DropColumn(
                name: "ActualMaterialCost",
                table: "ProjectPhases");

            migrationBuilder.DropColumn(
                name: "BudgetedMaterialCost",
                table: "ProjectPhases");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "ProjectPhases");

            migrationBuilder.DropColumn(
                name: "RequiresConsumptionControl",
                table: "Products");

            migrationBuilder.AlterColumn<int>(
                name: "Union",
                table: "WageScales",
                type: "integer",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "InvoiceType",
                table: "SupplierInvoices",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(5)",
                oldMaxLength: 5);

            migrationBuilder.AlterColumn<string>(
                name: "InvoiceNumber",
                table: "SupplierInvoices",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "MovementType",
                table: "StockMovements",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<double>(
                name: "Budget",
                table: "ProjectPhases",
                type: "double precision",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "numeric(18,2)",
                oldPrecision: 18,
                oldScale: 2);

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("11111111-1111-1111-1111-111111111111"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { 0, new DateTime(2026, 1, 26, 14, 7, 27, 878, DateTimeKind.Local).AddTicks(5323) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("22222222-2222-2222-2222-222222222222"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { 0, new DateTime(2026, 1, 26, 14, 7, 27, 878, DateTimeKind.Local).AddTicks(5335) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("33333333-3333-3333-3333-333333333333"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { 0, new DateTime(2026, 1, 26, 14, 7, 27, 878, DateTimeKind.Local).AddTicks(5337) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("44444444-4444-4444-4444-444444444444"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { 0, new DateTime(2026, 1, 26, 14, 7, 27, 878, DateTimeKind.Local).AddTicks(5347) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("55555555-5555-5555-5555-555555555555"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { 1, new DateTime(2026, 1, 26, 14, 7, 27, 878, DateTimeKind.Local).AddTicks(5349) });

            migrationBuilder.UpdateData(
                table: "WageScales",
                keyColumn: "Id",
                keyValue: new Guid("66666666-6666-6666-6666-666666666666"),
                columns: new[] { "Union", "ValidFrom" },
                values: new object[] { 1, new DateTime(2026, 1, 26, 14, 7, 27, 878, DateTimeKind.Local).AddTicks(5351) });

            migrationBuilder.AddForeignKey(
                name: "FK_StockMovements_Warehouses_SourceWarehouseId",
                table: "StockMovements",
                column: "SourceWarehouseId",
                principalTable: "Warehouses",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_StockMovements_Warehouses_TargetWarehouseId",
                table: "StockMovements",
                column: "TargetWarehouseId",
                principalTable: "Warehouses",
                principalColumn: "Id");
        }
    }
}
