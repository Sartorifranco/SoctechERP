using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    [Table("Products")]
    public class Product
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        // Recuperamos el SKU, vital para la logística y escaneo de códigos de barra
        public string? Sku { get; set; } 

        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; } // Precio de Venta (Lista)

        [Column(TypeName = "decimal(18,2)")]
        public decimal CostPrice { get; set; } // Costo de Referencia (Última compra o PPP)

        // Stock Actual (Caché). 
        // El stock real contable sale de sumar 'StockMovements', pero esto sirve para lectura rápida.
        [Column(TypeName = "decimal(18,2)")]
        public decimal Stock { get; set; } 

        public bool IsActive { get; set; } = true;

        // -----------------------------------------------------------
        // ESTRATEGIA DE SEGURIDAD HÍBRIDA (ABC)
        // -----------------------------------------------------------
        // true: Productos de Alto Valor (Cemento, Grifería) -> Requieren "Vale de Salida" firmado.
        // false: Productos a Granel (Arena, Agua) -> Se consumen automáticamente (Backflush).
        public bool RequiresConsumptionControl { get; set; } = true; 
    }
}