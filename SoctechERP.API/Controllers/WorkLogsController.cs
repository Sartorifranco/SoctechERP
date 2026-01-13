using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class WorkLogsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public WorkLogsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/WorkLogs
        [HttpGet]
        public async Task<ActionResult<IEnumerable<WorkLog>>> GetWorkLogs()
        {
            return await _context.WorkLogs
                .Include(w => w.Employee)
                .Include(w => w.Project) // Ahora sí existe Project
                .OrderByDescending(w => w.Date)
                .ToListAsync();
        }

        // POST: api/WorkLogs
        [HttpPost]
        public async Task<ActionResult<WorkLog>> PostWorkLog(WorkLog workLog)
        {
            // 1. Validar empleado
            var employee = await _context.Employees
                .Include(e => e.WageScale)
                .FirstOrDefaultAsync(e => e.Id == workLog.EmployeeId);

            if (employee == null) return BadRequest("Empleado no válido");

            // 2. Determinar el valor hora (Rate) - Todo en decimal para evitar errores de moneda
            decimal hourlyRate = 0;

            if (employee.NegotiatedSalary.HasValue && employee.NegotiatedSalary.Value > 0)
            {
                // Convertimos el double a decimal para operar
                decimal baseSalary = (decimal)employee.NegotiatedSalary.Value;
                
                // Si es mensual (Frequency 1), dividimos por 176 horas
                hourlyRate = (employee.Frequency == 1) ? (baseSalary / 176m) : baseSalary;
            }
            else if (employee.WageScale != null)
            {
                // WageScale.BasicValue suele ser double, lo casteamos
                hourlyRate = (decimal)employee.WageScale.BasicValue;
            }

            // 3. Calcular Costo (Horas [double] * Tarifa [decimal])
            workLog.HourlyRateSnapshot = hourlyRate;
            
            // Truco: Convertir las horas a decimal para multiplicar peras con peras
            workLog.TotalCost = (decimal)workLog.HoursWorked * hourlyRate;

            _context.WorkLogs.Add(workLog);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetWorkLogs", new { id = workLog.Id }, workLog);
        }
        
        // DELETE: api/WorkLogs/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteWorkLog(Guid id)
        {
            var workLog = await _context.WorkLogs.FindAsync(id);
            if (workLog == null) return NotFound();

            _context.WorkLogs.Remove(workLog);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}