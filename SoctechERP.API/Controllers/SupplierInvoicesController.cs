using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SupplierInvoicesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SupplierInvoicesController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<SupplierInvoice>>> GetInvoices()
        {
            return await _context.SupplierInvoices.OrderByDescending(i => i.InvoiceDate).ToListAsync();
        }

        [HttpPost]
        public async Task<ActionResult<SupplierInvoice>> PostInvoice(SupplierInvoice invoice)
        {
            if (invoice.ProviderId == Guid.Empty) return BadRequest("Falta el Proveedor");

            // LÓGICA "3-WAY MATCH"
            if (invoice.RelatedPurchaseOrderId != null)
            {
                var order = await _context.PurchaseOrders.FindAsync(invoice.RelatedPurchaseOrderId);
                if (order != null)
                {
                    // --- CORRECCIÓN CRÍTICA ---
                    // Antes comparaba Total vs Neto (Error). Ahora compara Total vs Total.
                    decimal difference = Math.Abs(order.TotalAmount - invoice.TotalAmount); 
                    
                    // Margen de tolerancia de $1000 por redondeos
                    if (difference > 1000) 
                    {
                        invoice.Status = "Flagged"; // Diferencia de precio -> Observada
                    }
                    else
                    {
                        invoice.Status = "Approved"; // Coincide -> Aprobada
                        order.Status = "Invoiced"; 
                    }
                }
            }
            else 
            {
                invoice.Status = "Approved"; // Sin orden previa -> Aprobada directo
            }

            invoice.Id = Guid.NewGuid();
            _context.SupplierInvoices.Add(invoice);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetInvoices", new { id = invoice.Id }, invoice);
        }
        
        [HttpGet("debt-summary")]
        public async Task<ActionResult<object>> GetDebtSummary()
        {
             var debt = await _context.SupplierInvoices
                                      .Where(i => i.Status == "Approved")
                                      .GroupBy(i => i.ProviderName)
                                      .Select(g => new { 
                                          Provider = g.Key, 
                                          TotalDebt = g.Sum(x => x.TotalAmount),
                                          Count = g.Count()
                                      })
                                      .OrderByDescending(x => x.TotalDebt)
                                      .ToListAsync();
             return debt;
        }
    }
}