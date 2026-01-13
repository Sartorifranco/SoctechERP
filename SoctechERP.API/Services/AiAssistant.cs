using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;

namespace SoctechERP.API.Services
{
    public class AiAssistant
    {
        private readonly AppDbContext _context;
        // TU CLAVE QUE SABEMOS QUE FUNCIONA
        private readonly string _apiKey = "AIzaSyAfjsPjApA__1GkGPHD4nZL_med05sWItw";

        public AiAssistant(AppDbContext context)
        {
            _context = context;
        }

        public async Task<string> AskJarvis(string userQuestion)
        {
            // 1. INTENTAR OBTENER DATOS DEL ERP (BLINDADO)
            string contextText = "No hay datos del sistema disponibles por error de BD.";
            try 
            {
                var totalCash = await _context.Wallets.SumAsync(w => w.Balance);
                var activeProjects = await _context.Projects.CountAsync(p => p.IsActive);
                contextText = $"Caja actual: ${totalCash:N2}. Obras activas: {activeProjects}.";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ADVERTENCIA DB]: No se pudo leer la base de datos: {ex.Message}");
                // No retornamos error, seguimos adelante para que al menos la IA responda el saludo
            }

            // 2. LLAMAR A GOOGLE
            try 
            {
                // URL QUE CONFIRMAMOS QUE FUNCIONA
                string url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={_apiKey}";
                
                var requestBody = new
                {
                    contents = new[]
                    {
                        new { parts = new[] { new { text = $"Eres el asistente de Soctech ERP. {contextText}\n\nUsuario: {userQuestion}" } } }
                    }
                };

                using var client = new HttpClient();
                var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

                var response = await client.PostAsync(url, content);
                var jsonString = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    Console.WriteLine($"[ERROR IA HTTP] {response.StatusCode}: {jsonString}");
                    return $"Error de conexión con Google ({response.StatusCode}).";
                }

                using var doc = JsonDocument.Parse(jsonString);
                if (doc.RootElement.TryGetProperty("candidates", out var candidates) && candidates.GetArrayLength() > 0)
                {
                    return candidates[0].GetProperty("content").GetProperty("parts")[0].GetProperty("text").GetString()!;
                }
                
                return "La IA no devolvió respuesta.";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ERROR CRITICO IA]: {ex.Message}");
                return "Error interno en el servicio de IA.";
            }
        }
    }
}