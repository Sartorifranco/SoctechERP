using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    // CORRECCIÓN CLAVE: Fijamos la ruta en minúscula para evitar errores 405
    [Route("api/dispatch")]
    [ApiController]
    public class DispatchController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DispatchController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/dispatch (Para ver el historial de remitos si lo necesitas)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Dispatch>>> GetDispatches()
        {
            return await _context.Dispatches
                                 .Include(d => d.Items)
                                 .OrderByDescending(d => d.Date)
                                 .ToListAsync();
        }

        // POST: api/dispatch
        [HttpPost]
        public async Task<ActionResult<Dispatch>> PostDispatch(Dispatch dispatch)
        {
            // 1. Validar que vengan ítems
            if (dispatch.Items == null || !dispatch.Items.Any())
                return BadRequest("Debes seleccionar al menos un producto.");

            // 2. Validar Obra
            var project = await _context.Projects.FindAsync(dispatch.ProjectId);
            if (project == null) return BadRequest("La obra seleccionada no existe.");

            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                // Completar datos del encabezado
                dispatch.Id = Guid.NewGuid();
                dispatch.DispatchNumber = "REM-" + DateTime.Now.ToString("yyMMdd-HHmm");
                dispatch.Date = DateTime.UtcNow;
                dispatch.ProjectName = project.Name;

                foreach (var item in dispatch.Items)
                {
                    // 3. Buscar Producto
                    var product = await _context.Products.FindAsync(item.ProductId);
                    if (product == null) throw new Exception($"Producto no encontrado ID: {item.ProductId}");

                    // 4. Validar Stock
                    if (product.Stock < item.Quantity)
                        throw new Exception($"Stock insuficiente para '{product.Name}'. Disponible: {product.Stock}");

                    // 5. Restar Stock
                    product.Stock -= item.Quantity;

                    // 6. Validar nombre de la Fase (Cosmético para el historial)
                    string phaseName = !string.IsNullOrEmpty(item.ProjectPhaseName) 
                                       ? item.ProjectPhaseName 
                                       : "General";

                    // 7. Generar Movimiento (StockMovement)
                    var movement = new StockMovement
                    {
                        ProductId = item.ProductId,
                        ProjectId = dispatch.ProjectId, // Imputado a la obra
                        
                        // Cantidad negativa = Salida. Convertimos double a decimal.
                        Quantity = -1 * (decimal)item.Quantity, 
                        
                        MovementType = "DISPATCH",
                        Date = DateTime.UtcNow,
                        
                        // Guardamos la Nota y la Fase en la descripción
                        Description = $"Salida a {project.Name} ({phaseName}) - {dispatch.Note}"
                    };
                    
                    _context.StockMovements.Add(movement);

                    // Vincular IDs internos del ítem
                    item.DispatchId = dispatch.Id;
                    item.ProductName = product.Name;
                }

                _context.Dispatches.Add(dispatch);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Salida registrada correctamente", dispatchId = dispatch.Id, dispatchNumber = dispatch.DispatchNumber });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { error = ex.Message });
            }
        }
    }
}