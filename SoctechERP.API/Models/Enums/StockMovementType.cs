namespace SoctechERP.API.Models.Enums
{
    public enum StockMovementType
    {
        InitialBalance,      // Saldo Inicial
        PurchaseReception,   // Recepción de Compra (Antes "Purchase")
        ProjectConsumption,  // Consumo en Obra (Antes "Dispatch")
        StockTransfer,       // Transferencia entre Depósitos (Antes "Transfer")
        Adjustment,          // Ajuste de Inventario
        StockWithdrawal      // Retiro Manual
    }
}