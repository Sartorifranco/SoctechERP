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

        // GET: api/WorkLogs?projectId=...
        // Mantenemos tu lógica de filtros, ¡es excelente!
        [HttpGet]
        public async Task<ActionResult<IEnumerable<WorkLog>>> GetWorkLogs(Guid? projectId)
        {
            var query = _context.WorkLogs.Include(w => w.Employee).AsQueryable();

            if (projectId != null)
            {
                query = query.Where(w => w.ProjectId == projectId);
            }

            return await query.OrderByDescending(w => w.Date).ToListAsync();
        }

        // POST: api/WorkLogs
        // CORREGIDO: Soporta empleados "Fuera de Convenio" (Sueldo Negociado)
        [HttpPost]
        public async Task<ActionResult<WorkLog>> PostWorkLog(WorkLog workLog)
        {
            // 1. Buscamos al empleado y su escala
            var employee = await _context.Employees
                                         .Include(e => e.WageScale) 
                                         .FirstOrDefaultAsync(e => e.Id == workLog.EmployeeId);

            if (employee == null) return NotFound("Empleado no encontrado");

            // 2. LÓGICA DE PRECIO (SNAPSHOT)
            // Aquí arreglamos el bug. Antes obligabas a tener WageScale. 
            // Ahora miramos primero si hay Sueldo Negociado.

            decimal finalRate = 0;

            if (employee.NegotiatedSalary.HasValue && employee.NegotiatedSalary > 0)
            {
                // A. Tiene Sueldo Manual (Fuera de Convenio)
                // Si el valor es muy alto (ej: > 200.000), asumimos que es mensual y lo dividimos por 200 horas promedio
                if (employee.NegotiatedSalary > 200000)
                    finalRate = employee.NegotiatedSalary.Value / 200;
                else
                    finalRate = employee.NegotiatedSalary.Value; // Ya es valor hora
            }
            else if (employee.WageScale != null)
            {
                // B. Es de Gremio (UOCRA/UECARA)
                finalRate = employee.WageScale.BasicValue;
            }
            else
            {
                // C. No tiene nada cargado
                return BadRequest("El empleado no tiene Categoría asignada ni Sueldo Negociado. No se puede calcular el costo.");
            }

            // Guardamos la foto del precio
            workLog.RegisteredRateSnapshot = finalRate;
            
            // Completamos IDs y Fechas
            workLog.Id = Guid.NewGuid();
            if (workLog.Date == DateTime.MinValue) workLog.Date = DateTime.UtcNow;

            _context.WorkLogs.Add(workLog);
            await _context.SaveChangesAsync();
            
            return CreatedAtAction("GetWorkLogs", new { id = workLog.Id }, workLog);
        }
    }
}