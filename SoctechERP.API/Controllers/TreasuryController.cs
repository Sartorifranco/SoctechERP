using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TreasuryController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TreasuryController(AppDbContext context)
        {
            _context = context;
        }

        // 1. Ver Billeteras y Saldos
        [HttpGet("wallets")]
        public async Task<ActionResult<IEnumerable<Wallet>>> GetWallets()
        {
            return await _context.Wallets.Where(w => w.IsActive).ToListAsync();
        }

        // 2. Crear Nueva Billetera (Ej: "Nueva Cuenta Banco")
        [HttpPost("wallets")]
        public async Task<ActionResult<Wallet>> PostWallet(Wallet wallet)
        {
            wallet.Id = Guid.NewGuid();
            _context.Wallets.Add(wallet);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetWallets", new { id = wallet.Id }, wallet);
        }

        // 3. REGISTRAR MOVIMIENTO (El corazón del sistema)
        [HttpPost("transactions")]
        public async Task<ActionResult<FinancialTransaction>> PostTransaction(FinancialTransaction trx)
        {
            var wallet = await _context.Wallets.FindAsync(trx.WalletId);
            if (wallet == null) return BadRequest("Billetera no encontrada");

            // Validar Saldo si es salida
            if (trx.Type == "EXPENSE" && wallet.Balance < trx.Amount)
            {
                return BadRequest($"Fondos insuficientes en {wallet.Name}. Saldo: {wallet.Balance}");
            }

            // 1. Impactar Saldo
            if (trx.Type == "INCOME") wallet.Balance += trx.Amount;
            else wallet.Balance -= trx.Amount;

            // 2. Guardar Transacción
            trx.Id = Guid.NewGuid();
            trx.WalletName = wallet.Name;
            trx.Date = DateTime.UtcNow;

            _context.FinancialTransactions.Add(trx);

            // 3. (Opcional) Si viene de una factura, actualizar estado a "Paid"
            if (trx.RelatedSupplierInvoiceId != null)
            {
                var inv = await _context.SupplierInvoices.FindAsync(trx.RelatedSupplierInvoiceId);
                if (inv != null) inv.Status = "Paid";
            }
            if (trx.RelatedSalesInvoiceId != null)
            {
                var inv = await _context.SalesInvoices.FindAsync(trx.RelatedSalesInvoiceId);
                if (inv != null) inv.Status = "Paid";
            }

            await _context.SaveChangesAsync();

            return Ok(trx);
        }

        // 4. Ver Movimientos (Últimos 50)
        [HttpGet("transactions")]
        public async Task<ActionResult<IEnumerable<FinancialTransaction>>> GetTransactions()
        {
            return await _context.FinancialTransactions
                                 .OrderByDescending(t => t.Date)
                                 .Take(50)
                                 .ToListAsync();
        }
    }
}