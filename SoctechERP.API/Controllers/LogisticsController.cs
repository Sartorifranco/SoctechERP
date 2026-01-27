using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    // [Authorize] // Descomenta esto cuando quieras activar seguridad full
    public class LogisticsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LogisticsController(AppDbContext context)
        {
            _context = context;
        }

        // --- GESTIÓN DE DEPÓSITOS (ALMACENES / OBRAS / CAMIONETAS) ---

        // 1. Listar todos los depósitos activos
        [HttpGet("warehouses")]
        public async Task<IActionResult> GetWarehouses()
        {
            return Ok(await _context.Warehouses.Where(w => w.IsActive).ToListAsync());
        }

        // 2. Crear un nuevo depósito (Ej: "Pañol Obra Kennedy")
        [HttpPost("warehouses")]
        public async Task<IActionResult> CreateWarehouse(Warehouse warehouse)
        {
            warehouse.Id = Guid.NewGuid();
            _context.Warehouses.Add(warehouse);
            await _context.SaveChangesAsync();
            return Ok(warehouse);
        }

        // --- CONSULTA DE STOCK AVANZADA (MATRIX) ---

        // 3. Ver Stock Detallado de un Producto (¿Dónde está el cemento?)
        [HttpGet("stock-detail/{productId}")]
        public async Task<IActionResult> GetProductStockDetail(Guid productId)
        {
            // Buscamos todas las existencias de ese producto en todos los depósitos
            var stocks = await _context.ProductStocks
                .Include(ps => ps.Warehouse)
                .Where(ps => ps.ProductId == productId && ps.Quantity != 0) // Solo donde hay algo
                .Select(ps => new 
                {
                    Depot = ps.Warehouse.Name,
                    Location = ps.Warehouse.Location,
                    Quantity = ps.Quantity
                })
                .ToListAsync();

            // Calculamos el total general
            var total = stocks.Sum(s => s.Quantity);

            return Ok(new { Total = total, Breakdown = stocks });
        }

        // 4. Ver todo el stock de un Depósito específico (Inventario de Obra)
        [HttpGet("warehouse-inventory/{warehouseId}")]
        public async Task<IActionResult> GetWarehouseInventory(Guid warehouseId)
        {
            var inventory = await _context.ProductStocks
                .Include(ps => ps.Product)
                .Where(ps => ps.WarehouseId == warehouseId && ps.Quantity != 0)
                .Select(ps => new
                {
                    Product = ps.Product.Name,
                    Sku = ps.Product.Sku,
                    Quantity = ps.Quantity
                })
                .ToListAsync();

            return Ok(inventory);
        }
    }
}