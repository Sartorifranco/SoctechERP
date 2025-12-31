using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Models;

namespace SoctechERP.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<Company> Companies { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Branch> Branches { get; set; }
        public DbSet<StockMovement> StockMovements { get; set; } // <--- NUEVO
        public DbSet<Project> Projects { get; set; }
        public DbSet<Provider> Providers { get; set; }
        public DbSet<ProjectPhase> ProjectPhases { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Company>().HasIndex(c => c.Cuit).IsUnique();

            modelBuilder.Entity<Product>().HasIndex(p => p.Sku).IsUnique();
            modelBuilder.Entity<Product>().Property(p => p.CostPrice).HasPrecision(18, 2);

            // Configuraciones numéricas para Movimientos
            modelBuilder.Entity<StockMovement>().Property(s => s.Quantity).HasPrecision(18, 4);
            modelBuilder.Entity<StockMovement>().Property(s => s.UnitCost).HasPrecision(18, 2);
        }
    }
}