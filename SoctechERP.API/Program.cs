using Microsoft.EntityFrameworkCore;
using SoctechERP.API.Data;

// Configuración para fechas (PostgreSQL)
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar la conexión a PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. CONFIGURACIÓN DE CORS (Permitir conexión desde el Frontend)
builder.Services.AddCors(options =>
{
    options.AddPolicy("PermitirTodo", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 3. AUTO-MIGRACIÓN
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

// 4. Configurar Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// --- CAMBIO IMPORTANTE AQUÍ ---
// Comentamos esta línea para evitar el error de redirección de puerto
// app.UseHttpsRedirection(); 
// ------------------------------

// Activamos CORS
app.UseCors("PermitirTodo");

app.UseAuthorization();

app.MapControllers();

app.Run();