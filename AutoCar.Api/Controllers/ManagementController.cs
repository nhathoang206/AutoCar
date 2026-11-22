using System.Security.Claims;
using System.Security.Cryptography;
using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Api.Services;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/users"),Authorize(Roles="Admin")]
public class UsersController(AppDbContext db,UserManager<AppUser> users) : ControllerBase
{
    [HttpGet]public async Task<IActionResult> Get(string? search=null,int page=1)
    {
        if(page<1)return BadRequest();var q=db.Users.AsNoTracking();if(search!=null)q=q.Where(x=>x.FullName.Contains(search)||x.Email!.Contains(search));
        var rows=await q.OrderBy(x=>x.Email).Skip((page-1)*20).Take(20).ToListAsync();var items=new List<object>();foreach(var u in rows)items.Add(new{u.Id,u.FullName,u.Email,u.PhoneNumber,u.Address,Locked=u.LockoutEnd>DateTimeOffset.UtcNow,Roles=await users.GetRolesAsync(u)});return Ok(new{items,total=await q.CountAsync(),page,pageSize=20});
    }
    [HttpGet("sales")]public async Task<IActionResult> Sales()=>Ok((await users.GetUsersInRoleAsync("Sales")).Select(x=>new{x.Id,x.FullName,x.Email}));
    [HttpPut("{id}")]public async Task<IActionResult> Update(string id,UserAdminInput i)
    {
        if(!new[]{"Admin","Sales","Customer"}.Contains(i.Role))return BadRequest();var u=await users.FindByIdAsync(id);if(u==null)return NotFound();
        if(await users.IsInRoleAsync(u,"Admin"))throw new BusinessException(409,"Không thay đổi tài khoản Admin qua API này.");
        await using var tx=await db.Database.BeginTransactionAsync();await users.RemoveFromRolesAsync(u,await users.GetRolesAsync(u));await users.AddToRoleAsync(u,i.Role);await users.SetLockoutEndDateAsync(u,i.Locked?DateTimeOffset.UtcNow.AddYears(50):null);
        await db.RefreshSessions.Where(x=>x.UserId==id).ExecuteUpdateAsync(s=>s.SetProperty(x=>x.Revoked,true));db.AuditLogs.Add(new(){ActorId=User.FindFirstValue(ClaimTypes.NameIdentifier)!,Action="UserRoleLock",Resource=$"User/{id}/{i.Role}/{i.Locked}"});await db.SaveChangesAsync();await tx.CommitAsync();return NoContent();
    }
}
[ApiController,Route("api/uploads"),Authorize(Roles="Admin")]
public class UploadsController(IWebHostEnvironment env) : ControllerBase
{
    [HttpPost,RequestSizeLimit(5*1024*1024)]public async Task<IActionResult> Upload(IFormFile file)
    {
        if(file.Length is < 12 or > 4*1024*1024)throw new BusinessException(400,"Ảnh phải nhỏ hơn 4 MB.");
        var ext=Path.GetExtension(file.FileName).ToLowerInvariant();if(!new[]{".jpg",".jpeg",".png",".webp"}.Contains(ext))throw new BusinessException(400,"Chỉ nhận JPG, PNG, WebP.");
        var bytes=new byte[12];await using(var s=file.OpenReadStream())await s.ReadExactlyAsync(bytes);
        bool valid=ext is ".jpg" or ".jpeg"?bytes[0]==255&&bytes[1]==216&&bytes[2]==255:ext==".png"?bytes.AsSpan(0,8).SequenceEqual(new byte[]{137,80,78,71,13,10,26,10}):System.Text.Encoding.ASCII.GetString(bytes,0,4)=="RIFF"&&System.Text.Encoding.ASCII.GetString(bytes,8,4)=="WEBP";
        if(!valid)throw new BusinessException(400,"Nội dung ảnh không đúng định dạng.");var dir=Path.Combine(env.ContentRootPath,"wwwroot","uploads");Directory.CreateDirectory(dir);var name=Convert.ToHexString(RandomNumberGenerator.GetBytes(20))+(ext==".jpeg"?".jpg":ext);await using var target=System.IO.File.Create(Path.Combine(dir,name));await file.CopyToAsync(target);return Created("/uploads/"+name,new{url="/uploads/"+name});
    }
}
[ApiController,Route("api/notifications"),Authorize]
public class NotificationsController(AppDbContext db) : ControllerBase
{
    private string Uid=>User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    [HttpGet]public async Task<IActionResult> Get()=>Ok(await db.Notifications.AsNoTracking().Where(x=>x.UserId==Uid).OrderByDescending(x=>x.Id).Select(x=>new{x.Id,x.Message,x.IsRead,x.CreatedAt}).Take(50).ToListAsync());
    [HttpPut("{id:int}/read")]public async Task<IActionResult> Read(int id){var n=await db.Notifications.SingleOrDefaultAsync(x=>x.Id==id&&x.UserId==Uid);if(n==null)return NotFound();n.IsRead=true;await db.SaveChangesAsync();return NoContent();}
}
[ApiController,Route("api/public")]
public class PublicController(AppDbContext db) : ControllerBase
{
    [HttpPost("contacts"),EnableRateLimiting("auth")]public async Task<IActionResult> Contact(ContactInput i){db.Contacts.Add(new(){Name=i.Name,Email=i.Email,Message=i.Message});await db.SaveChangesAsync();return StatusCode(201);}
    [HttpGet("promotions")]public async Task<IActionResult> Promotions()=>Ok(await db.Promotions.AsNoTracking().Where(x=>x.StartsAt<=DateTimeOffset.UtcNow&&x.EndsAt>=DateTimeOffset.UtcNow).Select(x=>new{x.Id,x.Title,x.Description,x.StartsAt,x.EndsAt}).ToListAsync());
    [HttpGet("contacts"),Authorize(Roles="Admin")]public Task<List<Contact>> Contacts()=>db.Contacts.OrderByDescending(x=>x.Id).Take(100).ToListAsync();
    [HttpGet("audit"),Authorize(Roles="Admin")]public async Task<IActionResult> Audit()=>Ok(await db.AuditLogs.OrderByDescending(x=>x.Id).Select(x=>new{x.Id,x.Action,x.Resource,x.At,Actor=x.Actor.FullName}).Take(100).ToListAsync());
}
