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

        // 1. GET: Listar órdenes con sus ítems
        [HttpGet]
        public async Task<ActionResult<IEnumerable<PurchaseOrder>>> GetOrders()
        {
            return await _context.PurchaseOrders
                                 .Include(o => o.Items)
                                 .OrderByDescending(o => o.Date)
                                 .ToListAsync();
        }

        // 2. GET: Obtener una orden específica (Necesario para el CreatedAtAction)
        [HttpGet("{id}")]
        public async Task<ActionResult<PurchaseOrder>> GetOrder(Guid id)
        {
            var order = await _context.PurchaseOrders
                                      .Include(o => o.Items)
                                      .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null) return NotFound();

            return order;
        }

        // 3. POST: Crear nueva orden (Borrador)
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

        // 4. PUT: RECIBIR MERCADERÍA
        [HttpPut("{id}/receive")]
        public async Task<IActionResult> ReceiveOrder(Guid id)
        {
            var order = await _context.PurchaseOrders
                                      .Include(o => o.Items)
                                      .FirstOrDefaultAsync(o => o.Id == id);
            
            if (order == null) return NotFound("Orden no encontrada.");
            if (order.Status == "Received") return BadRequest("Esta orden ya fue recibida.");
            if (order.Items == null || !order.Items.Any()) return BadRequest("La orden no tiene ítems.");

            // A. Cambiar estado
            order.Status = "Received";

            // B. Generar Movimientos de Stock
            foreach (var item in order.Items)
            {
                // 1. Crear el movimiento de entrada
                var movement = new StockMovement
                {
                    ProductId = item.ProductId,
                    ProjectId = null,
                    // CORRECCIÓN 1: Convertimos de double a decimal explícitamente
                    Quantity = (decimal)item.Quantity, 
                    MovementType = "PURCHASE",
                    Date = DateTime.UtcNow,
                    Description = $"Recepción OC: {order.OrderNumber}"
                };
                _context.StockMovements.Add(movement);

                // 2. Actualizar el stock físico del producto
                var product = await _context.Products.FindAsync(item.ProductId);
                if (product != null)
                {
                    // Convertimos la cantidad a double para sumar al stock (si product.Stock es double)
                    // Nota: Si product.Stock es decimal, quita el (double) de abajo.
                    // Asumo que product.Stock es double basado en tus errores previos.
                    product.Stock += item.Quantity;
                    
                    if (item.UnitPrice > 0)
                    {
                        // CORRECCIÓN 2: Convertimos de decimal a double explícitamente
                        product.CostPrice = (double)item.UnitPrice; 
                    }
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Orden recibida y Stock actualizado correctamente", orderId = order.Id });
        }
    }
}