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
        public string Name { get; set; } = string.Empty; 

        public string Location { get; set; } = string.Empty; 

        // --- ESTA ES LA PROPIEDAD QUE FALTABA Y CAUSABA EL ERROR ---
        public Guid BranchId { get; set; } 
        // -----------------------------------------------------------

        public bool IsMain { get; set; } = false; 
        public bool IsActive { get; set; } = true;
    }

    // 2. EL STOCK PUNTUAL
    public class ProductStock
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid ProductId { get; set; }
        
        [Required]
        public Guid WarehouseId { get; set; }

        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; } = 0; 

        public Product? Product { get; set; }
        public Warehouse? Warehouse { get; set; }
    }
}