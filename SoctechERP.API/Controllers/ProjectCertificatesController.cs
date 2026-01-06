using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProjectCertificatesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProjectCertificatesController(AppDbContext context)
        {
            _context = context;
        }

        // 1. GET: api/ProjectCertificates
        // Obtiene todos los certificados emitidos (El frontend luego filtra por obra)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ProjectCertificate>>> GetProjectCertificates()
        {
            return await _context.ProjectCertificates
                                 .OrderByDescending(c => c.Date) // Los más recientes primero
                                 .ToListAsync();
        }

        // 2. POST: api/ProjectCertificates
        // Crea un nuevo certificado de avance (Facturación)
        [HttpPost]
        public async Task<ActionResult<ProjectCertificate>> PostProjectCertificate(ProjectCertificate certificate)
        {
            // Validamos que el Proyecto (Obra) exista
            var projectExists = await _context.Projects.AnyAsync(p => p.Id == certificate.ProjectId);
            if (!projectExists)
            {
                return BadRequest("La obra especificada no existe.");
            }

            _context.ProjectCertificates.Add(certificate);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetProjectCertificates", new { id = certificate.Id }, certificate);
        }

        // 3. DELETE: api/ProjectCertificates/{id}
        // Para anular un certificado cargado por error
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCertificate(Guid id)
        {
            var cert = await _context.ProjectCertificates.FindAsync(id);
            if (cert == null)
            {
                return NotFound();
            }

            _context.ProjectCertificates.Remove(cert);
            await _context.SaveChangesAsync();

            return NoContent();
        }
        
        // 4. GET: api/ProjectCertificates/ByProject/{projectId}
        // (Opcional) Por si quieres traer solo lo cobrado de una obra específica desde el backend
        [HttpGet("ByProject/{projectId}")]
        public async Task<ActionResult<IEnumerable<ProjectCertificate>>> GetByProject(Guid projectId)
        {
             return await _context.ProjectCertificates
                                 .Where(c => c.ProjectId == projectId)
                                 .OrderByDescending(c => c.Date)
                                 .ToListAsync();
        }
    }
}