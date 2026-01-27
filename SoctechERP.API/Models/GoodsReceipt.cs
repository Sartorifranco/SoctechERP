using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Models
{
    [Table("GoodsReceipts")]
    public class GoodsReceipt
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid CompanyId { get; set; }

        // --- 1. Vinculación Comercial ---
        [Required]
        public Guid PurchaseOrderId { get; set; }
        
        public Guid ProviderId { get; set; }
        public string ProviderName { get; set; } = string.Empty;

        // --- 2. Datos del Papel Físico ---
        [Required]
        [MaxLength(50)]
        public string RemitoNumber { get; set; } = string.Empty; // R-0001-XXXX
        
        public DateTime ReceptionDate { get; set; } = DateTime.UtcNow;

        // --- 3. Destino Lógico ---
        // A qué depósito de tu sistema está entrando esta mercadería
        public Guid TargetWarehouseId { get; set; }
        // A qué Sucursal pertenece ese depósito (para reportes regionales)
        public Guid TargetBranchId { get; set; }

        // --- 4. Seguridad y Auditoría (Anti-Fraude) ---
        public Guid ReceivedByUserId { get; set; }
        
        // Coordenadas GPS obligatorias al firmar
        public double? ReceivedLatitude { get; set; }
        public double? ReceivedLongitude { get; set; } 

        // Evidencia
        public string? DigitalSignatureUrl { get; set; } // Firma en pantalla
        public string? EvidencePhotoUrl { get; set; } // Foto del remito papel

        public string? Comments { get; set; }

        // --- 5. Estado ---
        public ReceiptStatus Status { get; set; } = ReceiptStatus.Draft;

        // --- 6. Detalle ---
        public virtual ICollection<GoodsReceiptItem> Items { get; set; } = new List<GoodsReceiptItem>();
    }
}