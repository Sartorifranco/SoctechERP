using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;
using Microsoft.EntityFrameworkCore;

namespace SoctechERP.API.Services
{
    public class PurchaseValidationService
    {
        private readonly AppDbContext _context;
        private const decimal TOLERANCE_PERCENT = 0.02m; // 2% de tolerancia automática

        public PurchaseValidationService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<InvoiceStatus> ValidateInvoiceAsync(int invoiceId)
        {
            var invoice = await _context.SupplierInvoices
                                .Include(i => i.Items)
                                .Include(i => i.PurchaseOrder)
                                .ThenInclude(po => po.Items)
                                .FirstOrDefaultAsync(i => i.Id == invoiceId);

            if (invoice == null) throw new Exception("Factura no encontrada");

            // Limpiamos excepciones previas por si se está re-intentando
            var oldExceptions = _context.InvoiceExceptions.Where(e => e.SupplierInvoiceId == invoiceId);
            _context.InvoiceExceptions.RemoveRange(oldExceptions);

            bool hasBlockingErrors = false;

            // Recorremos cada línea de la factura
            foreach (var itemFactura in invoice.Items)
            {
                // Buscamos la línea original de la Orden de Compra por Producto
                var itemOC = invoice.PurchaseOrder?.Items
                    .FirstOrDefault(p => p.ProductId == itemFactura.ProductId);

                if (itemOC != null)
                {
                    // 1. VALIDACIÓN DE PRECIO (Con Tolerancia)
                    decimal maxPrice = itemOC.UnitPrice * (1 + TOLERANCE_PERCENT);

                    if (itemFactura.UnitPrice > maxPrice)
                    {
                        hasBlockingErrors = true;
                        
                        // Calculamos el impacto real en dinero (Unitario x Cantidad)
                        decimal unitDiff = itemFactura.UnitPrice - itemOC.UnitPrice;
                        decimal totalImpact = unitDiff * itemFactura.Quantity;

                        _context.InvoiceExceptions.Add(new InvoiceException
                        {
                            SupplierInvoiceId = invoice.Id,
                            Type = VarianceType.Price,
                            ItemName = itemFactura.ProductName ?? "Producto ID " + itemFactura.ProductId,
                            ExpectedValue = itemOC.UnitPrice,
                            ActualValue = itemFactura.UnitPrice,
                            VarianceTotalAmount = totalImpact,
                            Description = $"Diferencia de precio > {TOLERANCE_PERCENT * 100}%. Impacto total: ${totalImpact}"
                        });
                    }
                }
            }

            // Definimos el estado final
            if (hasBlockingErrors)
            {
                invoice.Status = InvoiceStatus.BlockedByVariance;
            }
            else
            {
                invoice.Status = InvoiceStatus.MatchedOK;
            }

            await _context.SaveChangesAsync();
            return invoice.Status;
        }

        // Método para que VOS (Gerente) apruebes la excepción
        public async Task ApproveExceptionAsync(int exceptionId, string userId, string comments)
        {
            var exception = await _context.InvoiceExceptions.FindAsync(exceptionId);
            if (exception == null) return;

            exception.IsResolved = true;
            exception.ResolvedByUserId = userId;
            exception.ResolvedAt = DateTime.UtcNow;
            exception.ManagerComment = comments;

            // Si no quedan más excepciones pendientes, liberamos la factura
            bool pendingIssues = await _context.InvoiceExceptions
                .AnyAsync(e => e.SupplierInvoiceId == exception.SupplierInvoiceId && !e.IsResolved);

            if (!pendingIssues)
            {
                var invoice = await _context.SupplierInvoices.FindAsync(exception.SupplierInvoiceId);
                invoice.Status = InvoiceStatus.ApprovedByManager;
            }

            await _context.SaveChangesAsync();
        }
    }
}