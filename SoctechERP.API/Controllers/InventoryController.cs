using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Services;
using System.Security.Claims;

namespace SoctechERP.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class InventoryController : ControllerBase
    {
        private readonly LogisticsService _logisticsService;
        private readonly AppDbContext _context;

        public InventoryController(LogisticsService logisticsService, AppDbContext context)
        {
            _logisticsService = logisticsService;
            _context = context;
        }

        // POST: api/Inventory/withdraw
        // Acción: Generar Vale de Salida (Descuenta stock e imputa costo a obra)
        [HttpPost("withdraw")]
        public async Task<IActionResult> CreateWithdrawal([FromBody] StockWithdrawal withdrawal)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                // Auditoría: Forzamos el usuario del Token si no viene
                // var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                // if (Guid.TryParse(userId, out Guid uid)) withdrawal.RequestedByUserId = uid;

                var result = await _logisticsService.ProcessWithdrawalAsync(withdrawal);
                return Ok(new { Message = "Vale procesado exitosamente.", ValeNumber = result.WithdrawalNumber });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // GET: api/Inventory/stock/{warehouseId}
        // Acción: Ver qué hay en el depósito antes de pedir
        [HttpGet("stock/{warehouseId}")]
        public async Task<IActionResult> GetStock(Guid warehouseId)
        {
            var stock = await _context.Products
                .Where(p => p.Stock > 0 && p.IsActive)
                .Select(p => new {
                    p.Id,
                    p.Name,
                    p.Sku,
                    p.Stock,
                    // UnitPrice // Ojo, no mostramos CostPrice al capataz por seguridad
                })
                .ToListAsync();

            return Ok(stock);
        }
    }
}