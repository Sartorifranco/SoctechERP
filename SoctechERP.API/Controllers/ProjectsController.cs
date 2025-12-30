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
        // Lista todas las obras activas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Project>>> GetProjects()
        {
            return await _context.Projects.ToListAsync();
        }

        // 2. POST: api/projects
        // Crea una obra nueva (Ej: "Torre Capital")
        [HttpPost]
        public async Task<ActionResult<Project>> PostProject(Project project)
        {
            _context.Projects.Add(project);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetProjects", new { id = project.Id }, project);
        }

        // 3. NUEVO - GET: api/projects/{projectId}/costs
        // Calcula cuánto dinero se ha "enterrado" en la obra hasta hoy
        [HttpGet("{projectId}/costs")]
        public async Task<ActionResult> GetProjectCosts(Guid projectId)
        {
            // Verificamos si la obra existe
            var project = await _context.Projects.FindAsync(projectId);
            if (project == null)
            {
                return NotFound("La obra no existe.");
            }

            // Sumamos (Cantidad * Costo) de todos los consumos de ESA obra.
            // Usamos Math.Abs porque el consumo se guarda negativo (-100), pero el costo es positivo.
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