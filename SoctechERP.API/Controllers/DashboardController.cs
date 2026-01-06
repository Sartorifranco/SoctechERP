using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Dashboard/kpi
        // Este endpoint es el "Cerebro". Calcula todo en el servidor y devuelve un resumen ligero.
        [HttpGet("kpi")]
        public async Task<ActionResult<object>> GetKPIs()
        {
            var today = DateTime.UtcNow;
            var firstDayMonth = new DateTime(today.Year, today.Month, 1);

            // 1. LIQUIDEZ TOTAL (Caja + Bancos)
            // Sumamos el saldo de todas las billeteras activas.
            var totalCash = await _context.Wallets
                .Where(w => w.IsActive)
                .SumAsync(w => w.Balance);

            // 2. VENTAS DEL MES (Facturación)
            // Sumamos el Bruto de las facturas emitidas desde el día 1 del mes.
            var salesThisMonth = await _context.SalesInvoices
                .Where(i => i.InvoiceDate >= firstDayMonth)
                .SumAsync(i => i.GrossTotal);

            // 3. DEUDA A PROVEEDORES (Cuentas por Pagar)
            // Sumamos facturas que están Aprobadas (Approved) o Flagged, pero NO Pagadas (Paid).
            var debtPending = await _context.SupplierInvoices
                .Where(i => i.Status == "Approved" || i.Status == "Flagged")
                .SumAsync(i => i.TotalAmount);

            // 4. OBRAS ACTIVAS
            var activeProjects = await _context.Projects.CountAsync(p => p.IsActive);

            return Ok(new 
            {
                TotalCash = totalCash,
                SalesMonth = salesThisMonth,
                DebtPending = debtPending,
                ActiveProjects = activeProjects,
                LastUpdate = DateTime.Now
            });
        }
    }
}