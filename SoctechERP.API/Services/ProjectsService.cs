using SoctechERP.API.Data;
using SoctechERP.API.Models;
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
            using var transaction = await _context.Database.BeginTransactionAsync();
            
            try 
            {
                // 1. Crear el Proyecto
                newProject.Id = Guid.NewGuid();
                newProject.CreatedAt = DateTime.UtcNow;
                
                _context.Projects.Add(newProject);
                await _context.SaveChangesAsync(); 

                // 2. Crear el "Depósito de Obra" (Branch/Sucursal)
                var projectSite = new Branch
                {
                    Id = Guid.NewGuid(),
                    Name = $"OBRA: {newProject.Name}", 
                    
                    // CORRECCIÓN: Usamos 'Location' (que es lo que tiene tu Modelo Branch)
                    Location = newProject.Address ?? "Dirección de Obra", 
                    
                    IsActive = true
                };

                _context.Branches.Add(projectSite);
                await _context.SaveChangesAsync();

                // 3. Confirmar
                await transaction.CommitAsync();

                return newProject;
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}