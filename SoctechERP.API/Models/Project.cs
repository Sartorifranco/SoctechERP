using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class Project
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public string Name { get; set; } = string.Empty;

        public string Address { get; set; } = string.Empty;

        public DateTime StartDate { get; set; } = DateTime.UtcNow;
        public DateTime? EndDate { get; set; }
        
        // Esta era la que faltaba para el error CS1061
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow; 

        public bool IsActive { get; set; } = true;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalContractAmount { get; set; } = 0;
    }
}