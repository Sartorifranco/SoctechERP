using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums; // Asegurate de tener los Enums importados

namespace SoctechERP.API.Models
{
    [Table("StockMovements")]
    public class StockMovement
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid CompanyId { get; set; }

        [Required]
        public Guid BranchId { get; set; } // Sucursal dueña del movimiento

        [Required]
        public Guid ProductId { get; set; }

        // --- IMPUTACIÓN DE COSTOS (Project Accounting) ---
        public Guid? ProjectId { get; set; }
        public Guid? ProjectPhaseId { get; set; } 

        // --- LOGÍSTICA MULTI-DEPÓSITO ---
        // Lógica de Partida Doble: Origen -> Destino
        public Guid? SourceWarehouseId { get; set; } 
        public Guid? TargetWarehouseId { get; set; } 

        public virtual Warehouse? SourceWarehouse { get; set; }
        public virtual Warehouse? TargetWarehouse { get; set; }

        // --- TIPO DE MOVIMIENTO (BLINDADO) ---
        // Usamos Enum para evitar errores de tipeo y asegurar reportes financieros exactos
        [Required]
        public StockMovementType MovementType { get; set; } 

        // --- CANTIDAD Y VALOR ---
        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }

        // Valor unitario al momento exacto de la operación (Snapshot financiero)
        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitCost { get; set; }

        public DateTime Date { get; set; } = DateTime.UtcNow;

        public string Description { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? Reference { get; set; } // Ej: "Remito R-0001" o "Vale #504"
        
        // Vínculo con la recepción física (Auditoría)
        public Guid? RelatedGoodsReceiptId { get; set; }
    }
}