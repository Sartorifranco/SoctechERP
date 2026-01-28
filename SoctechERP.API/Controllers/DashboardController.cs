using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models.Enums; 

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
            // 1. Total Caja
            var totalCash = await _context.Wallets.SumAsync(w => w.Balance);

            // 2. Ventas del Mes
            var startOfMonth = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1).ToUniversalTime();
            
            // CORRECCIÓN: Usamos 'InvoiceDate' que es la propiedad correcta en tu modelo
            var salesMonth = await _context.SalesInvoices
                .Where(s => s.InvoiceDate >= startOfMonth) 
                .SumAsync(s => s.GrossTotal);

            // 3. Deuda Pendiente
            var debtPending = await _context.SupplierInvoices
                .Where(i => i.Status == InvoiceStatus.MatchedOK || i.Status == InvoiceStatus.ApprovedByManager)
                .SumAsync(i => i.TotalAmount);

            // 4. Obras Activas
            var activeProjects = await _context.Projects.CountAsync(p => p.IsActive);

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