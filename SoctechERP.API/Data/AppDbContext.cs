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

        // --- 7. TESORERÍA (NUEVO - CAJA Y BANCOS) ---
        public DbSet<Wallet> Wallets { get; set; }
        public DbSet<FinancialTransaction> FinancialTransactions { get; set; }
        public DbSet<User> Users { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- ÍNDICES ---
            modelBuilder.Entity<Company>().HasIndex(c => c.Cuit).IsUnique();
            modelBuilder.Entity<Product>().HasIndex(p => p.Sku).IsUnique();

            // --- PRECISIONES DECIMALES (DINERO) ---
            // Importante para que SQL Server no trunque los centavos
            modelBuilder.Entity<Product>().Property(p => p.CostPrice).HasPrecision(18, 2);
            
            modelBuilder.Entity<StockMovement>().Property(s => s.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.UnitCost).HasPrecision(18, 2);

            modelBuilder.Entity<Employee>().Property(e => e.Address).HasDefaultValue(""); 
            modelBuilder.Entity<Employee>().Property(e => e.NegotiatedSalary).HasPrecision(18, 2);

            modelBuilder.Entity<WageScale>().Property(w => w.BasicValue).HasPrecision(18, 2);

            // --- CORRECCIÓN AQUÍ ---
            // Antes decía RegisteredRateSnapshot, ahora es HourlyRateSnapshot
            modelBuilder.Entity<WorkLog>().Property(w => w.HourlyRateSnapshot).HasPrecision(18, 2);
            // Agregamos también TotalCost que es nuevo
            modelBuilder.Entity<WorkLog>().Property(w => w.TotalCost).HasPrecision(18, 2);
            // -----------------------

            modelBuilder.Entity<ContractorJob>().Property(c => c.AgreedAmount).HasPrecision(18, 2);

            // Precisiones Facturación Compras
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.NetAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.VatAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.OtherTaxes).HasPrecision(18, 2);
            modelBuilder.Entity<SupplierInvoice>().Property(i => i.TotalAmount).HasPrecision(18, 2);

            // Precisiones Facturación Ventas
            modelBuilder.Entity<SalesInvoice>().Property(i => i.NetAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.VatAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.GrossTotal).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.RetainageAmount).HasPrecision(18, 2);
            modelBuilder.Entity<SalesInvoice>().Property(i => i.CollectibleAmount).HasPrecision(18, 2);
            
            // Precisiones Tesorería (NUEVO)
            modelBuilder.Entity<Wallet>().Property(w => w.Balance).HasPrecision(18, 2);
            modelBuilder.Entity<FinancialTransaction>().Property(t => t.Amount).HasPrecision(18, 2);


            // --- SEED DATA (Datos Iniciales RRHH) ---
            modelBuilder.Entity<WageScale>().HasData(
                // UOCRA
                new WageScale { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Union = UnionType.UOCRA, CategoryName = "Oficial Especializado", BasicValue = 6500, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Union = UnionType.UOCRA, CategoryName = "Oficial", BasicValue = 5800, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Union = UnionType.UOCRA, CategoryName = "Medio Oficial", BasicValue = 5200, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), Union = UnionType.UOCRA, CategoryName = "Ayudante", BasicValue = 4900, IsActive = true, ValidFrom = DateTime.Now },
                
                // UECARA
                new WageScale { Id = Guid.Parse("55555555-5555-5555-5555-555555555555"), Union = UnionType.UECARA, CategoryName = "Administrativo A", BasicValue = 950000, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("66666666-6666-6666-6666-666666666666"), Union = UnionType.UECARA, CategoryName = "Administrativo B", BasicValue = 1100000, IsActive = true, ValidFrom = DateTime.Now }
            );
        }
    }
}