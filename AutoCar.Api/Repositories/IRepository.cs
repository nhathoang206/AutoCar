namespace AutoCar.Api.Repositories;
public interface IRepository<T> where T : class
{
    Task<IEnumerable<T>> GetAllAsync();
    Task<T?> GetByIdAsync(int id);
    Task AddAsync(T entity);
    Task<bool> UpdateAsync(int id,T entity);
    Task<bool> DeleteAsync(int id);
    Task<bool> SaveAsync();
}
