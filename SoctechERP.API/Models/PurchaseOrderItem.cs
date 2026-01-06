using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class PurchaseOrderItem
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid PurchaseOrderId { get; set; } // Relación FK

        public Guid ProductId { get; set; } // Qué compramos
        
        public double Quantity { get; set; } // Cuánto

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; } // A qué precio pactado
    }
}