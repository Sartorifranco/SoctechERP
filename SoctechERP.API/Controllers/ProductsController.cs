using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;
using SoctechERP.API.Models;

namespace SoctechERP.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProductsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/products (Traer todos los productos)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
        {
            return await _context.Products.ToListAsync();
        }

        // POST: api/products (Crear un producto nuevo)
        [HttpPost]
        public async Task<ActionResult<Product>> PostProduct(Product product)
        {
            try
            {
                _context.Products.Add(product);
                await _context.SaveChangesAsync();
                
                // Devuelve código 201 (Creado)
                return CreatedAtAction("GetProducts", new { id = product.Id }, product);
            }
            catch (DbUpdateException dbEx)
            {
                // Si el error es por duplicado (SKU repetido), devolvemos mensaje amable
                if (dbEx.InnerException is Npgsql.PostgresException postgresEx && postgresEx.SqlState == "23505")
                {
                    return Conflict(new { message = "Ya existe un producto con ese código SKU." });
                }
                throw; // Si es otro error, que explote
            }
        }
    }
}