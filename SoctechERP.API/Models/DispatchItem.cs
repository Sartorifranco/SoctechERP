namespace SoctechERP.API.Models
{
    public class DispatchItem
    {
        public Guid Id { get; set; }
        public Guid ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public double Quantity { get; set; }
        
        // Para conectar con tu dropdown de fases
        public Guid? ProjectPhaseId { get; set; }
        public string ProjectPhaseName { get; set; } = string.Empty;

        public Guid DispatchId { get; set; }
    }
}