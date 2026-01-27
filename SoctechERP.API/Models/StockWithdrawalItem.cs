using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    [Table("StockWithdrawalItems")]
    public class StockWithdrawalItem
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        public Guid StockWithdrawalId { get; set; }

        public Guid ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty; // Snapshot

        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }

        // DATOS FINANCIEROS (Job Costing)
        // Guardamos cuánto costó esto en el momento exacto que salió.
        // Se calcula con PPP automáticamente.
        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitCostSnapshot { get; set; } 

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalCost { get; set; } 
    }
}