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

        // --- LOGIN: Devuelve Token + Lista de Permisos ---
        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginDto request)
        {
            // 1. Buscar usuario
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
            
            // 2. Validar
            if (user == null || user.Password != request.Password)
            {
                return Unauthorized("Usuario o contraseña incorrectos.");
            }

            // --- 3. LOGICA ENTERPRISE: OBTENER PERMISOS ---
            List<string> allowedModules = new List<string>();

            if (user.Role == "SuperAdmin") 
            {
                // Si es SuperAdmin, le damos TODOS los códigos de módulos existentes
                allowedModules = await _context.SystemModules.Select(m => m.Code).ToListAsync();
            }
            else 
            {
                // Si es un usuario normal, buscamos en la tabla intermedia
                allowedModules = await _context.UserPermissions
                    .Where(p => p.UserId == user.Id && p.IsEnabled == true)
                    .Join(_context.SystemModules,
                          perm => perm.ModuleId,
                          mod => mod.Id,
                          (perm, mod) => mod.Code) // Seleccionamos solo el Código (ej: "SALES")
                    .ToListAsync();
            }

            // 4. Generar Token JWT
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes("ESTA_ES_MI_CLAVE_SECRETA_SUPER_SEGURA_123456"); 

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Role, user.Role),
                    new Claim("Id", user.Id.ToString())
                }),
                Expires = DateTime.UtcNow.AddDays(7),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var tokenString = tokenHandler.WriteToken(token);

            // 5. RETORNO ENRIQUECIDO
            return Ok(new { 
                Token = tokenString, 
                User = user.Username,
                Role = user.Role,
                Permissions = allowedModules 
            });
        }

        // --- REGISTRO BÁSICO ---
        [HttpPost("register")]
        public async Task<IActionResult> Register(User user)
        {
            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
                return BadRequest("El usuario ya existe.");

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return Ok(user);
        }
        
        // --- UTILIDADES PARA EL FRONTEND ---

        // Listar módulos disponibles (Para armar los checks)
        [HttpGet("modules")]
        public async Task<IActionResult> GetModules()
        {
            return Ok(await _context.SystemModules.ToListAsync());
        }

        // --- GESTIÓN DE USUARIOS (NUEVO) ---

        // 1. Listar todos los usuarios
        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _context.Users
                .Select(u => new { u.Id, u.Username, u.Role }) // No devolvemos la password por seguridad
                .ToListAsync();
            return Ok(users);
        }

        // 2. Obtener permisos de un usuario específico (IDs de módulos habilitados)
        [HttpGet("permissions/{userId}")]
        public async Task<IActionResult> GetUserPermissions(Guid userId)
        {
            var permissionIds = await _context.UserPermissions
                .Where(p => p.UserId == userId && p.IsEnabled)
                .Select(p => p.ModuleId)
                .ToListAsync();
            return Ok(permissionIds);
        }

        // 3. Guardar/Actualizar permisos de un usuario
        [HttpPost("permissions/{userId}")]
        public async Task<IActionResult> UpdatePermissions(Guid userId, [FromBody] List<Guid> moduleIds)
        {
            // Borramos permisos anteriores
            var existing = _context.UserPermissions.Where(p => p.UserId == userId);
            _context.UserPermissions.RemoveRange(existing);

            // Insertamos los nuevos
            foreach (var modId in moduleIds)
            {
                _context.UserPermissions.Add(new UserPermission
                {
                    UserId = userId,
                    ModuleId = modId,
                    IsEnabled = true
                });
            }

            await _context.SaveChangesAsync();
            return Ok("Permisos actualizados correctamente");
        }
    }
}