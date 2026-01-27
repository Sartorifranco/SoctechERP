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
    public class SupplierInvoicesController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly PurchaseValidationService _validationService;

        public SupplierInvoicesController(AppDbContext context, PurchaseValidationService validationService)
        {
            _context = context;
            _validationService = validationService;
        }

        // --- A. DATA ENTRY (CARGA DE FACTURAS) ---

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SupplierInvoice invoice)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                // 1. Configuración Inicial
                invoice.Id = Guid.NewGuid();
                invoice.CreatedAt = DateTime.UtcNow;
                
                var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (Guid.TryParse(userIdStr, out Guid userId)) invoice.CreatedByUserId = userId;

                // Asignamos IDs a los items
                foreach(var item in invoice.Items)
                {
                    item.Id = Guid.NewGuid();
                    item.SupplierInvoiceId = invoice.Id;
                }
                
                _context.SupplierInvoices.Add(invoice);
                await _context.SaveChangesAsync();

                // 2. DISPARAR VALIDACIÓN AUTOMÁTICA (3-Way Match)
                var finalStatus = await _validationService.ValidateInvoiceAsync(invoice.Id);

                return Ok(new 
                { 
                    Message = "Factura procesada.", 
                    InvoiceId = invoice.Id,
                    Status = finalStatus.ToString(), // "MatchedOK" o "BlockedByVariance"
                    Warning = finalStatus == InvoiceStatus.BlockedByVariance ? "⚠️ BLOQUEADA por diferencia de precio." : null
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }

        // --- B. DASHBOARD GERENCIAL (ALERTAS) ---

        // Endpoint para tu Widget "Alertas de Compra"
        [HttpGet("blocked")]
        public async Task<IActionResult> GetBlockedInvoices()
        {
            var blocked = await _context.SupplierInvoices
                .Where(i => i.Status == InvoiceStatus.BlockedByVariance)
                .Include(i => i.Exceptions) // Traemos el detalle del error
                .OrderByDescending(i => i.TotalAmount)
                .Select(i => new {
                    i.Id,
                    i.InvoiceNumber,
                    i.ProviderName,
                    i.TotalAmount,
                    // Resumen para la tarjeta visual del Dashboard
                    VarianceAmount = i.Exceptions.Sum(e => e.VarianceTotalAmount),
                    MainCause = i.Exceptions.FirstOrDefault() != null ? i.Exceptions.FirstOrDefault().Description : "Varios errores"
                })
                .ToListAsync();

            return Ok(blocked);
        }

        // Acción Gerencial: Aprobar un desvío ("Pagar igual")
        [HttpPost("approve-exception/{exceptionId}")]
        public async Task<IActionResult> ApproveVariance(Guid exceptionId, [FromBody] string managerComments)
        {
            try
            {
                var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "SYSTEM";
                
                await _validationService.ApproveExceptionAsync(exceptionId, userIdStr, managerComments);
                
                return Ok(new { Message = "Desvío autorizado. La factura será re-evaluada." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }
    }
}