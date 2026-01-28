using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;

namespace SoctechERP.API.Controllers
{
    public class StockMovementDto
    {
        public Guid ProductId { get; set; }
        public Guid BranchId { get; set; }
        public Guid? SourceWarehouseId { get; set; }
        public Guid? TargetWarehouseId { get; set; }
        
        // Campos nuevos para ERP de Costos
        public Guid? ProjectId { get; set; }
        public Guid? ProjectPhaseId { get; set; }

        public string MovementType { get; set; } = string.Empty;
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
            // 1. Parsing robusto del Enum (Admite "Purchase", "Consumption", etc.)
            StockMovementType movementType;
            if (Enum.TryParse(dto.MovementType, true, out StockMovementType parsed))
            {
                movementType = parsed;
            }
            else if (string.Equals(dto.MovementType, "Consumption", StringComparison.OrdinalIgnoreCase))
            {
                movementType = StockMovementType.ProjectConsumption;
            }
            else
            {
                return BadRequest($"Tipo de movimiento '{dto.MovementType}' no reconocido.");
            }

            var movement = new StockMovement
            {
                Id = Guid.NewGuid(),
                ProductId = dto.ProductId,
                BranchId = dto.BranchId,
                SourceWarehouseId = dto.SourceWarehouseId,
                TargetWarehouseId = dto.TargetWarehouseId,
                ProjectId = dto.ProjectId,          // Imputación de Obra
                ProjectPhaseId = dto.ProjectPhaseId, // Imputación de Fase
                MovementType = movementType,
                Quantity = dto.Quantity,
                UnitCost = dto.UnitCost,
                Date = dto.Date.ToUniversalTime(),
                Description = dto.Description,
                Reference = dto.Reference
            };

            using var transaction = await _context.Database.BeginTransactionAsync();
            try 
            {
                // A. RECEPCIÓN (Suma)
                if (movementType == StockMovementType.PurchaseReception && movement.TargetWarehouseId.HasValue)
                {
                    await AddStockAsync(movement.ProductId, movement.TargetWarehouseId.Value, movement.Quantity);
                }
                // B. TRANSFERENCIA (Resta Origen -> Suma Destino)
                else if (movementType == StockMovementType.StockTransfer && movement.SourceWarehouseId.HasValue && movement.TargetWarehouseId.HasValue)
                {
                    await RemoveStockAsync(movement.ProductId, movement.SourceWarehouseId.Value, movement.Quantity);
                    await AddStockAsync(movement.ProductId, movement.TargetWarehouseId.Value, movement.Quantity);
                }
                // C. CONSUMO DE OBRA (Resta Origen -> Gasto) <--- ¡ESTO FALTABA!
                else if (movementType == StockMovementType.ProjectConsumption && movement.SourceWarehouseId.HasValue)
                {
                    await RemoveStockAsync(movement.ProductId, movement.SourceWarehouseId.Value, movement.Quantity);
                    
                    // Aquí en el futuro agregaremos la lógica que suma $$$ a la tabla de Costos del Proyecto
                }
                
                _context.StockMovements.Add(movement);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Movimiento registrado correctamente", id = movement.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { error = ex.Message });
            }
        }

        private async Task AddStockAsync(Guid productId, Guid warehouseId, decimal qty)
        {
            var stock = await _context.ProductStocks.FirstOrDefaultAsync(ps => ps.ProductId == productId && ps.WarehouseId == warehouseId);
            if (stock == null) {
                stock = new ProductStock { ProductId = productId, WarehouseId = warehouseId, Quantity = 0 };
                _context.ProductStocks.Add(stock);
            }
            stock.Quantity += qty;
        }

        private async Task RemoveStockAsync(Guid productId, Guid warehouseId, decimal qty)
        {
            var stock = await _context.ProductStocks.FirstOrDefaultAsync(ps => ps.ProductId == productId && ps.WarehouseId == warehouseId);
            if (stock == null || stock.Quantity < qty) throw new Exception($"Stock insuficiente. Disponible: {stock?.Quantity ?? 0}");
            stock.Quantity -= qty;
        }
    }
}