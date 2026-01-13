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

        [HttpGet("kpi")]
        public async Task<IActionResult> GetKpis()
        {
            // 1. Total Caja (Suma de todas las billeteras activas)
            var totalCash = await _context.Wallets
                .Where(w => w.IsActive)
                .SumAsync(w => w.Balance);

            // 2. Ventas del Mes (Facturas de venta desde el día 1 del mes actual)
            var firstDayMonth = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1).ToUniversalTime();
            var salesMonth = await _context.SalesInvoices
                .Where(s => s.InvoiceDate >= firstDayMonth)
                .SumAsync(s => s.GrossTotal);

            // 3. Deuda Pendiente (Facturas de proveedor Aprobadas u Observadas que suman deuda)
            // Nota: Aquí podrías filtrar por 'Status' != 'Paid' si tuvieras ese estado
            var debtPending = await _context.SupplierInvoices
                .Where(s => s.Status == "Approved" || s.Status == "Flagged") 
                .SumAsync(s => s.TotalAmount);

            // 4. Obras Activas
            var activeProjects = await _context.Projects
                .CountAsync(p => p.IsActive);

            return Ok(new
            {
                totalCash,
                salesMonth,
                debtPending,
                activeProjects
            });
        }
    }
}