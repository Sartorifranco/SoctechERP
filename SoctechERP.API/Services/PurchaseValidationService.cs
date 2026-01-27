using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;
using Microsoft.EntityFrameworkCore;

namespace SoctechERP.API.Services
{
    public class PurchaseValidationService
    {
        private readonly AppDbContext _context;
        private const decimal TOLERANCE_PERCENT = 0.02m; // 2% tolerancia automática

        public PurchaseValidationService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<InvoiceStatus> ValidateInvoiceAsync(Guid invoiceId)
        {
            var invoice = await _context.SupplierInvoices
                                .Include(i => i.Items)
                                .FirstOrDefaultAsync(i => i.Id == invoiceId);

            if (invoice == null) throw new Exception("Factura no encontrada");

            // Si no hay OC vinculada, la aprobamos (ej: Factura de Luz)
            if (invoice.RelatedPurchaseOrderId == null)
            {
                invoice.Status = InvoiceStatus.MatchedOK;
                await _context.SaveChangesAsync();
                return invoice.Status;
            }

            // Traemos la Orden de Compra para comparar precios
            var po = await _context.PurchaseOrders
                        .Include(p => p.Items)
                        .FirstOrDefaultAsync(p => p.Id == invoice.RelatedPurchaseOrderId);

            if (po != null)
            {
                // Limpiamos errores viejos (re-intento)
                var oldExceptions = _context.InvoiceExceptions.Where(e => e.SupplierInvoiceId == invoiceId);
                _context.InvoiceExceptions.RemoveRange(oldExceptions);

                bool hasBlockingErrors = false;

                foreach (var itemFactura in invoice.Items)
                {
                    // Buscamos coincidencia por Producto
                    var itemOC = po.Items.FirstOrDefault(p => p.ProductId == itemFactura.ProductId);

                    if (itemOC != null)
                    {
                        // LÓGICA 3-WAY MATCH
                        decimal maxPrice = itemOC.UnitPrice * (1 + TOLERANCE_PERCENT);

                        if (itemFactura.UnitPrice > maxPrice)
                        {
                            hasBlockingErrors = true;
                            decimal diff = itemFactura.UnitPrice - itemOC.UnitPrice;
                            decimal impact = diff * itemFactura.Quantity;

                            _context.InvoiceExceptions.Add(new InvoiceException
                            {
                                Id = Guid.NewGuid(),
                                SupplierInvoiceId = invoice.Id,
                                Type = VarianceType.Price,
                                ItemName = itemFactura.Description,
                                ExpectedValue = itemOC.UnitPrice,
                                ActualValue = itemFactura.UnitPrice,
                                VarianceTotalAmount = impact,
                                Description = $"Precio excede tolerancia. Impacto: ${impact}"
                            });
                        }
                    }
                }

                invoice.Status = hasBlockingErrors ? InvoiceStatus.BlockedByVariance : InvoiceStatus.MatchedOK;
            }

            await _context.SaveChangesAsync();
            return invoice.Status;
        }

        public async Task ApproveExceptionAsync(Guid exceptionId, string userId, string comments)
        {
            var exception = await _context.InvoiceExceptions.FindAsync(exceptionId);
            if (exception == null) return;

            exception.IsResolved = true;
            if (Guid.TryParse(userId, out Guid uid)) exception.ResolvedByUserId = uid;
            exception.ResolvedAt = DateTime.UtcNow;
            exception.ManagerComment = comments;

            // Verificamos si quedan más problemas pendientes
            bool pendingIssues = await _context.InvoiceExceptions
                .AnyAsync(e => e.SupplierInvoiceId == exception.SupplierInvoiceId && !e.IsResolved);

            if (!pendingIssues)
            {
                var invoice = await _context.SupplierInvoices.FindAsync(exception.SupplierInvoiceId);
                if(invoice != null) invoice.Status = InvoiceStatus.ApprovedByManager;
            }

            await _context.SaveChangesAsync();
        }
    }
}