using System.Text;
using System.Text.Json.Serialization; // <--- NECESARIO PARA TRADUCIR ENUMS
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SoctechERP.API.Data;
using SoctechERP.API.Services;

// Configuración para fechas (PostgreSQL)
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// 1. Configurar la conexión a PostgreSQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. CONFIGURACIÓN DE CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("PermitirTodo", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 3. SEGURIDAD JWT
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

// 4. CONFIGURACIÓN JSON (AQUÍ ESTÁ LA SOLUCIÓN)
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Esto permite leer "Purchase" o "Transfer" como texto
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// INYECCIÓN DE DEPENDENCIAS
builder.Services.AddScoped<AiAssistant>();
builder.Services.AddScoped<AiInvoiceScanner>();
builder.Services.AddScoped<LogisticsService>();
builder.Services.AddScoped<PurchaseValidationService>();
builder.Services.AddScoped<ProjectsService>();

var app = builder.Build();

// 5. AUTO-MIGRACIÓN
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

// 6. Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("PermitirTodo");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();