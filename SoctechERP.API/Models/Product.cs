using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class Product
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        // Recuperamos este campo que faltaba y daba error en ProductsController
        public string? Sku { get; set; } 

        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; } // Precio de Venta

        [Column(TypeName = "decimal(18,2)")]
        public decimal CostPrice { get; set; } // Precio de Costo

        // Renombramos 'StockCurrent' a 'Stock' para que DispatchController y PurchaseOrdersController no fallen
        [Column(TypeName = "decimal(18,2)")]
        public decimal Stock { get; set; } 

        public bool IsActive { get; set; } = true;
    }
}