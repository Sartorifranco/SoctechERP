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

        public string OrderNumber { get; set; } = string.Empty;

        public Guid ProviderId { get; set; }
        
        // Faltaba este campo para vincular la compra a la Obra
        public Guid? ProjectId { get; set; } 
        
        public DateTime Date { get; set; } = DateTime.UtcNow;
        
        public string Status { get; set; } = "Pending"; 

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; }

        public List<PurchaseOrderItem> Items { get; set; } = new List<PurchaseOrderItem>();
    }
}