using AutoCar.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace AutoCar.Api.Data;

// Invoked only by Development startup seeding or the explicit database seed command.
// A demo admin password is configured locally; normal registration policy is unchanged.
public static class DevelopmentAdminDefaults
{
    public static async Task Apply(IServiceProvider services,IConfiguration config)
    {
        var name=config["Seed:AdminUserName"];
        var password=config["Seed:AdminPassword"];
        if(string.IsNullOrWhiteSpace(name)||string.IsNullOrEmpty(password))return;
        var users=services.GetRequiredService<UserManager<AppUser>>();
        var db=services.GetRequiredService<AppDbContext>();
        var admin=await users.FindByEmailAsync("admin@autocar.local")??throw new InvalidOperationException("Seed the development administrator before applying its configured defaults.");
        if(!await users.IsInRoleAsync(admin,"Admin"))throw new InvalidOperationException("Development defaults can only update the seeded Admin account.");
        if(admin.UserName==name&&await users.CheckPasswordAsync(admin,password))return;
        await using var transaction=await db.Database.BeginTransactionAsync();
        admin.UserName=name.Trim();
        admin.PasswordHash=users.PasswordHasher.HashPassword(admin,password);
        admin.SecurityStamp=Guid.NewGuid().ToString();
        admin.ConcurrencyStamp=Guid.NewGuid().ToString();
        admin.LockoutEnd=null;admin.AccessFailedCount=0;
        var result=await users.UpdateAsync(admin);
        if(!result.Succeeded)throw new InvalidOperationException(string.Join("; ",result.Errors.Select(x=>x.Description)));
        await db.RefreshSessions.Where(x=>x.UserId==admin.Id).ExecuteUpdateAsync(s=>s.SetProperty(x=>x.Revoked,true));
        db.AuditLogs.Add(new(){ActorId=admin.Id,Action="DevelopmentAdminDefaults",Resource=$"User/{admin.Id}"});
        await db.SaveChangesAsync();await transaction.CommitAsync();
    }
}
