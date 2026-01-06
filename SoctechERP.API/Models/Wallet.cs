using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class Wallet
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public string Name { get; set; } = string.Empty; // Ej: "Caja Chica Obra", "Banco Galicia CC"

        public string Type { get; set; } = "CASH"; // CASH, BANK, CHECK_PORTFOLIO

        public string Currency { get; set; } = "ARS"; 

        [Column(TypeName = "decimal(18,2)")]
        public decimal Balance { get; set; } = 0; // El saldo actual real

        public bool IsActive { get; set; } = true;
    }
}