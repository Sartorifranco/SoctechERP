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
                .Include(s => s.SourceWarehouse) // Incluimos info de depósitos
                .Include(s => s.TargetWarehouse)
                .OrderByDescending(s => s.Date)
                .ToListAsync();
        }

        // POST: api/StockMovements
        [HttpPost]
        public async Task<ActionResult<StockMovement>> PostStockMovement(StockMovement stockMovement)
        {
            // 1. Validaciones básicas
            if (stockMovement.Quantity <= 0) return BadRequest("La cantidad debe ser mayor a 0.");

            // 2. Guardamos el movimiento en el Historial (El "Papel")
            _context.StockMovements.Add(stockMovement);

            // 3. Actualizamos el Producto Global (Legacy - para que no se rompa lo viejo)
            var product = await _context.Products.FindAsync(stockMovement.ProductId);
            if (product == null) return NotFound("Producto no encontrado");

            // --- 4. LOGÍSTICA AUTOMÁTICA (EL CEREBRO NUEVO) ---
            
            // CASO A: ENTRADA DE MERCADERÍA (Compra o Transferencia Entrante)
            // Si hay un TargetWarehouseId, significa que la mercadería ENTRA a ese depósito.
            if (stockMovement.TargetWarehouseId.HasValue)
            {
                // Buscamos si ya existe registro de este producto en ese depósito
                var stockEntry = await _context.ProductStocks
                    .FirstOrDefaultAsync(ps => ps.ProductId == stockMovement.ProductId && ps.WarehouseId == stockMovement.TargetWarehouseId.Value);

                if (stockEntry == null)
                {
                    // Si es la primera vez que entra este producto a este depósito, creamos el registro
                    stockEntry = new ProductStock
                    {
                        ProductId = stockMovement.ProductId,
                        WarehouseId = stockMovement.TargetWarehouseId.Value,
                        Quantity = 0
                    };
                    _context.ProductStocks.Add(stockEntry);
                }

                // SUMAMOS AL DEPÓSITO DE DESTINO
                stockEntry.Quantity += stockMovement.Quantity;
                
                // Actualizamos precio de costo y stock global (Legacy)
                if (stockMovement.MovementType == "PURCHASE")
                {
                    product.Stock += stockMovement.Quantity;
                    product.CostPrice = stockMovement.UnitCost; // Actualiza PPP o Último precio
                }
            }

            // CASO B: SALIDA DE MERCADERÍA (Consumo o Transferencia Saliente)
            // Si hay un SourceWarehouseId, significa que la mercadería SALE de ese depósito.
            if (stockMovement.SourceWarehouseId.HasValue)
            {
                var stockEntry = await _context.ProductStocks
                    .FirstOrDefaultAsync(ps => ps.ProductId == stockMovement.ProductId && ps.WarehouseId == stockMovement.SourceWarehouseId.Value);

                if (stockEntry != null)
                {
                    // --- VALIDACIÓN DE STOCK (CRÍTICA) ---
                    if (stockEntry.Quantity < stockMovement.Quantity)
                    {
                        return BadRequest($"Stock insuficiente en el depósito de origen. Disponible: {stockEntry.Quantity}");
                    }
                    // ------------------------------------

                    // RESTAMOS DEL DEPÓSITO DE ORIGEN
                    stockEntry.Quantity -= stockMovement.Quantity;
                }
                else
                {
                    return BadRequest("El producto no existe en el depósito de origen.");
                }

                // Restamos del global (Legacy) si es un consumo real (no una transferencia)
                if (stockMovement.MovementType == "CONSUMPTION" || stockMovement.MovementType == "DISPATCH")
                {
                    product.Stock -= stockMovement.Quantity;
                }
            }

            await _context.SaveChangesAsync();

            return CreatedAtAction("GetStockMovements", new { id = stockMovement.Id }, stockMovement);
        }
    }
}