using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class StockMovement
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid CompanyId { get; set; }

        [Required]
        public Guid BranchId { get; set; }

        [Required]
        public Guid ProductId { get; set; }

        // Relación con la Obra (Puede ser null si es una compra general o ajuste)
        public Guid? ProjectId { get; set; }

        // --- NUEVA PROPIEDAD PARA FASES ---
        // Permite saber si el material fue para "Cimientos", "Techo", etc.
        public Guid? ProjectPhaseId { get; set; } 
        // ----------------------------------

        [Required]
        [MaxLength(50)]
        public string MovementType { get; set; } = string.Empty; // Ej: PURCHASE, CONSUMPTION

        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitCost { get; set; }

        public DateTime Date { get; set; } = DateTime.UtcNow;

        [MaxLength(100)]
        public string? Reference { get; set; }
    }
}