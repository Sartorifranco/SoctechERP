using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Models
{
    [Table("InvoiceExceptions")]
    public class InvoiceException
    {
        [Key]
        public Guid Id { get; set; }

        public Guid SupplierInvoiceId { get; set; }
        
        public VarianceType Type { get; set; } // ¿Qué falló?

        // Snapshot para visualización rápida
        public string ItemName { get; set; } = string.Empty; 
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal ExpectedValue { get; set; } // Lo que decía la Orden de Compra ($1000)
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal ActualValue { get; set; }   // Lo que vino en la Factura ($1100)

        [Column(TypeName = "decimal(18,2)")]
        public decimal VarianceTotalAmount { get; set; } // Impacto total en plata ($100 x 1000 un = $100.000)

        public string Description { get; set; } = string.Empty;

        // Workflow de Resolución
        public bool IsResolved { get; set; } = false;
        public DateTime? ResolvedAt { get; set; }
        public Guid? ResolvedByUserId { get; set; } // Tu ID al aprobar
        public string? ManagerComment { get; set; } // "Autorizo por ajuste inflacionario"
    }
}