using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class PurchaseOrder
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public string OrderNumber { get; set; } = string.Empty; // Ej: OC-2024-001

        public Guid ProviderId { get; set; } // A quién le compramos
        
        public DateTime Date { get; set; } = DateTime.UtcNow;
        
        public string Status { get; set; } = "Pending"; // Pending, Received, Cancelled

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; }

        public List<PurchaseOrderItem> Items { get; set; } = new List<PurchaseOrderItem>();
    }
}