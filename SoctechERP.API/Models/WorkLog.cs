using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class WorkLog
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid EmployeeId { get; set; }
        
        // --- AQUÍ ESTÁ EL CAMBIO ---
        [ForeignKey("EmployeeId")]
        public Employee? Employee { get; set; } // <--- Agrega el '?' para evitar el Error 400
        // ---------------------------

        public Guid ProjectId { get; set; }
        public Guid? ProjectPhaseId { get; set; }

        public DateTime Date { get; set; }

        public double HoursWorked { get; set; } 

        [Column(TypeName = "decimal(18,2)")]
        public decimal RegisteredRateSnapshot { get; set; } 

        public string? Notes { get; set; }
    }
}