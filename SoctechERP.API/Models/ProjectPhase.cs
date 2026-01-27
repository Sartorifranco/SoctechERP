using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models 
{
    [Table("ProjectPhases")]
    public class ProjectPhase
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        // Relación con la Obra
        [Required]
        public Guid ProjectId { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty; 
        
        public string Description { get; set; } = string.Empty;

        // --- GESTIÓN FINANCIERA (CONTROL DE COSTOS) ---
        // Usamos 'decimal' para evitar errores de redondeo financiero.

        // 1. Planificación (Presupuesto)
        [Column(TypeName = "decimal(18,2)")]
        public decimal Budget { get; set; } // Presupuesto Global de la fase

        [Column(TypeName = "decimal(18,2)")]
        public decimal BudgetedMaterialCost { get; set; } // Meta de gasto en materiales

        // 2. Ejecución (Realidad)
        // Este campo se actualiza solo cuando el LogisticsService procesa un Vale de Salida
        [Column(TypeName = "decimal(18,2)")]
        public decimal ActualMaterialCost { get; set; }

        // Preparado para el futuro módulo de RRHH
        [Column(TypeName = "decimal(18,2)")]
        public decimal ActualLaborCost { get; set; }

        public bool IsCompleted { get; set; } = false;
        public bool IsActive { get; set; } = true;
    }
}