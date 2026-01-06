using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class FinancialTransaction
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public DateTime Date { get; set; } = DateTime.UtcNow;

        // ¿Qué billetera afectamos?
        public Guid WalletId { get; set; }
        public string WalletName { get; set; } = string.Empty;

        // INCOME (Entrada) o EXPENSE (Salida)
        public string Type { get; set; } = "EXPENSE"; 

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; } // Siempre positivo

        public string Description { get; set; } = string.Empty; // Ej: "Pago Factura Luz"

        // Vínculos Opcionales (Trazabilidad)
        public Guid? RelatedSupplierInvoiceId { get; set; } // Si pagamos una compra
        public Guid? RelatedSalesInvoiceId { get; set; }    // Si cobramos una venta
    }
}