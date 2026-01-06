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
        // CORRECCIÓN AQUÍ: StockMovement (singular)
        public async Task<ActionResult<IEnumerable<StockMovement>>> GetStockMovements()
        {
            // Retorna los últimos 100 movimientos ordenados por fecha
            return await _context.StockMovements
                                 .OrderByDescending(m => m.Date)
                                 .Take(100)
                                 .ToListAsync();
        }
    }
}