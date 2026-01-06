using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("stats")]
        public async Task<ActionResult> GetDashboardStats()
        {
            // 1. Contar Obras Activas (Usamos IsActive, NO Status)
            var activeProjects = await _context.Projects.CountAsync(p => p.IsActive);

            // 2. Contar Empleados Activos
            var activeEmployees = await _context.Employees.CountAsync(e => e.IsActive);

            // 3. Valorización del Stock (Cantidad * Precio de Costo)
            var totalStockValue = await _context.Products
                .SumAsync(p => p.Stock * p.CostPrice);

            return Ok(new
            {
                activeProjects,
                activeEmployees,
                totalStockValue
            });
        }
    }
}