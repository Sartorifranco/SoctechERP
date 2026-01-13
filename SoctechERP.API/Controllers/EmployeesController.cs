using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;
using System.Text;
using System.Text.RegularExpressions; // Necesario para leer CSV complejos

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EmployeesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public EmployeesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Employees
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Employee>>> GetEmployees()
        {
            return await _context.Employees
                                 .Include(e => e.WageScale)
                                 .Include(e => e.CurrentProject)
                                 .Where(e => e.IsActive)
                                 .OrderBy(e => e.LastName)
                                 .ToListAsync();
        }

        // --- NUEVO: BORRAR TODOS (PARA LIMPIAR BASURA) ---
        [HttpDelete("delete-all")]
        public async Task<IActionResult> DeleteAllEmployees()
        {
            var allEmployees = await _context.Employees.ToListAsync();
            _context.Employees.RemoveRange(allEmployees);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // POST: api/Employees/import (ADAPTADO A TU ARCHIVO DE CLIENTES)
        [HttpPost("import")]
        public async Task<ActionResult> ImportEmployees(IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("Archivo vacío");

            var newEmployees = new List<Employee>();
            int errors = 0;

            // Usamos Encoding.Latin1 o Default para que reconozca tildes si el CSV no es UTF8 puro
            using (var stream = new StreamReader(file.OpenReadStream(), Encoding.Latin1)) 
            {
                // Leer cabecera (la ignoramos)
                await stream.ReadLineAsync();

                // Regex para separar por comas PERO ignorar comas dentro de comillas "..."
                // Ejemplo: "Calle Falsa, 123" se trata como una sola columna
                var csvSplitter = new Regex("(?:^|,)(\"(?:[^\"]|\"\")*\"|[^,]*)", RegexOptions.Compiled);

                while (!stream.EndOfStream)
                {
                    var line = await stream.ReadLineAsync();
                    if (string.IsNullOrWhiteSpace(line)) continue;

                    // Usamos el Regex para obtener los valores limpios
                    var matches = csvSplitter.Matches(line);
                    var values = matches.Cast<Match>().Select(m => m.Value.TrimStart(',').Trim('"')).ToArray();

                    // TU ARCHIVO TIENE ESTAS COLUMNAS:
                    // [0] ID (ej: C0001)
                    // [1] Nombre completo (ej: Leandra Anna Malo Alba)
                    // [2] Fecha nac
                    // [3] Dirección
                    // [4] Localidad
                    // [5] Teléfono
                    // [6] Email
                    
                    if (values.Length < 2) { errors++; continue; }

                    try
                    {
                        var rawName = values[1].Trim();
                        
                        // Separar Nombre y Apellido (Tomamos la última palabra como apellido para simplificar)
                        var namesParts = rawName.Split(' ');
                        var lastName = namesParts.Length > 1 ? namesParts.Last() : "";
                        var firstName = namesParts.Length > 1 ? string.Join(" ", namesParts.Take(namesParts.Length - 1)) : rawName;

                        var emp = new Employee
                        {
                            Id = Guid.NewGuid(),
                            FirstName = firstName,
                            LastName = lastName,
                            
                            // Mapeamos tus columnas a nuestro modelo
                            Dni = values[0], // Usamos el ID del cliente como DNI temporal
                            Address = (values.Length > 3) ? values[3] + ", " + (values.Length > 4 ? values[4] : "") : "",
                            Phone = (values.Length > 5) ? values[5] : "",
                            Email = (values.Length > 6) ? values[6] : "",
                            
                            Cuil = "", // No viene en el archivo
                            IsActive = true,
                            EntryDate = DateTime.UtcNow,
                            Category = "Importado",
                            Union = 2, // Fuera de convenio por defecto
                            Frequency = 1 // Mensual
                        };
                        newEmployees.Add(emp);
                    }
                    catch
                    {
                        errors++;
                    }
                }
            }

            if (newEmployees.Any())
            {
                _context.Employees.AddRange(newEmployees);
                await _context.SaveChangesAsync();
            }

            return Ok(new { imported = newEmployees.Count, errors = errors });
        }
        
        // ... (MANTEN LOS METODOS GET{id}, PUT, DELETE y POST MANUAL IGUAL QUE ANTES) ...
        // GET: api/Employees/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Employee>> GetEmployee(Guid id)
        {
            var employee = await _context.Employees.FindAsync(id);
            if (employee == null) return NotFound();
            return employee;
        }

        // POST MANUAL
        [HttpPost]
        public async Task<ActionResult<Employee>> PostEmployee(Employee employee)
        {
             employee.WageScale = null;
             employee.CurrentProject = null;
             if (employee.EntryDate == DateTime.MinValue) employee.EntryDate = DateTime.UtcNow;
             _context.Employees.Add(employee);
             await _context.SaveChangesAsync();
             return CreatedAtAction("GetEmployee", new { id = employee.Id }, employee);
        }
    }
}