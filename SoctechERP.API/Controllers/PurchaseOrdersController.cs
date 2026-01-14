using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PurchaseOrdersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PurchaseOrdersController(AppDbContext context)
        {
            _context = context;
        }

        // GET: Listar órdenes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<PurchaseOrder>>> GetOrders()
        {
            return await _context.PurchaseOrders
                                 .Include(o => o.Items)
                                 .OrderByDescending(o => o.Date)
                                 .ToListAsync();
        }

        // GET: Obtener una orden
        [HttpGet("{id}")]
        public async Task<ActionResult<PurchaseOrder>> GetOrder(Guid id)
        {
            var order = await _context.PurchaseOrders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id);
            if (order == null) return NotFound();
            return order;
        }

        // POST: Crear orden
        [HttpPost]
        public async Task<ActionResult<PurchaseOrder>> PostOrder(PurchaseOrder order)
        {
            order.OrderNumber = "OC-" + DateTime.Now.ToString("yyMMdd-HHmm");
            order.Status = "Pending";
            order.Date = DateTime.UtcNow;
            _context.PurchaseOrders.Add(order);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
        }

        // PUT: RECIBIR MERCADERÍA (Con Bloqueo de Seguridad)
        [HttpPut("{id}/receive")]
        public async Task<IActionResult> ReceiveOrder(Guid id)
        {
            var order = await _context.PurchaseOrders
                                      .Include(o => o.Items)
                                      .FirstOrDefaultAsync(o => o.Id == id);
            
            if (order == null) return NotFound("Orden no encontrada.");

            // --- CORRECCIÓN CRÍTICA: EL CANDADO ---
            // Si ya está "Finished" (cerrada por factura) o "Received" (ya recibida), ERROR.
            if (order.Status == "Received" || order.Status == "Finished") 
                return BadRequest($"Esta orden ya fue procesada (Estado: {order.Status}). No se puede volver a sumar stock.");
            // --------------------------------------

            if (order.Items == null || !order.Items.Any()) return BadRequest("La orden no tiene ítems.");

            order.Status = "Received";

            foreach (var item in order.Items)
            {
                // 1. Movimiento de Stock
                var movement = new StockMovement
                {
                    ProductId = item.ProductId,
                    ProjectId = null,
                    Quantity = (decimal)item.Quantity, 
                    MovementType = "PURCHASE",
                    Date = DateTime.UtcNow,
                    Description = $"Recepción OC: {order.OrderNumber}"
                };
                _context.StockMovements.Add(movement);

                // 2. Actualizar Stock Físico
                var product = await _context.Products.FindAsync(item.ProductId);
                if (product != null)
                {
                    product.Stock += (decimal)item.Quantity;
                    if (item.UnitPrice > 0) product.CostPrice = item.UnitPrice; 
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Orden recibida y Stock actualizado correctamente", orderId = order.Id });
        }
    }
}