using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Models
{
    public class Employee
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        // --- DATOS PERSONALES ---
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        public string CUIL { get; set; } = string.Empty; 

        public DateTime BirthDate { get; set; }
        public string Address { get; set; } = string.Empty;

        // --- DATOS CONTRACTUALES ---
        public DateTime EntryDate { get; set; } // Para antigüedad

        public UnionType Union { get; set; }
        public PayFrequency Frequency { get; set; }

        // CAMPO PARA SUELDO MANUAL (Fuera de Convenio)
        [Column(TypeName = "decimal(18,2)")]
        public decimal? NegotiatedSalary { get; set; }

        // --- CAMBIO CLAVE AQUÍ: AGREGAMOS EL '?' PARA QUE SEA OPCIONAL ---
        public Guid? WageScaleId { get; set; } 
        // -----------------------------------------------------------------
        
        [ForeignKey("WageScaleId")]
        public WageScale? WageScale { get; set; }

        // OBRA ASIGNADA ACTUALMENTE
        public Guid? CurrentProjectId { get; set; } // Puede ser nulo si está en "Base"
        
        // (Opcional) Propiedad de navegación si quisieras traer el nombre del proyecto
        // [ForeignKey("CurrentProjectId")]
        // public Project? CurrentProject { get; set; }

        public bool IsActive { get; set; } = true;

        public string FullName => $"{LastName}, {FirstName}";
    }
}