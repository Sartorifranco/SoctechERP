namespace SoctechERP.API.Models.Enums
{
    // --- TUS ENUMS EXISTENTES (Se mantienen) ---
    public enum UnionType { UOCRA, UECARA, COMERCIO, FUERA_CONVENIO }
    public enum PayFrequency { Quincenal, Mensual }

    // --- NUEVOS ENUMS PARA EL MOTOR FINANCIERO (Nivel NetSuite) ---
    
    // Máquina de Estados de la Factura
    public enum InvoiceStatus
    {
        Draft,              // 0: Borrador / Carga inicial
        MatchingPending,    // 1: El sistema está validando vs OC y Remito
        MatchedOK,          // 2: Coincidencia Perfecta (Pasa a Cuentas a Pagar)
        
        BlockedByVariance,  // 3: 🛑 BLOQUEADA (Diferencia de precio/cantidad detectada)
        
        ApprovedByManager,  // 4: ✅ Gerencia autorizó el desvío manualmente
        Posted,             // 5: Contabilizada en Libro Mayor
        Voided              // 6: Anulada
    }

    // Tipos de discrepancias para auditoría
    public enum VarianceType
    {
        Price,      // Precio Factura > Precio Orden Compra
        Quantity,   // Cantidad Factura > Cantidad Recibida (Remito)
        Tax,        // Error de cálculo de impuestos
        TotalAmount // Diferencia matemática global
    }

    // Tipos de Sucursales (Para organizar tus depósitos)
    public enum BranchType
    {
        Headquarters, // Oficina Central
        Warehouse,    // Depósito Central
        ProjectSite   // Obrador / Depósito de Obra (Temporal)
    }

    public enum ReceiptStatus
    {
        Draft,      // 0: El capataz está contando (en Tablet)
        Confirmed,  // 1: Firmado y Stock impactado (Inmutable)
        Voided      // 2: Anulado por error administrativo
    }

    public enum StockMovementType
    {
        // 📥 ENTRADAS
        PurchaseReception,   // Ingreso por Compra (Proveedor -> Obra)
        TransferIn,          // Entrada desde otra Obra
        AdjustmentIn,        // Sobrante de inventario
        ReturnFromProject,   // Devolución de materiales sobrantes

        // 📤 SALIDAS
        ProjectConsumption,  // Consumo en Obra (El Activo se vuelve Costo)
        TransferOut,         // Salida a otra Obra
        AdjustmentOut,       // Faltante / Robo
        ReturnToProvider     // Devolución a proveedor (falla de calidad)
    }

    public enum QualityCondition
    {
        Good,       // Ok
        Damaged,    // Roto/Dañado (Entra a Cuarentena)
        WrongItem,  // Producto incorrecto
        Missing     // Faltante (Estaba en remito papel pero no bajó)
    }
}