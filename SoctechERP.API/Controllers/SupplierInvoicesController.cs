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

        // GET: api/SupplierInvoices
        [HttpGet]
        public async Task<ActionResult<IEnumerable<SupplierInvoice>>> GetInvoices()
        {
            return await _context.SupplierInvoices.OrderByDescending(i => i.InvoiceDate).ToListAsync();
        }

        // POST: api/SupplierInvoices
        [HttpPost]
        public async Task<ActionResult<SupplierInvoice>> PostInvoice(SupplierInvoice invoice)
        {
            if (invoice.ProviderId == Guid.Empty) return BadRequest("Falta el Proveedor");

            // 1. LÓGICA "3-WAY MATCH"
            if (invoice.RelatedPurchaseOrderId != null)
            {
                var order = await _context.PurchaseOrders
                                          .Include(po => po.Items) 
                                          .FirstOrDefaultAsync(o => o.Id == invoice.RelatedPurchaseOrderId);

                if (order != null)
                {
                    decimal difference = Math.Abs(order.TotalAmount - invoice.TotalAmount); 
                    
                    if (difference > 1000) 
                    {
                        invoice.Status = "Flagged"; // Diferencia de precio
                    }
                    else
                    {
                        // --- ACTUALIZACIÓN DE STOCK AUTOMÁTICA ---
                        invoice.Status = "Approved"; 
                        order.Status = "Finished";

                        foreach (var item in order.Items)
                        {
                            var product = await _context.Products.FindAsync(item.ProductId);
                            if (product != null)
                            {
                                // CORRECCIÓN 1: Usamos .Stock (coincide con el modelo)
                                // CORRECCIÓN 2: Agregamos (decimal) para evitar el error de tipos
                                product.Stock += (decimal)item.Quantity; 
                                
                                product.CostPrice = item.UnitPrice; 
                            }
                        }
                    }
                }
            }
            else 
            {
                invoice.Status = "Approved"; 
            }

            invoice.Id = Guid.NewGuid();
            _context.SupplierInvoices.Add(invoice);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetInvoices", new { id = invoice.Id }, invoice);
        }
        
        // DASHBOARD
        [HttpGet("debt-summary")]
        public async Task<ActionResult<object>> GetDebtSummary()
        {
             var debt = await _context.SupplierInvoices
                                      .Where(i => i.Status == "Approved" || i.Status == "Flagged")
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