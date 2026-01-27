using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Models
{
    [Table("SupplierInvoices")]
    public class SupplierInvoice
    {
        [Key]
        public Guid Id { get; set; }

        // --- 1. Datos del Papel ---
        [Required]
        [MaxLength(50)]
        public string InvoiceNumber { get; set; } = string.Empty; // Ej: "0001-00045822"
        
        [MaxLength(5)]
        public string InvoiceType { get; set; } = "A"; // A, B, C, M
        
        public DateTime InvoiceDate { get; set; }
        public DateTime DueDate { get; set; } // Vencimiento (Cashflow)
        public DateTime? ReceptionDate { get; set; } = DateTime.UtcNow; // Fecha de mesa de entrada

        // --- 2. Proveedor ---
        public Guid ProviderId { get; set; }
        public string ProviderName { get; set; } = string.Empty;
        
        // public virtual Provider? Provider { get; set; } // Descomentar para navegación EF

        // --- 3. EL VÍNCULO "ORACLE" (3-Way Match) ---
        public Guid? RelatedPurchaseOrderId { get; set; } 

        // --- 4. Los Números ---
        [Column(TypeName = "decimal(18,2)")]
        public decimal NetAmount { get; set; } 

        [Column(TypeName = "decimal(18,2)")]
        public decimal VatAmount { get; set; } 

        [Column(TypeName = "decimal(18,2)")]
        public decimal OtherTaxes { get; set; } 

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; } 

        // --- 5. Estado del Ciclo de Vida (El Cerebro) ---
        // CAMBIO CRÍTICO: Usamos Enum para lógica de negocio estricta
        public InvoiceStatus Status { get; set; } = InvoiceStatus.Draft;

        // --- 6. Imputación ---
        public Guid? ProjectId { get; set; } 
        public string? AttachmentUrl { get; set; }

        // --- 7. Auditoría ---
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public Guid CreatedByUserId { get; set; } 

        // --- 8. DETALLE Y VALIDACIÓN (Nivel ERP) ---
        
        // Detalle de ítems (Fundamental para comparar unitarios)
        public virtual ICollection<SupplierInvoiceItem> Items { get; set; } = new List<SupplierInvoiceItem>();

        // Historial de problemas detectados (Bloqueos)
        public virtual ICollection<InvoiceException> Exceptions { get; set; } = new List<InvoiceException>();
    }
}