using Microsoft.AspNetCore.Mvc;
using SoctechERP.API.Services;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ScanController : ControllerBase
    {
        private readonly AiInvoiceScanner _scanner;

        public ScanController(AiInvoiceScanner scanner)
        {
            _scanner = scanner;
        }

        [HttpPost("invoice")]
        public async Task<ActionResult> ScanInvoice(IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("No se subió archivo");

            // Llamamos a la Inteligencia Artificial
            var result = await _scanner.ScanInvoice(file);

            if (result == null) return StatusCode(500, "La IA no pudo leer la factura o falta configurar la API Key.");

            return Ok(result);
        }
    }
}