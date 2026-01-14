using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StockMovementsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public StockMovementsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/StockMovements
        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockMovement>>> GetStockMovements()
        {
            return await _context.StockMovements
                                 .OrderByDescending(m => m.Date)
                                 .Take(100)
                                 .ToListAsync();
        }

        // POST: api/StockMovements (ESTE ES EL QUE FALTABA)
        [HttpPost]
        public async Task<ActionResult<StockMovement>> PostStockMovement(StockMovement movement)
        {
            // 1. Buscamos el producto relacionado para actualizar su stock
            var product = await _context.Products.FindAsync(movement.ProductId);

            if (product == null)
            {
                return NotFound("El producto especificado no existe.");
            }

            // 2. Lógica de Negocio: Actualizar Stock y Costo según el tipo de movimiento
            // El frontend envía "PURCHASE" para compras
            if (movement.MovementType == "PURCHASE" || movement.MovementType == "Entry")
            {
                // A) CÁLCULO DE PRECIO PROMEDIO PONDERADO (PPP)
                // Fórmula: ((StockActual * CostoActual) + (CantidadNueva * NuevoCosto)) / (StockActual + CantidadNueva)
                decimal currentTotalValue = (product.Stock * product.CostPrice);
                decimal newPurchaseValue = ((decimal)movement.Quantity * movement.UnitCost);
                decimal newTotalStock = product.Stock + (decimal)movement.Quantity;

                if (newTotalStock > 0)
                {
                    product.CostPrice = (currentTotalValue + newPurchaseValue) / newTotalStock;
                }
                else
                {
                    product.CostPrice = movement.UnitCost; // Si es el primero, toma el costo directo
                }

                // B) SUMAR STOCK
                product.Stock += (decimal)movement.Quantity;
            }
            else if (movement.MovementType == "Exit" || movement.MovementType == "Dispatch")
            {
                // Si fuera una salida, restamos
                product.Stock -= (decimal)movement.Quantity;
            }

            // 3. Guardamos el Movimiento (Historial) y el Producto (Actualizado)
            _context.StockMovements.Add(movement);
            
            // Entity Framework es inteligente: al modificar 'product' arriba, 
            // SaveChanges detecta que debe actualizar la tabla Products también.
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetStockMovements", new { id = movement.Id }, movement);
        }
    }
}