using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Api.Repositories;
using AutoCar.Api.Services;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/[controller]")]
public class BrandsController(IRepository<Brand> repo,AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<PageResult<BrandDto>> List(string? search=null,int page=1,int pageSize=30,bool includeHidden=false)
    {
        if(page<1||page>100000||pageSize<1||pageSize>100)throw new BusinessException(400,"Phân trang không hợp lệ.");
        var q=db.Brands.AsNoTracking().Where(x=>(includeHidden&&User.IsInRole("Admin"))||x.IsActive);
        if(search!=null)q=q.Where(x=>x.Name.Contains(search));
        return new(await q.OrderBy(x=>x.Name).Skip((page-1)*pageSize).Take(pageSize).Select(x=>new BrandDto(x.Id,x.Name,x.LogoUrl,x.IsActive)).ToListAsync(),await q.CountAsync(),page,pageSize);
    }
    [HttpGet("{id:int}")]
    public async Task<ActionResult<BrandDto>> Get(int id){var b=await repo.GetByIdAsync(id);return b==null?NotFound():Ok(new BrandDto(b.Id,b.Name,b.LogoUrl,b.IsActive));}
    [HttpPost,Authorize(Roles="Admin")]
    public async Task<IActionResult> Create(BrandInput i)
    {
        ValidateLogo(i.LogoUrl);var b=new Brand{Name=i.Name.Trim(),LogoUrl=i.LogoUrl,IsActive=i.IsActive};await repo.AddAsync(b);await repo.SaveAsync();return CreatedAtAction(nameof(Get),new{id=b.Id},new BrandDto(b.Id,b.Name,b.LogoUrl,b.IsActive));
    }
    [HttpPut("{id:int}"),Authorize(Roles="Admin")]
    public async Task<IActionResult> Update(int id,BrandInput i)
    {
        ValidateLogo(i.LogoUrl);var b=await repo.GetByIdAsync(id);if(b==null)return NotFound();b.Name=i.Name.Trim();b.LogoUrl=i.LogoUrl;b.IsActive=i.IsActive;await repo.SaveAsync();return NoContent();
    }
    [HttpDelete("{id:int}"),Authorize(Roles="Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var b=await repo.GetByIdAsync(id);if(b==null)return NotFound();
        if(await db.CarModels.AnyAsync(x=>x.BrandId==id))b.IsActive=false;else await repo.DeleteAsync(id);
        await repo.SaveAsync();return NoContent();
    }
    private static void ValidateLogo(string? url){if(url!=null&&(!url.StartsWith("/uploads/")||url.Contains("..")))throw new BusinessException(400,"Logo phải được tải lên API.");}
}
