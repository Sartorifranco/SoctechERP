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

        // --- ESTA ES LA LÍNEA QUE TE FALTA ---
        public Guid? ProjectId { get; set; } // Puede ser null
        // --------------------------------------

        [Required]
        [MaxLength(50)]
        public string MovementType { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitCost { get; set; }

        public DateTime Date { get; set; } = DateTime.UtcNow;

        [MaxLength(100)]
        public string? Reference { get; set; }
    }
}