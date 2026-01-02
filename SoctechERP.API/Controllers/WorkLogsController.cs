using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

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
    [HttpGet]
    public async Task<ActionResult<IEnumerable<WorkLog>>> GetWorkLogs(Guid? projectId)
    {
        if (projectId == null) 
            return await _context.WorkLogs
                                 .Include(w => w.Employee) // Incluimos nombre del empleado
                                 .ToListAsync();
        
        return await _context.WorkLogs
                             .Include(w => w.Employee)
                             .Where(w => w.ProjectId == projectId)
                             .OrderByDescending(w => w.Date)
                             .ToListAsync();
    }

    [HttpPost]
    public async Task<ActionResult<WorkLog>> PostWorkLog(WorkLog workLog)
    {
        // 1. Buscamos al empleado E INCLUIMOS su escala salarial (WageScale)
        //    Necesitamos el Include porque si no, WageScale viene vacío (null)
        var employee = await _context.Employees
                                     .Include(e => e.WageScale) 
                                     .FirstOrDefaultAsync(e => e.Id == workLog.EmployeeId);

        if (employee == null) return NotFound("Empleado no encontrado");
        if (employee.WageScale == null) return BadRequest("El empleado no tiene categoría asignada");

        // 2. LOGICA PROFESIONAL: Guardamos el Snapshot
        //    Tomamos el precio de la escala (Ej: $5800) y lo grabamos en el registro histórico
        workLog.RegisteredRateSnapshot = employee.WageScale.BasicValue;
        
        workLog.Id = Guid.NewGuid();
        
        // Validar fecha si no viene
        if (workLog.Date == DateTime.MinValue) workLog.Date = DateTime.UtcNow;

        _context.WorkLogs.Add(workLog);
        await _context.SaveChangesAsync();
        
        return CreatedAtAction("GetWorkLogs", new { id = workLog.Id }, workLog);
    }
}