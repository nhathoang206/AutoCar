using AutoCar.Api.Data;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Repositories;
public class Repository<T>(AppDbContext context) : IRepository<T> where T : class
{
    private readonly DbSet<T> set = context.Set<T>();
    public async Task<IEnumerable<T>> GetAllAsync()=>await set.ToListAsync();
    public async Task<T?> GetByIdAsync(int id)=>await set.FindAsync(id);
    public async Task AddAsync(T entity)=>await set.AddAsync(entity);
    public async Task<bool> UpdateAsync(int id,T entity)
    {
        var existing=await set.FindAsync(id); if(existing is null) return false;
        context.Entry(existing).CurrentValues.SetValues(entity); return true;
    }
    public async Task<bool> DeleteAsync(int id)
    {
        var existing=await set.FindAsync(id); if(existing is null) return false;
        set.Remove(existing); return true;
    }
    public async Task<bool> SaveAsync()=>await context.SaveChangesAsync()>0;
}
