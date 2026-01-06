using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Models
{
    // Esta tabla guarda la "Hoja de UOCRA"
    public class WageScale
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public UnionType Union { get; set; } // UOCRA o UECARA

        [Required]
        public string CategoryName { get; set; } = string.Empty; // Ej: "Oficial Especializado", "Administrativo A"

        // Valor Básico: Si es UOCRA es "por hora", si es Admin es "por mes".
        [Column(TypeName = "decimal(18,2)")]
        public decimal BasicValue { get; set; } 

        // Zona Desfavorable (Porcentaje). Ej: Córdoba Capital = 0%, Sur = 20%
        public double ZonePercentage { get; set; } = 0;

        public DateTime ValidFrom { get; set; } // Vigencia desde...
        public bool IsActive { get; set; } = true;
    }
}