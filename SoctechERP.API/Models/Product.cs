using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Product
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Sku { get; set; } = string.Empty;

        public string? Description { get; set; }

        public double CostPrice { get; set; }

        public double SalePrice { get; set; }

        // --- ESTE ES EL CAMPO QUE FALTABA PARA QUE LA MIGRACIÓN FUNCIONE ---
        public double Stock { get; set; } = 0;
        // ------------------------------------------------------------------

        public bool IsActive { get; set; } = true;
    }
}