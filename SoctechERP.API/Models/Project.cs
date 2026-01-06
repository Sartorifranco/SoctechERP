using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema; // <--- ESTA ERA LA LÍNEA QUE FALTABA

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

        public bool IsActive { get; set; } = true;

        // Monto Total del Contrato (Ingresos Esperados)
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalContractAmount { get; set; } = 0;
    }
}