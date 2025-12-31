using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models // Ajusta el namespace según tu proyecto
{
    public class ProjectPhase
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string Name { get; set; } // Ej: "Cimientos", "Techo"

        public string Description { get; set; }

        public double Budget { get; set; } // Presupuesto específico para esta fase

        public bool IsCompleted { get; set; } = false;

        // Relación con la Obra
        [Required]
        public Guid ProjectId { get; set; }
        
        // (Opcional) Si tienes la clase Project definida, descomenta esto para navegación:
        // [ForeignKey("ProjectId")]
        // public Project Project { get; set; }
    }
}