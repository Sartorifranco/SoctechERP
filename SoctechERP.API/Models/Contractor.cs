using System;
using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Contractor
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public string Name { get; set; } = string.Empty; // Ej: "Juan Perez"

        public string CUIT { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Trade { get; set; } = string.Empty; // Rubro: Electricista, Pintor, Gasista

        public bool IsActive { get; set; } = true;
    }
}