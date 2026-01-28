using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    public class Branch
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        // --- ESTA ES LA PROPIEDAD QUE FALTABA ---
        public string Location { get; set; } = string.Empty; 
        // ----------------------------------------

        public bool IsActive { get; set; } = true;
    }
}