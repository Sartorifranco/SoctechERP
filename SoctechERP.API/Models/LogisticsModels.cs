using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    // 1. EL LUGAR FÍSICO (Depósito Central, Pañol Obra, Camioneta)
    public class Warehouse
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public string Name { get; set; } = string.Empty; // Ej: "Depósito Central", "Pañol Obra A"

        public string Location { get; set; } = string.Empty; // Dirección física

        public bool IsMain { get; set; } = false; // ¿Es el depósito principal por defecto?
        public bool IsActive { get; set; } = true;
    }

    // 2. EL STOCK PUNTUAL (La relación Producto <-> Depósito)
    // Esto responde: "¿Cuánto hay de ESTE producto en ESTE lugar?"
    public class ProductStock
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid ProductId { get; set; }
        
        [Required]
        public Guid WarehouseId { get; set; }

        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; } = 0; // Cantidad en este depósito específico

        // Propiedades de Navegación
        public Product? Product { get; set; }
        public Warehouse? Warehouse { get; set; }
    }
}