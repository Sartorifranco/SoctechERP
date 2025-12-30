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

        // GET: api/Dashboard/stats
        [HttpGet("stats")]
        public async Task<ActionResult<object>> GetStats()
        {
            // 1. Calcular Valor Total del Inventario (Stock * Precio de Costo)
            var totalValue = await _context.Products
                .SumAsync(p => p.Stock * p.CostPrice);

            // 2. Contar Obras Activas
            // (Asumimos que si no está "Finished", está activa)
            var activeProjects = await _context.Projects
                .CountAsync(p => p.Status != "Finished" && p.IsActive);

            // 3. Alerta de Stock Bajo (Productos con menos de 10 unidades)
            var lowStock = await _context.Products
                .CountAsync(p => p.Stock < 10);

            return Ok(new 
            { 
                totalInventoryValue = totalValue, 
                activeProjects = activeProjects,
                lowStockCount = lowStock
            });
        }
    }
}