using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SoctechERP.API.Models
{
    // Catálogo de Módulos del Sistema (Ej: "Ventas", "Compras")
    public class SystemModule
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        public string Name { get; set; } = string.Empty; // Nombre visible (Ej: "Tesorería")
        
        [Required]
        public string Code { get; set; } = string.Empty; // Código interno (Ej: "MODULE_TREASURY")
    }

    // Tabla intermedia: Qué usuario puede ver qué módulo
    public class UserPermission
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [ForeignKey("User")]
        public Guid UserId { get; set; }
        
        [ForeignKey("SystemModule")]
        public Guid ModuleId { get; set; }

        public bool IsEnabled { get; set; } = true; // ¿Tiene acceso?

        // Propiedades de navegación (opcional, ayuda a EF)
        public User? User { get; set; }
        public SystemModule? SystemModule { get; set; }
    }
}