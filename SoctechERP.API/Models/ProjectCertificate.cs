using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class ProjectCertificate
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid ProjectId { get; set; } // ¿De qué obra es?
        
        public DateTime Date { get; set; } = DateTime.UtcNow; // Fecha de certificación
        
        public double Percentage { get; set; } // Avance (ej: 15%)

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; } // Plata a cobrar (ej: $1.500.000)

        public string Note { get; set; } = string.Empty; // Ej: "Certificado Nº 1 - Movimiento de Suelos"
    }
}