using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public AuthController(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginDto request)
        {
            // 1. Buscar usuario
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
            
            // 2. Validar (En prod usar BCrypt para comparar hash)
            if (user == null || user.Password != request.Password)
            {
                return Unauthorized("Usuario o contraseña incorrectos.");
            }

            // 3. Generar Token JWT (La llave digital)
            var tokenHandler = new JwtSecurityTokenHandler();
            // Usamos una clave secreta fija para desarrollo (En prod va a variables de entorno)
            var key = Encoding.ASCII.GetBytes("ESTA_ES_MI_CLAVE_SECRETA_SUPER_SEGURA_123456"); 

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Role, user.Role),
                    new Claim("Id", user.Id.ToString())
                }),
                Expires = DateTime.UtcNow.AddDays(7), // El login dura 7 días
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var tokenString = tokenHandler.WriteToken(token);

            return Ok(new { Token = tokenString, User = user.Username });
        }

        // Endpoint para crear el primer usuario (Setup inicial)
        [HttpPost("register")]
        public async Task<IActionResult> Register(User user)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return Ok(user);
        }
    }
}