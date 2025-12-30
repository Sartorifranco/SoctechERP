using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    // Esta clase representa la tabla "companies" en tu base de datos
    public class Company
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid(); // ID único automático (UUID)

        [Required]
        [MaxLength(255)]
        public string Name { get; set; } = string.Empty; // Nombre de la empresa

        [Required]
        [MaxLength(20)]
        public string Cuit { get; set; } = string.Empty; // CUIT

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;
    }
}