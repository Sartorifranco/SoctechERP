using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

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
                             .Where(e => e.IsActive)
                             .ToListAsync();
    }

    // GET: api/Employees/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Employee>> GetEmployee(Guid id)
    {
        var employee = await _context.Employees
                                     .Include(e => e.WageScale)
                                     .FirstOrDefaultAsync(e => e.Id == id);

        if (employee == null) return NotFound();

        return employee;
    }

    // POST: api/Employees (ALTA)
    [HttpPost]
    public async Task<ActionResult<Employee>> PostEmployee(Employee employee)
    {
        // 1. Validar Categoría SOLO SI se envió un ID (Evita error en Fuera de Convenio)
        if (employee.WageScaleId != null)
        {
            var scaleExists = await _context.WageScales.AnyAsync(w => w.Id == employee.WageScaleId);
            if (!scaleExists)
            {
                return BadRequest($"La categoría con ID {employee.WageScaleId} no existe.");
            }
        }

        // 2. Limpieza y valores por defecto
        employee.WageScale = null; // Evitar conflictos de duplicación
        if (employee.EntryDate == DateTime.MinValue) employee.EntryDate = DateTime.UtcNow;
        
        // 3. Guardar en Base de Datos
        _context.Employees.Add(employee);
        await _context.SaveChangesAsync();

        return CreatedAtAction("GetEmployee", new { id = employee.Id }, employee);
    }

    // PUT: api/Employees/5 (EDICIÓN)
    [HttpPut("{id}")]
    public async Task<IActionResult> PutEmployee(Guid id, Employee employee)
    {
        if (id != employee.Id) return BadRequest();

        _context.Entry(employee).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!EmployeeExists(id)) return NotFound();
            else throw;
        }

        return NoContent();
    }

    // DELETE: api/Employees/5 (BAJA LÓGICA)
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(Guid id)
    {
        var employee = await _context.Employees.FindAsync(id);
        if (employee == null) return NotFound();

        employee.IsActive = false; // Soft Delete
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool EmployeeExists(Guid id)
    {
        return _context.Employees.Any(e => e.Id == id);
    }
}