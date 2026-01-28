using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums; // <--- NECESARIO

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReportsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ReportsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/reports/project-costs/{projectId}
        [HttpGet("project-costs/{projectId}")]
        public async Task<IActionResult> GetProjectCosts(Guid projectId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null) return NotFound("Obra no encontrada");

            // 2. Buscar movimientos de salida
            var movements = await (from m in _context.StockMovements
                                   join p in _context.Products on m.ProductId equals p.Id
                                   where m.ProjectId == projectId 
                                         // CORRECCIÓN: Comparación con Enum
                                         && (m.MovementType == StockMovementType.ProjectConsumption)
                                   select new
                                   {
                                       ProdId = p.Id,
                                       ProdName = p.Name,
                                       Quantity = Math.Abs((double)m.Quantity), 
                                       UnitCost = p.CostPrice, 
                                       Description = m.Description, 
                                       Date = m.Date
                                   }).ToListAsync();

            // 3. Calcular Totales
            decimal totalSpent = 0;
            var details = new List<object>();

            var grouped = movements.GroupBy(m => m.ProdName);

            foreach (var group in grouped)
            {
                double totalQty = group.Sum(x => x.Quantity);
                decimal avgCost = (decimal)group.First().UnitCost; 
                decimal subTotal = (decimal)totalQty * avgCost;

                totalSpent += subTotal;

                details.Add(new 
                {
                    ProductName = group.Key,
                    TotalQuantity = totalQty,
                    AvgCost = avgCost,
                    SubTotal = subTotal
                });
            }

            // 4. Devolver reporte
            return Ok(new 
            {
                ProjectId = project.Id,
                ProjectName = project.Name,
                TotalSpent = totalSpent,
                Items = details.OrderByDescending(x => ((dynamic)x).SubTotal).ToList(),
                LastUpdate = DateTime.UtcNow
            });
        }
    }
}