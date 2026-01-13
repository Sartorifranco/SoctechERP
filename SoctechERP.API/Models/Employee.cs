using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class Employee
    {
        [Key]
        public Guid Id { get; set; }

        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        // [NotMapped] significa que esto NO se guarda en la base de datos, se calcula al vuelo.
        // Por eso no podías asignarle valor directamente en el controlador.
        [NotMapped]
        public string FullName => $"{LastName}, {FirstName}";

        public string Cuil { get; set; } = string.Empty;
        
        // --- NUEVOS CAMPOS ---
        public string Dni { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        
        // Guardamos la categoría como texto por defecto si viene del CSV
        public string Category { get; set; } = "Ayudante"; 

        public bool IsActive { get; set; } = true;
        public DateTime EntryDate { get; set; }

        // 0: UOCRA, 1: UECARA, 2: FDC
        public int Union { get; set; } 
        // 0: Quincenal, 1: Mensual
        public int Frequency { get; set; } 

        // Relaciones
        public Guid? WageScaleId { get; set; }
        public WageScale? WageScale { get; set; }

        public Guid? CurrentProjectId { get; set; }
        public Project? CurrentProject { get; set; }
        
        public double? NegotiatedSalary { get; set; }
    }
}