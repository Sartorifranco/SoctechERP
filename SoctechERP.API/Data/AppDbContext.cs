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
        public DbSet<StockMovement> StockMovements { get; set; } 
        
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
        public DbSet<StockWithdrawal> StockWithdrawals { get; set; }
        public DbSet<StockWithdrawalItem> StockWithdrawalItems { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // CONFIGURACIÓN DE ENUMS A STRING (CRÍTICO)
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.Status).HasConversion<string>();
            modelBuilder.Entity<StockMovement>().Property(m => m.MovementType).HasConversion<string>();
            modelBuilder.Entity<InvoiceException>().Property(e => e.Type).HasConversion<string>();
            modelBuilder.Entity<WageScale>().Property(w => w.Union).HasConversion<string>();

            // ÍNDICES Y RELACIONES
            modelBuilder.Entity<Company>().HasIndex(c => c.Cuit).IsUnique();
            modelBuilder.Entity<Product>().HasIndex(p => p.Sku).IsUnique();

            modelBuilder.Entity<StockMovement>()
                .HasOne(m => m.SourceWarehouse).WithMany().HasForeignKey(m => m.SourceWarehouseId).OnDelete(DeleteBehavior.Restrict);
            modelBuilder.Entity<StockMovement>()
                .HasOne(m => m.TargetWarehouse).WithMany().HasForeignKey(m => m.TargetWarehouseId).OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ProductStock>()
                .HasIndex(ps => new { ps.ProductId, ps.WarehouseId }).IsUnique();

            // PRECISIONES (Evitar errores de redondeo)
            var decimalProps = new[] { 
                "CostPrice", "UnitPrice", "Stock", "Quantity", "Budget", 
                "NetAmount", "VatAmount", "TotalAmount", "Balance", "Amount" 
            };
            // Nota: Aplicamos precisión genérica a los campos clave para simplificar el código
            modelBuilder.Entity<Product>().Property(p => p.CostPrice).HasPrecision(18, 2);
            modelBuilder.Entity<Product>().Property(p => p.Stock).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.UnitCost).HasPrecision(18, 2);
            modelBuilder.Entity<ProductStock>().Property(p => p.Quantity).HasPrecision(18, 4);

            // --- SEED DATA (DATOS INICIALES CORREGIDOS) ---
            
            // 1. Crear Sucursal Principal (NECESARIO para el Depósito)
            var mainBranchId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
            modelBuilder.Entity<Branch>().HasData(
                new Branch { Id = mainBranchId, Name = "Casa Central", Location = "Córdoba Capital", IsActive = true }
            );

            // 2. Crear Depósito Central vinculado a la Sucursal
            modelBuilder.Entity<Warehouse>().HasData(
                new Warehouse 
                { 
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"), 
                    Name = "Depósito Central", 
                    Location = "Nave Principal", 
                    BranchId = mainBranchId, // <--- AHORA SÍ TIENE PADRE
                    IsMain = true, 
                    IsActive = true
                }
            );

            // 3. Módulos del Sistema
            modelBuilder.Entity<SystemModule>().HasData(
                new SystemModule { Id = Guid.NewGuid(), Name = "Tablero", Code = "DASHBOARD" },
                new SystemModule { Id = Guid.NewGuid(), Name = "Stock", Code = "STOCK_IN" },
                new SystemModule { Id = Guid.NewGuid(), Name = "Proyectos", Code = "PROJECTS" }
            );
        }
    }
}