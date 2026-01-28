using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Controllers
{
    // DTO para recibir datos sin errores de validación
    public class StockMovementDto
    {
        public Guid ProductId { get; set; }
        public Guid BranchId { get; set; }
        public Guid? SourceWarehouseId { get; set; }
        public Guid? TargetWarehouseId { get; set; }
        public string MovementType { get; set; } = string.Empty; // Recibimos texto
        public decimal Quantity { get; set; }
        public decimal UnitCost { get; set; }
        public DateTime Date { get; set; }
        public string Description { get; set; } = string.Empty;
        public string Reference { get; set; } = string.Empty;
    }

    [Route("api/[controller]")]
    [ApiController]
    public class StockMovementsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public StockMovementsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost]
        public async Task<ActionResult<StockMovement>> PostStockMovement(StockMovementDto dto)
        {
            // 1. Convertir String a Enum (Manejo flexible de mayúsculas/minúsculas)
            // Mapeamos "Purchase" -> PurchaseReception y "Transfer" -> StockTransfer para compatibilidad
            StockMovementType movementType;

            if (string.Equals(dto.MovementType, "Purchase", StringComparison.OrdinalIgnoreCase) || 
                string.Equals(dto.MovementType, "PurchaseReception", StringComparison.OrdinalIgnoreCase))
            {
                movementType = StockMovementType.PurchaseReception;
            }
            else if (string.Equals(dto.MovementType, "Transfer", StringComparison.OrdinalIgnoreCase) || 
                     string.Equals(dto.MovementType, "StockTransfer", StringComparison.OrdinalIgnoreCase))
            {
                movementType = StockMovementType.StockTransfer;
            }
            else
            {
                // Intento genérico para otros tipos
                if (!Enum.TryParse(dto.MovementType, true, out movementType))
                {
                    return BadRequest($"Tipo de movimiento '{dto.MovementType}' no válido.");
                }
            }

            // 2. Crear la Entidad
            var movement = new StockMovement
            {
                Id = Guid.NewGuid(),
                ProductId = dto.ProductId,
                BranchId = dto.BranchId,
                SourceWarehouseId = dto.SourceWarehouseId,
                TargetWarehouseId = dto.TargetWarehouseId,
                MovementType = movementType,
                Quantity = dto.Quantity,
                UnitCost = dto.UnitCost,
                Date = dto.Date.ToUniversalTime(),
                Description = dto.Description,
                Reference = dto.Reference
            };

            // 3. Impactar Stock Físico
            using var transaction = await _context.Database.BeginTransactionAsync();
            try 
            {
                // A. Si es RECEPCIÓN DE COMPRA (Suma al destino)
                if (movement.MovementType == StockMovementType.PurchaseReception && movement.TargetWarehouseId.HasValue)
                {
                    await AddStockAsync(movement.ProductId, movement.TargetWarehouseId.Value, movement.Quantity);
                }
                // B. Si es TRANSFERENCIA (Resta origen, Suma destino)
                else if (movement.MovementType == StockMovementType.StockTransfer && movement.SourceWarehouseId.HasValue && movement.TargetWarehouseId.HasValue)
                {
                    await RemoveStockAsync(movement.ProductId, movement.SourceWarehouseId.Value, movement.Quantity);
                    await AddStockAsync(movement.ProductId, movement.TargetWarehouseId.Value, movement.Quantity);
                }
                
                _context.StockMovements.Add(movement);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Movimiento registrado con éxito", id = movement.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { error = ex.Message });
            }
        }

        // Métodos auxiliares
        private async Task AddStockAsync(Guid productId, Guid warehouseId, decimal qty)
        {
            var stock = await _context.ProductStocks
                .FirstOrDefaultAsync(ps => ps.ProductId == productId && ps.WarehouseId == warehouseId);

            if (stock == null)
            {
                stock = new ProductStock { ProductId = productId, WarehouseId = warehouseId, Quantity = 0 };
                _context.ProductStocks.Add(stock);
            }
            stock.Quantity += qty;
        }

        private async Task RemoveStockAsync(Guid productId, Guid warehouseId, decimal qty)
        {
            var stock = await _context.ProductStocks
                .FirstOrDefaultAsync(ps => ps.ProductId == productId && ps.WarehouseId == warehouseId);

            if (stock == null || stock.Quantity < qty)
                throw new Exception("Stock insuficiente en el depósito de origen.");

            stock.Quantity -= qty;
        }
    }
}