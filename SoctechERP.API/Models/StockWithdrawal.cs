using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    [Table("StockWithdrawals")]
    public class StockWithdrawal
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        // --- Contexto ---
        public Guid ProjectId { get; set; }      // A qué obra le cobramos
        public Guid ProjectPhaseId { get; set; } // A qué fase (ej: "Losa 2do Piso")
        public Guid WarehouseId { get; set; }    // De qué depósito físico sale

        // --- Responsables ---
        public Guid RequestedByUserId { get; set; } // El capataz que pide
        
        // Si el producto es "Clase A" (RequiresConsumptionControl), este campo es obligatorio
        public Guid? ApprovedByUserId { get; set; }  

        public DateTime WithdrawalDate { get; set; } = DateTime.UtcNow;

        // --- Evidencia (Anti-Robo) ---
        [Required]
        [MaxLength(50)]
        public string WithdrawalNumber { get; set; } = string.Empty; // "VALE-00045"
        
        public string? DigitalSignatureUrl { get; set; } // Firma del capataz en pantalla
        
        // Coordenadas GPS obligatorias al retirar
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        public string Description { get; set; } = string.Empty; // "Materiales para hormigonado"

        // --- Detalle ---
        public virtual ICollection<StockWithdrawalItem> Items { get; set; } = new List<StockWithdrawalItem>();
    }
}