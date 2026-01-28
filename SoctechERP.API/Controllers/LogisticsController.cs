using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LogisticsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public LogisticsController(AppDbContext context)
        {
            _context = context;
        }

        // 1. Listar todos los depósitos activos
        [HttpGet("warehouses")]
        public async Task<IActionResult> GetWarehouses()
        {
            return Ok(await _context.Warehouses.Where(w => w.IsActive).ToListAsync());
        }

        // 2. Crear un nuevo depósito
        [HttpPost("warehouses")]
        public async Task<IActionResult> CreateWarehouse(Warehouse warehouse)
        {
            warehouse.Id = Guid.NewGuid();
            _context.Warehouses.Add(warehouse);
            await _context.SaveChangesAsync();
            return Ok(warehouse);
        }

        // 3. Ver Stock Detallado de un Producto
        [HttpGet("stock-detail/{productId}")]
        public async Task<IActionResult> GetProductStockDetail(Guid productId)
        {
            var stocks = await _context.ProductStocks
                .Include(ps => ps.Warehouse)
                .Where(ps => ps.ProductId == productId && ps.Quantity != 0)
                .Select(ps => new 
                {
                    Depot = ps.Warehouse.Name,
                    Location = ps.Warehouse.Location,
                    Quantity = ps.Quantity
                })
                .ToListAsync();

            var total = stocks.Sum(s => s.Quantity);
            return Ok(new { Total = total, Breakdown = stocks });
        }

        // 4. Ver todo el stock de un Depósito (CORREGIDO)
        [HttpGet("warehouse-inventory/{warehouseId}")]
        public async Task<IActionResult> GetWarehouseInventory(Guid warehouseId)
        {
            var inventory = await _context.ProductStocks
                .Include(ps => ps.Product)
                .Where(ps => ps.WarehouseId == warehouseId && ps.Quantity != 0)
                .Select(ps => new
                {
                    ProductId = ps.ProductId, // <--- CRÍTICO: Agregado para que el frontend no falle
                    Product = ps.Product.Name,
                    Sku = ps.Product.Sku,
                    Quantity = ps.Quantity
                })
                .ToListAsync();

            return Ok(inventory);
        }
    }
}