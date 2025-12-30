using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Provider
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid CompanyId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty; // Ej: "Corralón El Amigo"

        public string? TaxId { get; set; } // CUIT, RUT o RFC
        
        public string? ContactName { get; set; } // Nombre del vendedor
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string? Address { get; set; }

        public bool IsActive { get; set; } = true;
    }
}