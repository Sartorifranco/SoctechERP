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

        // GET: api/SupplierInvoices (AHORA TRAE INFO DE LA ORDEN DE COMPRA)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetInvoices()
        {
            var invoices = await _context.SupplierInvoices
                .OrderByDescending(i => i.InvoiceDate)
                .Select(i => new 
                {
                    i.Id,
                    i.InvoiceNumber,
                    i.ProviderName,
                    i.InvoiceDate,
                    i.DueDate,
                    i.TotalAmount,
                    i.NetAmount,
                    i.VatAmount,
                    i.Status,
                    i.RelatedPurchaseOrderId,
                    
                    // --- DATOS EXTRA PARA LA COMPARATIVA ---
                    // Buscamos cuánto era el total original de la OC
                    PurchaseOrderTotal = _context.PurchaseOrders
                                         .Where(po => po.Id == i.RelatedPurchaseOrderId)
                                         .Select(po => po.TotalAmount)
                                         .FirstOrDefault(),
                                         
                    // Buscamos el número de la OC
                    PurchaseOrderNumber = _context.PurchaseOrders
                                          .Where(po => po.Id == i.RelatedPurchaseOrderId)
                                          .Select(po => po.OrderNumber)
                                          .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(invoices);
        }

        // POST: api/SupplierInvoices
        [HttpPost]
        public async Task<ActionResult<SupplierInvoice>> PostInvoice(SupplierInvoice invoice)
        {
            if (invoice.ProviderId == Guid.Empty) return BadRequest("Falta el Proveedor");

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
                        invoice.Status = "Flagged"; // OBSERVADA
                    }
                    else
                    {
                        invoice.Status = "Approved"; 
                        order.Status = "Finished";

                        foreach (var item in order.Items)
                        {
                            var product = await _context.Products.FindAsync(item.ProductId);
                            if (product != null)
                            {
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

        // DELETE
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteInvoice(Guid id)
        {
            var invoice = await _context.SupplierInvoices.FindAsync(id);
            if (invoice == null) return NotFound("Factura no encontrada");

            if (invoice.Status == "Approved")
                return BadRequest("No se puede eliminar una factura ya Aprobada. Use Nota de Crédito.");

            _context.SupplierInvoices.Remove(invoice);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Factura eliminada correctamente." });
        }

        // PUT: FORZAR APROBACIÓN
        [HttpPut("{id}/approve")]
        public async Task<IActionResult> ForceApproveInvoice(Guid id)
        {
            var invoice = await _context.SupplierInvoices.FindAsync(id);
            if (invoice == null) return NotFound("Factura no encontrada");

            if (invoice.Status == "Approved")
                return BadRequest("Esta factura ya está aprobada.");

            invoice.Status = "Approved";

            if (invoice.RelatedPurchaseOrderId != null)
            {
                var order = await _context.PurchaseOrders
                                          .Include(po => po.Items)
                                          .FirstOrDefaultAsync(o => o.Id == invoice.RelatedPurchaseOrderId);

                if (order != null)
                {
                    if (order.Status != "Finished")
                    {
                        order.Status = "Finished";
                        foreach (var item in order.Items)
                        {
                            var product = await _context.Products.FindAsync(item.ProductId);
                            if (product != null)
                            {
                                product.Stock += (decimal)item.Quantity;
                                product.CostPrice = item.UnitPrice;
                            }
                        }
                    }
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Factura aprobada manualmente y stock actualizado." });
        }
    }
}