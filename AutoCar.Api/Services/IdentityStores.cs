using AutoCar.Api.Data;
using AutoCar.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace AutoCar.Api.Services;

// ASP.NET Core Identity managers/hashers backed by EF Core. Explicit store avoids
// an unavailable Identity.EntityFrameworkCore package in the offline lab environment.
public class UserStore(AppDbContext db) : IUserPasswordStore<AppUser>, IUserEmailStore<AppUser>,
    IUserRoleStore<AppUser>, IUserLockoutStore<AppUser>, IUserPhoneNumberStore<AppUser>, IUserSecurityStampStore<AppUser>
{
    public void Dispose() { }
    public Task<string> GetUserIdAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.Id);
    public Task<string?> GetUserNameAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.UserName);
    public Task SetUserNameAsync(AppUser u,string? v,CancellationToken c){u.UserName=v;return Task.CompletedTask;}
    public Task<string?> GetNormalizedUserNameAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.NormalizedUserName);
    public Task SetNormalizedUserNameAsync(AppUser u,string? v,CancellationToken c){u.NormalizedUserName=v;return Task.CompletedTask;}
    public async Task<IdentityResult> CreateAsync(AppUser u,CancellationToken c){db.Users.Add(u);await db.SaveChangesAsync(c);return IdentityResult.Success;}
    public async Task<IdentityResult> UpdateAsync(AppUser u,CancellationToken c){db.Users.Update(u);await db.SaveChangesAsync(c);return IdentityResult.Success;}
    public async Task<IdentityResult> DeleteAsync(AppUser u,CancellationToken c){db.Users.Remove(u);await db.SaveChangesAsync(c);return IdentityResult.Success;}
    public Task<AppUser?> FindByIdAsync(string id,CancellationToken c)=>db.Users.SingleOrDefaultAsync(x=>x.Id==id,c);
    public Task<AppUser?> FindByNameAsync(string name,CancellationToken c)=>db.Users.SingleOrDefaultAsync(x=>x.NormalizedUserName==name,c);
    public Task SetPasswordHashAsync(AppUser u,string? v,CancellationToken c){u.PasswordHash=v;return Task.CompletedTask;}
    public Task<string?> GetPasswordHashAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.PasswordHash);
    public Task<bool> HasPasswordAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.PasswordHash!=null);
    public Task SetEmailAsync(AppUser u,string? v,CancellationToken c){u.Email=v;return Task.CompletedTask;}
    public Task<string?> GetEmailAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.Email);
    public Task<bool> GetEmailConfirmedAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.EmailConfirmed);
    public Task SetEmailConfirmedAsync(AppUser u,bool v,CancellationToken c){u.EmailConfirmed=v;return Task.CompletedTask;}
    public Task<AppUser?> FindByEmailAsync(string v,CancellationToken c)=>db.Users.SingleOrDefaultAsync(x=>x.NormalizedEmail==v,c);
    public Task<string?> GetNormalizedEmailAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.NormalizedEmail);
    public Task SetNormalizedEmailAsync(AppUser u,string? v,CancellationToken c){u.NormalizedEmail=v;return Task.CompletedTask;}
    public async Task AddToRoleAsync(AppUser u,string role,CancellationToken c){var r=await db.Roles.SingleAsync(x=>x.NormalizedName==role,c);db.UserRoles.Add(new(){UserId=u.Id,RoleId=r.Id});}
    public async Task RemoveFromRoleAsync(AppUser u,string role,CancellationToken c){var r=await db.Roles.SingleAsync(x=>x.NormalizedName==role,c);var link=await db.UserRoles.SingleOrDefaultAsync(x=>x.UserId==u.Id&&x.RoleId==r.Id,c);if(link!=null)db.UserRoles.Remove(link);}
    public async Task<IList<string>> GetRolesAsync(AppUser u,CancellationToken c)=>await (from l in db.UserRoles join r in db.Roles on l.RoleId equals r.Id where l.UserId==u.Id select r.Name!).ToListAsync(c);
    public Task<bool> IsInRoleAsync(AppUser u,string role,CancellationToken c)=>(from l in db.UserRoles join r in db.Roles on l.RoleId equals r.Id where l.UserId==u.Id&&r.NormalizedName==role select l).AnyAsync(c);
    public async Task<IList<AppUser>> GetUsersInRoleAsync(string role,CancellationToken c)=>await (from u in db.Users join l in db.UserRoles on u.Id equals l.UserId join r in db.Roles on l.RoleId equals r.Id where r.NormalizedName==role select u).ToListAsync(c);
    public Task<DateTimeOffset?> GetLockoutEndDateAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.LockoutEnd);
    public Task SetLockoutEndDateAsync(AppUser u,DateTimeOffset? v,CancellationToken c){u.LockoutEnd=v;return Task.CompletedTask;}
    public Task<int> IncrementAccessFailedCountAsync(AppUser u,CancellationToken c)=>Task.FromResult(++u.AccessFailedCount);
    public Task ResetAccessFailedCountAsync(AppUser u,CancellationToken c){u.AccessFailedCount=0;return Task.CompletedTask;}
    public Task<int> GetAccessFailedCountAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.AccessFailedCount);
    public Task<bool> GetLockoutEnabledAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.LockoutEnabled);
    public Task SetLockoutEnabledAsync(AppUser u,bool v,CancellationToken c){u.LockoutEnabled=v;return Task.CompletedTask;}
    public Task SetPhoneNumberAsync(AppUser u,string? v,CancellationToken c){u.PhoneNumber=v;return Task.CompletedTask;}
    public Task<string?> GetPhoneNumberAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.PhoneNumber);
    public Task<bool> GetPhoneNumberConfirmedAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.PhoneNumberConfirmed);
    public Task SetPhoneNumberConfirmedAsync(AppUser u,bool v,CancellationToken c){u.PhoneNumberConfirmed=v;return Task.CompletedTask;}
    public Task SetSecurityStampAsync(AppUser u,string v,CancellationToken c){u.SecurityStamp=v;return Task.CompletedTask;}
    public Task<string?> GetSecurityStampAsync(AppUser u,CancellationToken c)=>Task.FromResult(u.SecurityStamp);
}
public class RoleStore(AppDbContext db) : IRoleStore<IdentityRole>
{
    public void Dispose() { }
    public Task<string> GetRoleIdAsync(IdentityRole r,CancellationToken c)=>Task.FromResult(r.Id);
    public Task<string?> GetRoleNameAsync(IdentityRole r,CancellationToken c)=>Task.FromResult(r.Name);
    public Task SetRoleNameAsync(IdentityRole r,string? v,CancellationToken c){r.Name=v;return Task.CompletedTask;}
    public Task<string?> GetNormalizedRoleNameAsync(IdentityRole r,CancellationToken c)=>Task.FromResult(r.NormalizedName);
    public Task SetNormalizedRoleNameAsync(IdentityRole r,string? v,CancellationToken c){r.NormalizedName=v;return Task.CompletedTask;}
    public Task<IdentityRole?> FindByIdAsync(string id,CancellationToken c)=>db.Roles.SingleOrDefaultAsync(x=>x.Id==id,c);
    public Task<IdentityRole?> FindByNameAsync(string name,CancellationToken c)=>db.Roles.SingleOrDefaultAsync(x=>x.NormalizedName==name,c);
    public async Task<IdentityResult> CreateAsync(IdentityRole r,CancellationToken c){db.Roles.Add(r);await db.SaveChangesAsync(c);return IdentityResult.Success;}
    public async Task<IdentityResult> UpdateAsync(IdentityRole r,CancellationToken c){db.Roles.Update(r);await db.SaveChangesAsync(c);return IdentityResult.Success;}
    public async Task<IdentityResult> DeleteAsync(IdentityRole r,CancellationToken c){db.Roles.Remove(r);await db.SaveChangesAsync(c);return IdentityResult.Success;}
}
