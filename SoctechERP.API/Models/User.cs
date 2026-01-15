using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class User
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Username { get; set; } = string.Empty; // Email o nombre
        public string Password { get; set; } = string.Empty; // En prod esto se hashea
        public string Role { get; set; } = "Admin";
    }

    public class LoginDto
    {
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}