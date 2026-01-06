using System.ComponentModel.DataAnnotations;

namespace SoctechERP.API.Models
{
    public class Dispatch
    {
        public Guid Id { get; set; }
        public string DispatchNumber { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public Guid ProjectId { get; set; }
        public string ProjectName { get; set; } = string.Empty;
        public string? Note { get; set; }
        public List<DispatchItem> Items { get; set; } = new();
    }
}