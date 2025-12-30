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
        public async Task<ActionResult<IEnumerable<StockMovement>>> GetMovements()
        {
            return await _context.StockMovements.ToListAsync();
        }

        // POST: api/StockMovements
        [HttpPost]
        public async Task<ActionResult<StockMovement>> PostMovement(StockMovement movement)
        {
            // 1. Validaciones
            if (movement.Quantity == 0)
            {
                return BadRequest("La cantidad no puede ser cero.");
            }

            // 2. Guardamos el movimiento
            _context.StockMovements.Add(movement);

            // 3. Actualizamos el Producto
            var product = await _context.Products.FindAsync(movement.ProductId);
            
            if (product != null)
            {
                // CORRECCIÓN AQUI: Agregamos (double) para convertir el decimal
                product.Stock += (double)movement.Quantity;
                
                _context.Entry(product).State = EntityState.Modified;
            }

            // 4. Guardamos todo
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetMovements", new { id = movement.Id }, movement);
        }

        // GET: api/StockMovements/balance/{branchId}/{productId}
        [HttpGet("balance/{branchId}/{productId}")]
        public async Task<ActionResult<decimal>> GetStockBalance(Guid branchId, Guid productId)
        {
            var balance = await _context.StockMovements
                .Where(m => m.BranchId == branchId && m.ProductId == productId)
                .SumAsync(m => m.Quantity);

            return Ok(new { branchId, productId, currentStock = balance });
        }
    }
}