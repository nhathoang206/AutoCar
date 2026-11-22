using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Api.Mapping;
using AutoCar.Shared.Contracts;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Services;
public class CarService(AppDbContext db)
{
    public IQueryable<CarVariant> Full=>db.CarVariants.Include(x=>x.CarModel).ThenInclude(x=>x.Brand).Include(x=>x.Inventory).Include(x=>x.Images);
    public async Task<PageResult<CarDto>> List(CarQuery f,bool admin=false)
    {
        var q=Full.AsNoTracking();
        if(!admin||!f.IncludeHidden)q=q.Where(x=>x.IsVisible&&x.CarModel.Brand.IsActive);
        if(!string.IsNullOrWhiteSpace(f.Search))q=q.Where(x=>x.Name.Contains(f.Search)||x.CarModel.Name.Contains(f.Search)||x.CarModel.Brand.Name.Contains(f.Search)||x.Code.Contains(f.Search));
        if(f.BrandId.HasValue)q=q.Where(x=>x.CarModel.BrandId==f.BrandId);
        if(f.MinPrice.HasValue)q=q.Where(x=>x.Price>=f.MinPrice);
        if(f.MaxPrice.HasValue)q=q.Where(x=>x.Price<=f.MaxPrice);
        if(f.Year.HasValue)q=q.Where(x=>x.Year==f.Year);
        if(f.Seats.HasValue)q=q.Where(x=>x.Seats==f.Seats);
        if(f.Fuel!=null)q=q.Where(x=>x.Fuel==f.Fuel);
        if(f.Transmission!=null)q=q.Where(x=>x.Transmission==f.Transmission);
        if(f.BodyStyle!=null)q=q.Where(x=>x.BodyStyle==f.BodyStyle);
        if(f.InStock.HasValue)q=q.Where(x=>(x.Inventory.Stock>0)==f.InStock);
        if(f.Featured.HasValue)q=q.Where(x=>x.IsFeatured==f.Featured);
        q=f.Sort switch{"price_asc"=>q.OrderBy(x=>x.Price).ThenBy(x=>x.Id),"price_desc"=>q.OrderByDescending(x=>x.Price).ThenBy(x=>x.Id),_=>q.OrderByDescending(x=>x.Id)};
        var total=await q.CountAsync();var rows=await q.Skip((f.Page-1)*f.PageSize).Take(f.PageSize).ToListAsync();
        return new(rows.Select(x=>x.Dto()).ToList(),total,f.Page,f.PageSize);
    }
    public async Task<CarVariant> Find(int id,bool admin=false)=>await Full.SingleOrDefaultAsync(x=>x.Id==id&&(admin||(x.IsVisible&&x.CarModel.Brand.IsActive)))??throw new BusinessException(404,"Không tìm thấy xe.");
    public async Task Validate(CarInput i)
    {
        if(!await db.CarModels.AnyAsync(x=>x.Id==i.CarModelId))throw new BusinessException(400,"Dòng xe không tồn tại.");
        if(i.Images.Length>12||i.Images.Any(x=>string.IsNullOrWhiteSpace(x)||!(x.StartsWith("/uploads/",StringComparison.Ordinal)||System.Text.RegularExpressions.Regex.IsMatch(x,"^/catalog/[a-z0-9-]+\\.webp$"))||x.Contains("..")||!new[]{".jpg",".png",".webp"}.Contains(Path.GetExtension(x).ToLowerInvariant())))
            throw new BusinessException(400,"Ảnh phải được tải lên API; tối đa 12 ảnh.");
    }
    public async Task<CarDto> Create(CarInput i)
    {
        await Validate(i);var c=new CarVariant();c.Apply(i);c.Inventory=new(){Stock=i.Stock};
        c.Images=i.Images.Select((url,n)=>new CarImage{Url=url,SortOrder=n}).ToList();db.CarVariants.Add(c);await db.SaveChangesAsync();return (await Find(c.Id,true)).Dto();
    }
    public async Task Update(int id,CarInput i)
    {
        await Validate(i);var c=await Find(id,true);
        if(string.IsNullOrEmpty(i.RowVersion)||i.RowVersion!=Convert.ToBase64String(c.RowVersion)||i.InventoryVersion!=Convert.ToBase64String(c.Inventory.RowVersion))throw new BusinessException(409,"Xe hoặc tồn kho đã thay đổi. Hãy tải lại trước khi lưu.");
        c.Apply(i);c.Inventory.Stock=i.Stock;db.CarImages.RemoveRange(c.Images);
        c.Images=i.Images.Select((url,n)=>new CarImage{Url=url,SortOrder=n}).ToList();await db.SaveChangesAsync();
    }
}
