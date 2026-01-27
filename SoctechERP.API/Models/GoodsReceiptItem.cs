using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Models
{
    [Table("GoodsReceiptItems")]
    public class GoodsReceiptItem
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid GoodsReceiptId { get; set; }

        public Guid ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty; // Snapshot del nombre

        // --- Control de Cantidades ---
        [Column(TypeName = "decimal(18,2)")]
        public decimal QuantityOrdered { get; set; } // Lo que decía la Orden de Compra

        [Column(TypeName = "decimal(18,2)")]
        public decimal QuantityReceived { get; set; } // Lo que realmente bajó del camión

        [Column(TypeName = "decimal(18,2)")]
        public decimal QuantityRejected { get; set; } // Rechazado por rotura

        // --- Calidad ---
        public QualityCondition Condition { get; set; } = QualityCondition.Good;
        public string? RejectionReason { get; set; }
    }
}