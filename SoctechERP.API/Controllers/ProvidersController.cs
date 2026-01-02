using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

[Route("api/[controller]")]
[ApiController]
public class ProvidersController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProvidersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Provider>>> GetProviders()
    {
        return await _context.Providers.ToListAsync();
    }

    [HttpPost]
    public async Task<ActionResult<Provider>> PostProvider(Provider provider)
    {
        // Validación: Evitar CUIT duplicado
        if (await _context.Providers.AnyAsync(p => p.Cuit == provider.Cuit))
        {
            return BadRequest("Ya existe un proveedor con ese CUIT.");
        }

        provider.Id = Guid.NewGuid();
        _context.Providers.Add(provider);
        await _context.SaveChangesAsync();

        return CreatedAtAction("GetProviders", new { id = provider.Id }, provider);
    }
}