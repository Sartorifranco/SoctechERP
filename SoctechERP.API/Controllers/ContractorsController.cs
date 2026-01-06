using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ContractorsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ContractorsController(AppDbContext context)
        {
            _context = context;
        }

        // --- GESTIÓN DE CONTRATISTAS ---

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Contractor>>> GetContractors()
        {
            return await _context.Contractors.Where(c => c.IsActive).ToListAsync();
        }

        [HttpPost]
        public async Task<ActionResult<Contractor>> PostContractor(Contractor contractor)
        {
            _context.Contractors.Add(contractor);
            await _context.SaveChangesAsync();
            return CreatedAtAction("GetContractors", new { id = contractor.Id }, contractor);
        }

        // --- GESTIÓN DE TRABAJOS (JOBS) ---

        [HttpGet("jobs")]
        public async Task<ActionResult<IEnumerable<ContractorJob>>> GetJobs()
        {
            return await _context.ContractorJobs.ToListAsync();
        }
        
        // Obtener trabajos de una obra específica (Para el BI de Costos luego)
        [HttpGet("jobs/project/{projectId}")]
        public async Task<ActionResult<IEnumerable<ContractorJob>>> GetJobsByProject(Guid projectId)
        {
            return await _context.ContractorJobs.Where(j => j.ProjectId == projectId).ToListAsync();
        }

        [HttpPost("jobs")]
        public async Task<ActionResult<ContractorJob>> PostJob(ContractorJob job)
        {
            _context.ContractorJobs.Add(job);
            await _context.SaveChangesAsync();
            return Ok(job);
        }
        
        [HttpPut("jobs/{id}/pay")]
        public async Task<IActionResult> MarkAsPaid(Guid id)
        {
            var job = await _context.ContractorJobs.FindAsync(id);
            if (job == null) return NotFound();
            
            job.IsPaid = true; // Marcar como pagado
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}