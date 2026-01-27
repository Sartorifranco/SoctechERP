using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;
using Microsoft.EntityFrameworkCore;

namespace SoctechERP.API.Services
{
    public class LogisticsService
    {
        private readonly AppDbContext _context;

        public LogisticsService(AppDbContext context)
        {
            _context = context;
        }

        // --- 1. ENTRADA (RECEPCIÓN) + CÁLCULO PPP ---
        public async Task ConfirmReceiptAsync(Guid receiptId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                var receipt = await _context.GoodsReceipts
                                    .Include(r => r.Items)
                                    .FirstOrDefaultAsync(r => r.Id == receiptId);

                if (receipt == null) throw new Exception("Remito no encontrado");
                if (receipt.Status == ReceiptStatus.Confirmed) throw new Exception("Remito ya procesado");

                var po = await _context.PurchaseOrders
                                .Include(p => p.Items)
                                .FirstOrDefaultAsync(p => p.Id == receipt.PurchaseOrderId);

                foreach (var item in receipt.Items)
                {
                    if (item.QuantityReceived > 0)
                    {
                        var poItem = po?.Items.FirstOrDefault(i => i.ProductId == item.ProductId);
                        decimal incomingCost = poItem?.UnitPrice ?? 0;

                        // A. Generar Movimiento Físico
                        var movement = new StockMovement
                        {
                            Id = Guid.NewGuid(),
                            CompanyId = receipt.CompanyId,
                            BranchId = receipt.TargetBranchId,
                            SourceWarehouseId = null,
                            TargetWarehouseId = receipt.TargetWarehouseId,
                            ProductId = item.ProductId,
                            Date = receipt.ReceptionDate,
                            Quantity = item.QuantityReceived,
                            UnitCost = incomingCost,
                            MovementType = StockMovementType.PurchaseReception,
                            Reference = receipt.RemitoNumber,
                            Description = $"Ingreso OC-{po?.OrderNumber}",
                            RelatedGoodsReceiptId = receipt.Id,
                            ProjectId = po?.ProjectId
                        };
                        _context.StockMovements.Add(movement);

                        // B. ACTUALIZACIÓN FINANCIERA (PPP)
                        // Recalculamos el Precio Promedio Ponderado del producto
                        var product = await _context.Products.FindAsync(item.ProductId);
                        if (product != null)
                        {
                            // Fórmula: ((StockActual * CostoActual) + (Entra * CostoEntra)) / (StockActual + Entra)
                            decimal currentTotalVal = product.Stock * product.CostPrice;
                            decimal incomingTotalVal = item.QuantityReceived * incomingCost;
                            decimal newQuantity = product.Stock + item.QuantityReceived;

                            if (newQuantity > 0)
                            {
                                product.CostPrice = (currentTotalVal + incomingTotalVal) / newQuantity;
                            }

                            product.Stock = newQuantity; // Actualizamos caché
                            _context.Products.Update(product);
                        }
                    }
                }

                receipt.Status = ReceiptStatus.Confirmed;
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        // --- 2. SALIDA (VALE DE CONSUMO) ---
        public async Task<StockWithdrawal> ProcessWithdrawalAsync(StockWithdrawal withdrawal)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();

            try
            {
                // Validación de integridad
                if (!withdrawal.Items.Any()) throw new Exception("El vale está vacío.");

                // Generamos número si no viene (Simulado)
                if (string.IsNullOrEmpty(withdrawal.WithdrawalNumber))
                    withdrawal.WithdrawalNumber = $"VALE-{DateTime.UtcNow.Ticks.ToString()[^6..]}";

                // Obtenemos la Sucursal dueña del Depósito
                var warehouse = await _context.Warehouses.FindAsync(withdrawal.WarehouseId);
                Guid branchId = warehouse?.BranchId ?? Guid.Empty;

                foreach (var item in withdrawal.Items)
                {
                    var product = await _context.Products.FindAsync(item.ProductId);
                    if (product == null) throw new Exception($"Producto {item.ProductId} no existe");

                    // 1. Validar Stock
                    if (product.Stock < item.Quantity)
                        throw new Exception($"Stock insuficiente para {product.Name}. Disponible: {product.Stock}");

                    // 2. Validar Seguridad ABC (Híbrido)
                    if (product.RequiresConsumptionControl && withdrawal.ApprovedByUserId == null)
                        throw new Exception($"El producto {product.Name} requiere autorización de Supervisor (Clase A).");

                    // 3. Generar Movimiento de Salida (Gasto)
                    // Usamos el CostPrice actual (que es el PPP calculado en la entrada)
                    decimal costAtExit = product.CostPrice;

                    var movement = new StockMovement
                    {
                        Id = Guid.NewGuid(),
                        BranchId = branchId,
                        SourceWarehouseId = withdrawal.WarehouseId,
                        TargetWarehouseId = null, // Se consume
                        
                        ProductId = item.ProductId,
                        ProjectId = withdrawal.ProjectId,      // Imputación
                        ProjectPhaseId = withdrawal.ProjectPhaseId, 

                        MovementType = StockMovementType.ProjectConsumption,
                        Quantity = item.Quantity * -1, // Negativo
                        UnitCost = costAtExit,
                        
                        Date = withdrawal.WithdrawalDate,
                        Reference = withdrawal.WithdrawalNumber,
                        Description = $"Consumo Obra: {withdrawal.Description}"
                    };

                    _context.StockMovements.Add(movement);

                    // 4. Actualizar Item del Vale (Snapshot financiero)
                    item.UnitCostSnapshot = costAtExit;
                    item.TotalCost = costAtExit * item.Quantity;
                    item.ProductName = product.Name; 

                    // 5. Actualizar Stock Caché
                    product.Stock -= item.Quantity;
                    _context.Products.Update(product);

                    // 6. Actualizar Costo Real de la Fase (Dashboard)
                    var phase = await _context.ProjectPhases.FindAsync(withdrawal.ProjectPhaseId);
                    if (phase != null)
                    {
                        phase.ActualMaterialCost += item.TotalCost;
                        _context.ProjectPhases.Update(phase);
                    }
                }

                _context.StockWithdrawals.Add(withdrawal);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return withdrawal;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}