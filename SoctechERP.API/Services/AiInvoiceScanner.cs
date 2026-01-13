using System.Text;
using System.Text.Json;

namespace SoctechERP.API.Services
{
    public class AiInvoiceScanner
    {
        // TU CLAVE (La misma del chat)
        private readonly string _apiKey = "AIzaSyAfjsPjApA__1GkGPHD4nZL_med05sWItw"; 

        public async Task<ScanResult?> ScanInvoice(IFormFile file)
        {
            try 
            {
                // 1. Detección manual del tipo de imagen (CORRECCIÓN CRÍTICA)
                string extension = Path.GetExtension(file.FileName).ToLower();
                string mimeType = extension switch
                {
                    ".png" => "image/png",
                    ".jpg" => "image/jpeg",
                    ".jpeg" => "image/jpeg",
                    ".webp" => "image/webp",
                    ".heic" => "image/heic",
                    ".heif" => "image/heif",
                    _ => "image/jpeg" // Ante la duda, decimos que es JPG
                };

                // 2. Convertir imagen a Base64
                using var ms = new MemoryStream();
                await file.CopyToAsync(ms);
                var base64Image = Convert.ToBase64String(ms.ToArray());

                Console.WriteLine($"[SCANNER] Enviando imagen: {file.FileName} como {mimeType}");

                // 3. URL Gemini
                string url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={_apiKey}";

                // 4. Prompt Estricto
                var requestBody = new
                {
                    contents = new[]
                    {
                        new
                        {
                            parts = new object[]
                            {
                                new { text = "Analiza esta imagen. IMPORTANTE: Responde ÚNICAMENTE con un JSON crudo. NO uses bloques de código markdown (```json). El JSON debe tener: providerName, invoiceNumber, date (YYYY-MM-DD), totalAmount (decimal), netAmount, vatAmount y items array." },
                                new { inline_data = new { mime_type = mimeType, data = base64Image } }
                            }
                        }
                    }
                };

                using var client = new HttpClient();
                var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");

                // 5. Enviar a Google
                var response = await client.PostAsync(url, content);
                var jsonString = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode) 
                {
                    Console.WriteLine($"[ERROR HTTP GOOGLE] {response.StatusCode}: {jsonString}");
                    return null;
                }

                // 6. Parsear respuesta con cirugía
                using var doc = JsonDocument.Parse(jsonString);
                
                if (!doc.RootElement.TryGetProperty("candidates", out var candidates)) return null;
                if (candidates.GetArrayLength() == 0) return null;

                var rawText = candidates[0]
                                .GetProperty("content").GetProperty("parts")[0]
                                .GetProperty("text").GetString();

                if (rawText != null)
                {
                    Console.WriteLine($"[IA RAW]: {rawText}"); // Debug

                    // Limpieza de Markdown y búsqueda de llaves
                    rawText = rawText.Replace("```json", "").Replace("```", "").Trim();
                    
                    int firstBrace = rawText.IndexOf('{');
                    int lastBrace = rawText.LastIndexOf('}');

                    if (firstBrace >= 0 && lastBrace > firstBrace)
                    {
                        rawText = rawText.Substring(firstBrace, lastBrace - firstBrace + 1);
                    }

                    var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                    return JsonSerializer.Deserialize<ScanResult>(rawText, options);
                }
                return null;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[EXCEPCION FATAL SCANNER]: {ex.Message}");
                return null;
            }
        }
    }

    // Modelos
    public class ScanResult
    {
        public string? ProviderName { get; set; }
        public string? InvoiceNumber { get; set; }
        public string? Date { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal NetAmount { get; set; }
        public decimal VatAmount { get; set; }
        public List<ScanItem> Items { get; set; } = new List<ScanItem>();
    }

    public class ScanItem
    {
        public string? Description { get; set; }
        public decimal Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Total { get; set; }
    }
}