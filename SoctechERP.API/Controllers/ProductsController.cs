using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

[Route("api/[controller]")]
[ApiController]
public class ProductsController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProductsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
    {
        return await _context.Products.ToListAsync();
    }

    // ESTE ES EL MÉTODO QUE NECESITAS PARA CREAR
    [HttpPost]
    public async Task<ActionResult<Product>> PostProduct(Product product)
    {
        // Validar duplicados de SKU/Código
        if (await _context.Products.AnyAsync(p => p.Sku == product.Sku))
        {
            return BadRequest("Ya existe un producto con ese SKU / Código.");
        }

        product.Id = Guid.NewGuid();
        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        return CreatedAtAction("GetProducts", new { id = product.Id }, product);
    }
}