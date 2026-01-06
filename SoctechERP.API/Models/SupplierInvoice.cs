using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class SupplierInvoice
    {
        public Guid Id { get; set; }

        // 1. Datos del Papel
        [Required]
        public string InvoiceNumber { get; set; } = string.Empty; // Ej: "0001-00045822"
        public string InvoiceType { get; set; } = "A"; // A, B, C, M
        
        public DateTime InvoiceDate { get; set; }
        public DateTime DueDate { get; set; } // Vencimiento (Clave para Cashflow)

        // 2. ¿A quién le debemos?
        public Guid ProviderId { get; set; }
        public string ProviderName { get; set; } = string.Empty;

        // 3. EL VÍNCULO "ORACLE" (3-Way Match)
        // Opcional, porque a veces llegan facturas de luz/agua que no tienen Orden de Compra
        public Guid? RelatedPurchaseOrderId { get; set; } 

        // 4. Los Números
        [Column(TypeName = "decimal(18,2)")]
        public decimal NetAmount { get; set; } // Neto Gravado

        [Column(TypeName = "decimal(18,2)")]
        public decimal VatAmount { get; set; } // IVA (21% o 10.5%)

        [Column(TypeName = "decimal(18,2)")]
        public decimal OtherTaxes { get; set; } // Percepciones IIBB, Ganancias

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; } // El total a pagar

        // 5. Estado del Ciclo de Vida
        // "Draft" (Cargando), "Approved" (Validada), "Paid" (Pagada), "Void" (Anulada)
        public string Status { get; set; } = "Draft"; 

        // 6. Imputación de Costos (Para el Dashboard)
        // A veces una factura se divide en varios proyectos, pero para simplificar v1.0, la imputamos a uno principal.
        public Guid? ProjectId { get; set; } 
        
        // Archivo adjunto (PDF/Foto) - Guardamos la URL
        public string? AttachmentUrl { get; set; }
    }
}