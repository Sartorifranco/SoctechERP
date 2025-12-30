using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Branch
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid CompanyId { get; set; } // Pertenece a la empresa

        [Required]
        [MaxLength(255)]
        public string Name { get; set; } = string.Empty; // Ej: "Depósito Central", "Obra Torre Capital"

        public string? Address { get; set; } // Dirección física

        public bool IsWarehouse { get; set; } = true; // ¿Es un lugar que guarda stock?
        
        public bool IsActive { get; set; } = true;
    }
}