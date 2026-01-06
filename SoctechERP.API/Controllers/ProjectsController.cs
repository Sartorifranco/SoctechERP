using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProjectsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProjectsController(AppDbContext context)
        {
            _context = context;
        }

        // 1. GET: api/projects
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Project>>> GetProjects()
        {
            return await _context.Projects.ToListAsync();
        }

        // --- NUEVO MÉTODO AGREGADO (SOLUCIÓN A "CARGANDO NOMBRE DE OBRA") ---
        // 2. GET: api/projects/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Project>> GetProject(Guid id)
        {
            var project = await _context.Projects.FindAsync(id);
            if (project == null) return NotFound();
            return project;
        }
        // --------------------------------------------------------------------

        // 3. POST: api/projects
        [HttpPost]
        public async Task<ActionResult<Project>> PostProject(Project project)
        {
            _context.Projects.Add(project);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetProjects", new { id = project.Id }, project);
        }

        // 4. GET: api/projects/{projectId}/costs
        [HttpGet("{projectId}/costs")]
        public async Task<ActionResult> GetProjectCosts(Guid projectId)
        {
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null) return NotFound("La obra no existe.");

            // Costo de Materiales
            var totalSpent = await _context.StockMovements
                .Where(m => m.ProjectId == projectId && m.MovementType == "CONSUMPTION")
                .SumAsync(m => Math.Abs(m.Quantity) * m.UnitCost);

            return Ok(new 
            { 
                projectId = project.Id, 
                projectName = project.Name, 
                totalSpent = totalSpent,
                currency = "ARS" 
            });
        }
    }
}