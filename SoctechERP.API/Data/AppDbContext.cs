using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums; // Asegúrate de tener este using para los Enums

namespace SoctechERP.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        // --- TABLAS DE LA BASE DE DATOS ---
        public DbSet<Company> Companies { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Branch> Branches { get; set; }
        public DbSet<StockMovement> StockMovements { get; set; }
        public DbSet<Project> Projects { get; set; }
        public DbSet<Provider> Providers { get; set; }
        public DbSet<ProjectPhase> ProjectPhases { get; set; }
        
        // MÓDULO RRHH (NUEVO)
        public DbSet<Employee> Employees { get; set; }
        public DbSet<WorkLog> WorkLogs { get; set; }
        public DbSet<WageScale> WageScales { get; set; } // <--- Tabla de Categorías/Precios

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // --- CONFIGURACIONES E ÍNDICES ---
            modelBuilder.Entity<Company>().HasIndex(c => c.Cuit).IsUnique();

            modelBuilder.Entity<Product>().HasIndex(p => p.Sku).IsUnique();
            modelBuilder.Entity<Product>().Property(p => p.CostPrice).HasPrecision(18, 2);

            // Configuraciones numéricas para Movimientos de Stock
            modelBuilder.Entity<StockMovement>().Property(s => s.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.UnitCost).HasPrecision(18, 2);

            // Configuraciones numéricas para RRHH
            modelBuilder.Entity<Employee>().Property(e => e.Address).HasDefaultValue(""); 
            modelBuilder.Entity<WageScale>().Property(w => w.BasicValue).HasPrecision(18, 2);
            modelBuilder.Entity<WorkLog>().Property(w => w.RegisteredRateSnapshot).HasPrecision(18, 2);

            // --- DATOS INICIALES (SEED DATA) ---
            // Esto carga automáticamente las categorías de UOCRA y UECARA al crear la base de datos
            modelBuilder.Entity<WageScale>().HasData(
                // UOCRA (Construcción - Por Hora)
                new WageScale { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Union = UnionType.UOCRA, CategoryName = "Oficial Especializado", BasicValue = 6500, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Union = UnionType.UOCRA, CategoryName = "Oficial", BasicValue = 5800, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Union = UnionType.UOCRA, CategoryName = "Medio Oficial", BasicValue = 5200, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), Union = UnionType.UOCRA, CategoryName = "Ayudante", BasicValue = 4900, IsActive = true, ValidFrom = DateTime.Now },
                
                // UECARA (Administrativos - Mensual)
                new WageScale { Id = Guid.Parse("55555555-5555-5555-5555-555555555555"), Union = UnionType.UECARA, CategoryName = "Administrativo A", BasicValue = 950000, IsActive = true, ValidFrom = DateTime.Now },
                new WageScale { Id = Guid.Parse("66666666-6666-6666-6666-666666666666"), Union = UnionType.UECARA, CategoryName = "Administrativo B", BasicValue = 1100000, IsActive = true, ValidFrom = DateTime.Now }
            );
        }
    }
}