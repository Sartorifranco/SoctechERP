using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class SalesInvoice
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        // 1. Datos Fiscales (Listos para Factura Electrónica)
        public string InvoiceType { get; set; } = "A"; // A, B, C
        public string SalePoint { get; set; } = "0001"; // Punto de Venta
        public string InvoiceNumber { get; set; } = "00000000"; // Se genera al timbrar
        public string? CAE { get; set; } 
        public DateTime? VtoCAE { get; set; }

        public DateTime InvoiceDate { get; set; } = DateTime.UtcNow;
        
        // 2. El Cliente y la Obra
        [Required]
        public string ClientName { get; set; } = string.Empty;
        public string ClientCuit { get; set; } = string.Empty;
        
        public Guid ProjectId { get; set; } // Vinculación contable
        public string ProjectName { get; set; } = string.Empty;

        // 3. Concepto
        public string Concept { get; set; } = string.Empty; // Ej: "Certificado de Obra Nro 3"

        // 4. LOS NÚMEROS "PRO" (Manejo de Fondo de Reparo)
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal NetAmount { get; set; } // Neto Gravado (Base Imponible)

        [Column(TypeName = "decimal(18,2)")]
        public decimal VatPercentage { get; set; } = 21; // 21% o 10.5% en obra

        [Column(TypeName = "decimal(18,2)")]
        public decimal VatAmount { get; set; } // El monto del IVA

        [Column(TypeName = "decimal(18,2)")]
        public decimal GrossTotal { get; set; } // Total de la Factura (Lo que dice el papel)

        // --- LA DIFERENCIA CON UN SISTEMA COMÚN ---
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal RetainagePercentage { get; set; } = 0; // Ej: 5% Fondo de Reparo

        [Column(TypeName = "decimal(18,2)")]
        public decimal RetainageAmount { get; set; } // Plata que el cliente se guarda

        [Column(TypeName = "decimal(18,2)")]
        public decimal CollectibleAmount { get; set; } // Lo que realmente vamos a cobrar hoy (Total - Fondo)

        // 5. Estado de Cobranza
        public string Status { get; set; } = "Issued"; // Issued (Emitida), Paid (Cobrada), Void (Anulada)
    }
}