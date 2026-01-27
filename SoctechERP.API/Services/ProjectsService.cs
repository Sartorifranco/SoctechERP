using SoctechERP.API.Data;
using SoctechERP.API.Models;
using SoctechERP.API.Models.Enums;
using Microsoft.EntityFrameworkCore;

namespace SoctechERP.API.Services
{
    public class ProjectsService
    {
        private readonly AppDbContext _context;

        public ProjectsService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<Project> CreateProjectWithLogisticsAsync(Project newProject)
        {
            // Usamos una transacción para asegurar integridad total (ACID).
            // Si falla la creación del depósito, se cancela la creación del proyecto.
            using var transaction = await _context.Database.BeginTransactionAsync();
            
            try 
            {
                // 1. Crear el Proyecto
                newProject.Id = Guid.NewGuid();
                newProject.CreatedAt = DateTime.UtcNow;
                // newProject.Status = ProjectStatus.Active; 

                _context.Projects.Add(newProject);
                
                // Guardamos para asegurar que el ID existe en la DB
                await _context.SaveChangesAsync(); 

                // 2. AUTOMATIZACIÓN: Crear el "Depósito de Obra" (Branch)
                // Esto permite que el día 1 ya puedas mandar materiales a la obra.
                var projectSite = new Branch
                {
                    Id = Guid.NewGuid(),
                    Name = $"OBRA: {newProject.Name}", // Ej: "OBRA: Torre Alvear"
                    Address = newProject.Address ?? "Dirección de Obra",
                    IsActive = true,
                    
                    // Asegurate de agregar estos campos a tu entidad Branch:
                    // Type = BranchType.ProjectSite, 
                    // ProjectId = newProject.Id 
                };

                _context.Branches.Add(projectSite);
                await _context.SaveChangesAsync();

                // 3. Confirmar transacción
                await transaction.CommitAsync();

                return newProject;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw; // Re-lanzamos para que el Controller maneje el error HTTP 500
            }
        }
    }
}