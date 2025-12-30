using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;

// --- CORRECCIÓN PARA FECHAS (IMPORTANTE) ---
// Esto permite guardar fechas sin zona horaria (como las que manda Flutter)
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);
// -------------------------------------------

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar la conexión a PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. Agregar servicios básicos de la API
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 3. AUTO-MIGRACIÓN: Esto crea la Base de Datos automáticamente al iniciar si no existe
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try 
    {
        var context = services.GetRequiredService<AppDbContext>();
        context.Database.Migrate(); 
        Console.WriteLine("--> Base de datos migrada exitosamente.");
    }
    catch (Exception ex)
    {
        Console.WriteLine("--> Error migrando la DB: " + ex.Message);
    }
}

// 4. Configurar el entorno visual (Swagger)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();