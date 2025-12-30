using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")] // La ruta será: api/companies
    [ApiController]
    public class CompaniesController : ControllerBase
    {
        private readonly AppDbContext _context;

        // Inyección de Dependencias: Aquí recibimos la conexión a la DB
        public CompaniesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/companies
        // Este método devuelve TODAS las empresas
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Company>>> GetCompanies()
        {
            return await _context.Companies.ToListAsync();
        }

        // POST: api/companies
        // Este método CREA una nueva empresa
        // POST: api/companies
[HttpPost]
public async Task<ActionResult<Company>> PostCompany(Company company)
{
    try 
    {
        _context.Companies.Add(company);
        await _context.SaveChangesAsync();

        return CreatedAtAction("GetCompanies", new { id = company.Id }, company);
    }
    catch (DbUpdateException dbEx)
    {
        // Verificamos si el error interno viene de Postgres y si es por duplicados (Código 23505)
        if (dbEx.InnerException is Npgsql.PostgresException postgresEx && postgresEx.SqlState == "23505")
        {
            // Retornamos un error 409 (Conflicto) con un mensaje claro
            return Conflict(new { message = "Ya existe una empresa registrada con ese CUIT." });
        }
        
        // Si es otro error, lo lanzamos para que lo maneje el servidor
        throw;
    }
}
    }
}