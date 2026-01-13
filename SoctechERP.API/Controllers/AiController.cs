using Microsoft.AspNetCore.Mvc;
using SoctechERP.API.Services;

namespace SoctechERP.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AiController : ControllerBase
    {
        private readonly AiAssistant _aiAssistant;
        private readonly AiInvoiceScanner _scanner;

        // INYECCIÓN DE DEPENDENCIAS:
        // Aquí recibimos los servicios que registraste en Program.cs
        public AiController(AiAssistant aiAssistant, AiInvoiceScanner scanner)
        {
            _aiAssistant = aiAssistant;
            _scanner = scanner;
        }

        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] ChatRequest request)
        {
            if (string.IsNullOrEmpty(request.Question))
                return BadRequest("La pregunta no puede estar vacía.");

            // Llamamos a Jarvis
            var response = await _aiAssistant.AskJarvis(request.Question);
            return Ok(new { answer = response });
        }

        [HttpPost("scan-invoice")]
        public async Task<IActionResult> ScanInvoice(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("No se subió ninguna imagen.");

            var result = await _scanner.ScanInvoice(file);
            
            if (result == null)
                return StatusCode(500, "La IA no pudo leer la factura. Intenta con una imagen más clara.");

            return Ok(result);
        }
    }

    public class ChatRequest
    {
        public string Question { get; set; } = string.Empty;
    }
}