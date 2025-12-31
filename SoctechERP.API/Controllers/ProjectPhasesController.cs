using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data; // Ajusta a tu namespace de Data
using SoctechERP.API.Models; // Ajusta a tu namespace de Models

[Route("api/[controller]")]
[ApiController]
public class ProjectPhasesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProjectPhasesController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/ProjectPhases?projectId=...
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProjectPhase>>> GetPhases(Guid? projectId)
    {
        if (projectId == null)
            return await _context.ProjectPhases.ToListAsync();
            
        return await _context.ProjectPhases
                             .Where(p => p.ProjectId == projectId)
                             .ToListAsync();
    }

    // POST: api/ProjectPhases
    [HttpPost]
    public async Task<ActionResult<ProjectPhase>> PostPhase(ProjectPhase phase)
    {
        phase.Id = Guid.NewGuid();
        _context.ProjectPhases.Add(phase);
        await _context.SaveChangesAsync();
        return CreatedAtAction("GetPhases", new { id = phase.Id }, phase);
    }
    
    // PUT: api/ProjectPhases/update-progress (Para el futuro)
}