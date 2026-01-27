using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;
using SoctechERP.API.Services;
using System.Security.Claims;

namespace SoctechERP.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class GoodsReceiptController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly LogisticsService _logisticsService;

        public GoodsReceiptController(AppDbContext context, LogisticsService logisticsService)
        {
            _context = context;
            _logisticsService = logisticsService;
        }

        // --- 1. ¿QUÉ ESPERAMOS RECIBIR? (Ayuda al Capataz) ---
        // GET: api/GoodsReceipt/pending-po
        // Muestra órdenes de compra recientes para facilitar la carga
        [HttpGet("pending-po")]
        public async Task<IActionResult> GetPendingPurchaseOrders()
        {
            var orders = await _context.PurchaseOrders
                .OrderByDescending(p => p.Date)
                .Take(20) // Traemos las últimas 20 para no saturar la tablet
                .Select(p => new {
                    p.Id,
                    p.OrderNumber,
                    // p.ProviderName, // Descomentar si tenés este campo en tu modelo PurchaseOrder
                    p.Date,
                    ItemsCount = p.Items.Count
                })
                .ToListAsync();

            return Ok(orders);
        }

        // --- 2. BORRADOR (MIENTRAS BAJAN EL CAMIÓN) ---
        // POST: api/GoodsReceipt
        [HttpPost]
        public async Task<IActionResult> CreateDraft([FromBody] GoodsReceipt receipt)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                // Auditoría: Identificamos quién recibe la carga
                var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (Guid.TryParse(userIdStr, out Guid userId)) receipt.ReceivedByUserId = userId;

                receipt.Status = ReceiptStatus.Draft; // Siempre nace como borrador
                receipt.ReceptionDate = DateTime.UtcNow;

                // Aseguramos IDs
                if (receipt.Id == Guid.Empty) receipt.Id = Guid.NewGuid();
                foreach (var item in receipt.Items)
                {
                    if (item.Id == Guid.Empty) item.Id = Guid.NewGuid();
                    item.GoodsReceiptId = receipt.Id;
                }

                _context.GoodsReceipts.Add(receipt);
                await _context.SaveChangesAsync();

                // Devolvemos el ID para que la tablet pueda seguir agregando items
                return Ok(new { Message = "Borrador creado.", Id = receipt.Id });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // --- 3. CONFIRMACIÓN (FIRMA DIGITAL) ---
        // POST: api/GoodsReceipt/{id}/confirm
        // Acción CRÍTICA: Dispara el Motor Logístico (Mueve Stock + Calcula PPP)
        [HttpPost("{id}/confirm")]
        public async Task<IActionResult> ConfirmReceipt(Guid id)
        {
            try
            {
                await _logisticsService.ConfirmReceiptAsync(id);
                return Ok(new { Message = "Recepción confirmada. Stock actualizado y valorizado." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // --- 4. EVIDENCIA (FOTO) ---
        [HttpPost("{id}/evidence")]
        public async Task<IActionResult> UploadEvidence(Guid id, [FromBody] string photoUrl)
        {
            var receipt = await _context.GoodsReceipts.FindAsync(id);
            if (receipt == null) return NotFound();

            receipt.EvidencePhotoUrl = photoUrl;
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Evidencia adjuntada." });
        }
    }
}