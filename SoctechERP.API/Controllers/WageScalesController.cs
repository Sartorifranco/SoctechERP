using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

[Route("api/[controller]")]
[ApiController]
public class WageScalesController : ControllerBase
{
    private readonly AppDbContext _context;

    public WageScalesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<WageScale>>> GetScales()
    {
        return await _context.WageScales.Where(w => w.IsActive).ToListAsync();
    }
}