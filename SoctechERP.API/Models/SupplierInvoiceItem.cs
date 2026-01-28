using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    [Table("SupplierInvoiceItems")]
    public class SupplierInvoiceItem
    {
        [Key]
        public Guid Id { get; set; }

        public Guid SupplierInvoiceId { get; set; }
        
        public Guid ProductId { get; set; } // Vinculación con Stock
        
        [MaxLength(200)]
        public string Description { get; set; } = string.Empty; // Descripción según el proveedor

        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal UnitPrice { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalLineAmount { get; set; }

        // --- RELACIONES DE NAVEGACIÓN ---
        // [JsonIgnore] // Descomentar si usas System.Text.Json y tienes ciclos
        // public virtual SupplierInvoice? SupplierInvoice { get; set; }
    }
}