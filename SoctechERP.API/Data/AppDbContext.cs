using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums; 

namespace SoctechERP.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        // --- 1. CORE & INVENTARIO ---
        public DbSet<Company> Companies { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Branch> Branches { get; set; }
        public DbSet<StockMovement> StockMovements { get; set; } // El Historial (Kardex)
        
        // --- 2. GESTIÓN DE OBRAS ---
        public DbSet<Project> Projects { get; set; }
        public DbSet<ProjectPhase> ProjectPhases { get; set; }
        public DbSet<ProjectCertificate> ProjectCertificates { get; set; }

        // --- 3. COMPRAS & PROVEEDORES ---
        public DbSet<Provider> Providers { get; set; }
        public DbSet<PurchaseOrder> PurchaseOrders { get; set; }
        public DbSet<PurchaseOrderItem> PurchaseOrderItems { get; set; }
        public DbSet<Dispatch> Dispatches { get; set; }
        public DbSet<DispatchItem> DispatchItems { get; set; }

        // [NUEVO] Recepción de Mercadería (Goods Receipt)
        public DbSet<GoodsReceipt> GoodsReceipts { get; set; }
        public DbSet<GoodsReceiptItem> GoodsReceiptItems { get; set; }

        // --- 4. SUBCONTRATISTAS ---
        public DbSet<Contractor> Contractors { get; set; }
        public DbSet<ContractorJob> ContractorJobs { get; set; }

        // --- 5. RECURSOS HUMANOS (RRHH) ---
        public DbSet<Employee> Employees { get; set; }
        public DbSet<WorkLog> WorkLogs { get; set; }
        public DbSet<WageScale> WageScales { get; set; }

        // --- 6. ADMINISTRACIÓN (FACTURACIÓN) ---
        public DbSet<SupplierInvoice> SupplierInvoices { get; set; } 
        // [NUEVO] Detalle y Auditoría de Facturas (3-Way Match)
        public DbSet<SupplierInvoiceItem> SupplierInvoiceItems { get; set; }
        public DbSet<InvoiceException> InvoiceExceptions { get; set; }

        public DbSet<SalesInvoice> SalesInvoices { get; set; }       

        // --- 7. TESORERÍA ---
        public DbSet<Wallet> Wallets { get; set; }
        public DbSet<FinancialTransaction> FinancialTransactions { get; set; }
        
        // --- 8. SEGURIDAD ENTERPRISE ---
        public DbSet<User> Users { get; set; }
        public DbSet<SystemModule> SystemModules { get; set; }
        public DbSet<UserPermission> UserPermissions { get; set; }

        // --- 9. LOGÍSTICA & CONSUMO ---
        public DbSet<Warehouse> Warehouses { get; set; }
        public DbSet<ProductStock> ProductStocks { get; set; }
        
        // [NUEVO] Vales de Salida (Consumo ABC)
        public DbSet<StockWithdrawal> StockWithdrawals { get; set; }
        public DbSet<StockWithdrawalItem> StockWithdrawalItems { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- ÍNDICES ---
            modelBuilder.Entity<Company>().HasIndex(c => c.Cuit).IsUnique();
            modelBuilder.Entity<Product>().HasIndex(p => p.Sku).IsUnique();

            // --- RELACIONES ROBUSTAS (Evitar borrados en cascada accidentales) ---
            modelBuilder.Entity<StockMovement>()
                .HasOne(m => m.SourceWarehouse)
                .WithMany()
                .HasForeignKey(m => m.SourceWarehouseId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<StockMovement>()
                .HasOne(m => m.TargetWarehouse)
                .WithMany()
                .HasForeignKey(m => m.TargetWarehouseId)
                .OnDelete(DeleteBehavior.Restrict);

            // --- PRECISIONES DECIMALES (CRÍTICO PARA ERP FINANCIERO) ---
            
            // Productos y Stock
            modelBuilder.Entity<Product>().Property(p => p.CostPrice).HasPrecision(18, 2);
            modelBuilder.Entity<Product>().Property(p => p.UnitPrice).HasPrecision(18, 2);
            modelBuilder.Entity<Product>().Property(p => p.Stock).HasPrecision(18, 4); 
            modelBuilder.Entity<StockMovement>().Property(s => s.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.UnitCost).HasPrecision(18, 2);
            
            // Fases de Proyecto
            modelBuilder.Entity<ProjectPhase>().Property(p => p.Budget).HasPrecision(18, 2);
            modelBuilder.Entity<ProjectPhase>().Property(p => p.BudgetedMaterialCost).HasPrecision(18, 2);
            modelBuilder.Entity<ProjectPhase>().Property(p => p.ActualMaterialCost).HasPrecision(18, 2);
            modelBuilder.Entity<ProjectPhase>().Property(p => p.ActualLaborCost).HasPrecision(18, 2);

            // Recepción (Goods Receipt)
            modelBuilder.Entity<GoodsReceiptItem>().Property(i => i.QuantityOrdered).HasPrecision(18, 4);
            modelBuilder.Entity<GoodsReceiptItem>().Property(i => i.QuantityReceived).HasPrecision(18, 4);
            modelBuilder.Entity<GoodsReceiptItem>().Property(i => i.QuantityRejected).HasPrecision(18, 4);

            // Salidas / Vales (Withdrawals)
            modelBuilder.Entity<StockWithdrawalItem>().Property(i => i.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockWithdrawalItem>().Property(i => i.UnitCostSnapshot).HasPrecision(18, 2);
            modelBuilder.Entity<StockWithdrawalItem>().Property(i => i.TotalCost).HasPrecision(18, 2);

            // RRHH
            modelBuilder.Entity<Employee>().Property(e => e.Address).HasDefaultValue(""); 
            modelBuilder.Entity<Employee>().Property(e => e.NegotiatedSalary).HasPrecision(18, 2);
            modelBuilder.Entity<WageScale>().Property(w => w.BasicValue).HasPrecision(18, 2);
            modelBuilder.Entity<WorkLog>().Property(w => w.HourlyRateSnapshot).HasPrecision(18, 2);
            modelBuilder.Entity<WorkLog>().Property(w => w.TotalCost).HasPrecision(18, 2);
            modelBuilder.Entity<ContractorJob>().Property(c => c.AgreedAmount).HasPrecision(18, 2);
            
            // Facturación Proveedores (Input)
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.NetAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.VatAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.OtherTaxes).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.TotalAmount).HasPrecision(18, 2);
            
            // Detalle Factura (Validación)
            modelBuilder.Entity<SupplierInvoiceItem>().Property(i => i.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<SupplierInvoiceItem>().Property(i => i.UnitPrice).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoiceItem>().Property(i => i.TotalLineAmount).HasPrecision(18, 2);

            // Auditoría (Excepciones)
            modelBuilder.Entity<InvoiceException>().Property(i => i.ExpectedValue).HasPrecision(18, 2);
            modelBuilder.Entity<InvoiceException>().Property(i => i.ActualValue).HasPrecision(18, 2);
            modelBuilder.Entity<InvoiceException>().Property(i => i.VarianceTotalAmount).HasPrecision(18, 2);

            // Facturación Ventas (Output)
            modelBuilder.Entity<SalesInvoice>().Property(i => i.NetAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.VatAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.GrossTotal).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.RetainageAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.CollectibleAmount).HasPrecision(18, 2);
            
            // Tesorería
            modelBuilder.Entity<Wallet>().Property(w => w.Balance).HasPrecision(18, 2);
            modelBuilder.Entity<FinancialTransaction>().Property(t => t.Amount).HasPrecision(18, 2);
            
            // Logística Multi-Depósito
            modelBuilder.Entity<ProductStock>()
                .HasIndex(ps => new { ps.ProductId, ps.WarehouseId }) 
                .IsUnique();
            modelBuilder.Entity<ProductStock>().Property(p => p.Quantity).HasPrecision(18, 4);


            // --- SEED DATA (RRHH) ---
            modelBuilder.Entity<WageScale>().HasData(
                new WageScale { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Union = UnionType.UOCRA, CategoryName = "Oficial Especializado", BasicValue = 6500, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Union = UnionType.UOCRA, CategoryName = "Oficial", BasicValue = 5800, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Union = UnionType.UOCRA, CategoryName = "Medio Oficial", BasicValue = 5200, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), Union = UnionType.UOCRA, CategoryName = "Ayudante", BasicValue = 4900, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("55555555-5555-5555-5555-555555555555"), Union = UnionType.UECARA, CategoryName = "Administrativo A", BasicValue = 950000, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("66666666-6666-6666-6666-666666666666"), Union = UnionType.UECARA, CategoryName = "Administrativo B", BasicValue = 1100000, IsActive = true, ValidFrom = DateTime.Now }
            );

            // --- SEED DATA (Módulos) ---
            modelBuilder.Entity<SystemModule>().HasData(
                new SystemModule { Id = Guid.Parse("aaaaaaaa-1111-1111-1111-111111111111"), Name = "Tablero de Control", Code = "DASHBOARD" },
                new SystemModule { Id = Guid.Parse("bbbbbbbb-2222-2222-2222-222222222222"), Name = "Entrada Mercadería (Stock)", Code = "STOCK_IN" },
                new SystemModule { Id = Guid.Parse("cccccccc-3333-3333-3333-333333333333"), Name = "Salida / Consumo (Stock)", Code = "STOCK_OUT" },
                new SystemModule { Id = Guid.Parse("dddddddd-4444-4444-4444-444444444444"), Name = "Órdenes de Compra", Code = "PURCHASE_ORDERS" },
                new SystemModule { Id = Guid.Parse("eeeeeeee-5555-5555-5555-555555555555"), Name = "Tesorería (Caja)", Code = "TREASURY" },
                new SystemModule { Id = Guid.Parse("ffffffff-6666-6666-6666-666666666666"), Name = "Ventas y Facturación", Code = "SALES" },
                new SystemModule { Id = Guid.Parse("10000000-7777-7777-7777-777777777777"), Name = "Obras y Proyectos", Code = "PROJECTS" },
                new SystemModule { Id = Guid.Parse("20000000-8888-8888-8888-888888888888"), Name = "RRHH y Personal", Code = "HR" },
                new SystemModule { Id = Guid.Parse("30000000-9999-9999-9999-999999999999"), Name = "Gestión de Usuarios", Code = "ADMIN_USERS" }
            );

            // --- SEED DATA (Depósito Central) ---
            modelBuilder.Entity<Warehouse>().HasData(
                new Warehouse 
                { 
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"), 
                    Name = "Depósito Central", 
                    Location = "Casa Central", 
                    IsMain = true, 
                    IsActive = true,
                    // BranchId: OJO -> Asegurate de actualizar esto con un ID real de Branch cuando crees la tabla de Warehouses.
                }
            );
        }
    }
}