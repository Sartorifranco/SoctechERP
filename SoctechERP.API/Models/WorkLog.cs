using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class WorkLog
    {
        [Key]
        public Guid Id { get; set; }

        public DateTime Date { get; set; }
        public double HoursWorked { get; set; }
        public string Description { get; set; } = string.Empty;

        // Relación con Empleado
        public Guid EmployeeId { get; set; }
        public Employee? Employee { get; set; }

        // --- CAMPOS NUEVOS QUE FALTABAN ---
        
        // Relación con Obra (Para saber dónde trabajó)
        public Guid ProjectId { get; set; }
        public Project? Project { get; set; }

        // Datos Financieros (Snapshot: Guardamos cuánto valía la hora en ese momento)
        [Column(TypeName = "decimal(18,2)")]
        public decimal HourlyRateSnapshot { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalCost { get; set; }
    }
}