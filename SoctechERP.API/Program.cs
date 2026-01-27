using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SoctechERP.API.Data;
// Importamos el namespace de los Servicios para limpiar el código
using SoctechERP.API.Services; 

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

// 3. CONFIGURACIÓN DE SEGURIDAD (JWT)
var key = Encoding.ASCII.GetBytes("ESTA_ES_MI_CLAVE_SECRETA_SUPER_SEGURA_123456"); 
builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false;
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false
    };
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// -----------------------------------------------------------------------------
// INYECCIÓN DE DEPENDENCIAS (EL CEREBRO DEL ERP)
// -----------------------------------------------------------------------------

// A. Servicios de Inteligencia Artificial
builder.Services.AddScoped<AiAssistant>();       // Chatbot
builder.Services.AddScoped<AiInvoiceScanner>();  // Escáner de Facturas

// B. Servicios Core de Negocio (Arquitectura ERP Corporativa)
// Registramos los motores lógicos que hemos diseñado:
builder.Services.AddScoped<LogisticsService>();          // Motor de Stock y Recepción (Goods Receipt)
builder.Services.AddScoped<PurchaseValidationService>(); // Motor de Triple Validación (3-Way Match)
builder.Services.AddScoped<ProjectsService>();           // Automatización de Obras y Depósitos

// -----------------------------------------------------------------------------

var app = builder.Build();

// 5. AUTO-MIGRACIÓN (Crea la DB y tablas nuevas automáticamente al iniciar)
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

// 6. Configurar Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Activamos CORS
app.UseCors("PermitirTodo");

// 7. ACTIVAR SEGURIDAD (Orden importante: Auth -> Authorize)
app.UseAuthentication(); // Identifica quién eres
app.UseAuthorization();  // Verifica qué puedes hacer

app.MapControllers();

app.Run();