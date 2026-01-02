using System;
using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Provider
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        public string Name { get; set; } = string.Empty; // Razón Social

        [Required]
        public string Cuit { get; set; } = string.Empty; // <--- ESTO FALTABA

        public string ContactName { get; set; } = string.Empty; // Vendedor

        public string PhoneNumber { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Address { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
    }
}