using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

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
            // 1. Validar que la obra exista
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null) return NotFound("Obra no encontrada");

            // 2. Buscar todos los movimientos de salida (DISPATCH) de esa obra
            // Usamos un JOIN manual con LINQ para asegurarnos de traer el precio actual del producto
            var movements = await (from m in _context.StockMovements
                                   join p in _context.Products on m.ProductId equals p.Id
                                   where m.ProjectId == projectId 
                                      && (m.MovementType == "DISPATCH" || m.MovementType == "CONSUMPTION")
                                   select new
                                   {
                                       ProdId = p.Id,
                                       ProdName = p.Name,
                                       // Cantidad siempre positiva para el reporte de gastos
                                       Quantity = Math.Abs((double)m.Quantity), 
                                       UnitCost = p.CostPrice, // Usamos el costo actual del producto
                                       // Extraemos la fase de la descripción si es posible, o "General"
                                       Description = m.Description, 
                                       Date = m.Date
                                   }).ToListAsync();

            // 3. Calcular Totales
            decimal totalSpent = 0;
            var details = new List<object>();

            // Agrupamos por Producto para que no salga 50 veces "Cemento"
            var grouped = movements.GroupBy(m => m.ProdName);

            foreach (var group in grouped)
            {
                double totalQty = group.Sum(x => x.Quantity);
                // Usamos el costo del primer ítem (son todos el mismo producto)
                // Nota: Convertimos a decimal para cálculo monetario
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

            // 4. Devolver el reporte JSON
            return Ok(new 
            {
                ProjectId = project.Id,
                ProjectName = project.Name,
                TotalSpent = totalSpent,
                Items = details.OrderByDescending(x => ((dynamic)x).SubTotal).ToList(), // Ordenar por lo que más gastó
                LastUpdate = DateTime.UtcNow
            });
        }
    }
}