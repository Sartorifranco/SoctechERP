using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Project
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public Guid CompanyId { get; set; }

        [Required]
        [MaxLength(255)]
        public string Name { get; set; } = string.Empty; // Ej: "Torre Capital"

        public string? Address { get; set; }

        public string Status { get; set; } = "In Progress"; // Estado de la obra

        public DateTime StartDate { get; set; } = DateTime.UtcNow;
        
        public bool IsActive { get; set; } = true;
    }
}