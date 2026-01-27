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
        
        // --- 4. SUBCONTRATISTAS ---
        public DbSet<Contractor> Contractors { get; set; }
        public DbSet<ContractorJob> ContractorJobs { get; set; }

        // --- 5. RECURSOS HUMANOS (RRHH) ---
        public DbSet<Employee> Employees { get; set; }
        public DbSet<WorkLog> WorkLogs { get; set; }
        public DbSet<WageScale> WageScales { get; set; }

        // --- 6. ADMINISTRACIÓN (FACTURACIÓN) ---
        public DbSet<SupplierInvoice> SupplierInvoices { get; set; } // Compras (3-Way Match)
        public DbSet<SalesInvoice> SalesInvoices { get; set; }       // Ventas (Certificados)

        // --- 7. TESORERÍA ---
        public DbSet<Wallet> Wallets { get; set; }
        public DbSet<FinancialTransaction> FinancialTransactions { get; set; }
        
        // --- 8. SEGURIDAD ENTERPRISE ---
        public DbSet<User> Users { get; set; }
        public DbSet<SystemModule> SystemModules { get; set; }
        public DbSet<UserPermission> UserPermissions { get; set; }

        // --- 9. LOGÍSTICA MULTI-DEPÓSITO (NUEVO) ---
        public DbSet<Warehouse> Warehouses { get; set; }
        public DbSet<ProductStock> ProductStocks { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- ÍNDICES ---
            modelBuilder.Entity<Company>().HasIndex(c => c.Cuit).IsUnique();
            modelBuilder.Entity<Product>().HasIndex(p => p.Sku).IsUnique();

            // --- PRECISIONES DECIMALES ---
            modelBuilder.Entity<Product>().Property(p => p.CostPrice).HasPrecision(18, 2);
            modelBuilder.Entity<StockMovement>().Property(s => s.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.UnitCost).HasPrecision(18, 2);
            modelBuilder.Entity<Employee>().Property(e => e.Address).HasDefaultValue(""); 
            modelBuilder.Entity<Employee>().Property(e => e.NegotiatedSalary).HasPrecision(18, 2);
            modelBuilder.Entity<WageScale>().Property(w => w.BasicValue).HasPrecision(18, 2);
            modelBuilder.Entity<WorkLog>().Property(w => w.HourlyRateSnapshot).HasPrecision(18, 2);
            modelBuilder.Entity<WorkLog>().Property(w => w.TotalCost).HasPrecision(18, 2);
            modelBuilder.Entity<ContractorJob>().Property(c => c.AgreedAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.NetAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.VatAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.OtherTaxes).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.TotalAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.NetAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.VatAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.GrossTotal).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.RetainageAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.CollectibleAmount).HasPrecision(18, 2);
            modelBuilder.Entity<Wallet>().Property(w => w.Balance).HasPrecision(18, 2);
            modelBuilder.Entity<FinancialTransaction>().Property(t => t.Amount).HasPrecision(18, 2);
            
            // --- NUEVA CONFIG DE LOGÍSTICA ---
            modelBuilder.Entity<ProductStock>()
                .HasIndex(ps => new { ps.ProductId, ps.WarehouseId }) // Un producto solo puede tener 1 registro por depósito
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

            // --- SEED DATA (Depósito Central) - NUEVO ---
            modelBuilder.Entity<Warehouse>().HasData(
                new Warehouse 
                { 
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"), 
                    Name = "Depósito Central", 
                    Location = "Casa Central", 
                    IsMain = true, 
                    IsActive = true 
                }
            );
        }
    }
}