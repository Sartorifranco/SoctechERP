using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SalesInvoicesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SalesInvoicesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: Historial de Facturación
        [HttpGet]
        public async Task<ActionResult<IEnumerable<SalesInvoice>>> GetSalesInvoices()
        {
            return await _context.SalesInvoices.OrderByDescending(x => x.InvoiceDate).ToListAsync();
        }

        // POST: Emitir Factura (Cálculo Automático)
        [HttpPost]
        public async Task<ActionResult<SalesInvoice>> PostSalesInvoice(SalesInvoice invoice)
        {
            // 1. Validar Obra
            var project = await _context.Projects.FindAsync(invoice.ProjectId);
            if (project != null)
            {
                invoice.ProjectName = project.Name;
            }

            // 2. LÓGICA FINANCIERA AUTOMÁTICA
            // El usuario manda el Neto. Nosotros calculamos el resto.
            
            // A. IVA
            invoice.VatAmount = invoice.NetAmount * (invoice.VatPercentage / 100);
            
            // B. Total de la Factura (Legal)
            invoice.GrossTotal = invoice.NetAmount + invoice.VatAmount;

            // C. Fondo de Reparo (Retención de Garantía)
            // OJO: El fondo se calcula sobre el Neto o el Bruto según contrato.
            // Estándar "Pro": Se calcula sobre el Neto habitualmente, pero lo haremos sobre Bruto si es simple.
            // Vamos a hacerlo sobre el Neto para ser precisos.
            if (invoice.RetainagePercentage > 0)
            {
                invoice.RetainageAmount = invoice.NetAmount * (invoice.RetainagePercentage / 100);
            }
            else
            {
                invoice.RetainageAmount = 0;
            }

            // D. Monto a Cobrar (Lo que entra al banco)
            // Total Factura - Fondo de Reparo
            invoice.CollectibleAmount = invoice.GrossTotal - invoice.RetainageAmount;

            // 3. Simulación de AFIP (CAE)
            invoice.InvoiceNumber = new Random().Next(100, 9999).ToString("D8"); // Simula número 00000123
            invoice.CAE = "74123456789123"; // Simulado
            invoice.VtoCAE = DateTime.Now.AddDays(10);

            _context.SalesInvoices.Add(invoice);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetSalesInvoices", new { id = invoice.Id }, invoice);
        }

        // BI: ¿Cuánto dinero tenemos retenido en la calle? (Fondo de Reparo acumulado)
        [HttpGet("retained-balance")]
        public async Task<ActionResult<decimal>> GetTotalRetained()
        {
            return await _context.SalesInvoices.SumAsync(x => x.RetainageAmount);
        }
    }
}