using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class ContractorJob
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid ContractorId { get; set; } // ¿Quién lo hace?
        public Guid ProjectId { get; set; }    // ¿En qué obra?

        public string Description { get; set; } = string.Empty; // Ej: "Instalación eléctrica PB"

        public DateTime StartDate { get; set; } = DateTime.UtcNow;
        public DateTime? EndDate { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal AgreedAmount { get; set; } // ¿Cuánto le vamos a pagar?

        public bool IsPaid { get; set; } = false; // ¿Ya se pagó?
    }
}