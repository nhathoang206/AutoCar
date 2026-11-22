using System.Security.Claims;
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
[ApiController,Route("api/[controller]")]
public class AuthController(UserManager<AppUser> users,TokenService tokens,AppDbContext db) : ControllerBase
{
    [HttpPost("register"),EnableRateLimiting("auth")]
    public async Task<IActionResult> Register(RegisterInput input)
    {
        var u=new AppUser{UserName=input.Email,Email=input.Email,FullName=input.FullName,PhoneNumber=input.Phone,LockoutEnabled=true};
        var result=await users.CreateAsync(u,input.Password);
        if(!result.Succeeded)return BadRequest(new ProblemDetails{Title=string.Join(" ",result.Errors.Select(x=>x.Description)),Status=400});
        await users.AddToRoleAsync(u,"Customer");
        return StatusCode(201,await tokens.Issue(u));
    }
    [HttpPost("login"),EnableRateLimiting("auth")]
    public async Task<IActionResult> Login(LoginInput input)
    {
        var identifier=input.Email.Trim();
        var u=identifier.Contains('@')?await users.FindByEmailAsync(identifier):await users.FindByNameAsync(identifier);
        if(u==null||await users.IsLockedOutAsync(u))return Unauthorized(new ProblemDetails{Title="Email hoặc mật khẩu không hợp lệ.",Status=401});
        if(!await users.CheckPasswordAsync(u,input.Password)) {await users.AccessFailedAsync(u);return Unauthorized(new ProblemDetails{Title="Email hoặc mật khẩu không hợp lệ.",Status=401});}
        await users.ResetAccessFailedCountAsync(u);
        return Ok(await tokens.Issue(u));
    }
    [HttpPost("refresh"),EnableRateLimiting("auth")]
    public async Task<IActionResult> Refresh(RefreshInput input)
    {
        await using var tx=await db.Database.BeginTransactionAsync();
        var hash=TokenService.Hash(input.RefreshToken);
        var s=await db.RefreshSessions.SingleOrDefaultAsync(x=>x.TokenHash==hash&&!x.Revoked);
        if(s==null||s.ExpiresAt<=DateTimeOffset.UtcNow)return Unauthorized();
        var u=await users.FindByIdAsync(s.UserId);
        if(u==null||await users.IsLockedOutAsync(u))return Unauthorized();
        s.Revoked=true;await db.SaveChangesAsync();
        var result=await tokens.Issue(u);await tx.CommitAsync();return Ok(result);
    }
    [HttpPost("logout"),Authorize]
    public async Task<IActionResult> Logout()
    {
        var sid=int.Parse(User.FindFirstValue("sid")!);
        var s=await db.RefreshSessions.FindAsync(sid);if(s!=null)s.Revoked=true;
        await db.SaveChangesAsync();return NoContent();
    }
    [HttpGet("me"),Authorize]
    public async Task<UserDto> Me()=>await tokens.Profile((await users.GetUserAsync(User))!);
    [HttpPut("me"),Authorize]
    public async Task<IActionResult> Profile(ProfileInput input)
    {
        var u=(await users.GetUserAsync(User))!;u.FullName=input.FullName;u.PhoneNumber=input.Phone;u.Address=input.Address;
        await users.UpdateAsync(u);return NoContent();
    }
    [HttpPost("change-password"),Authorize]
    public async Task<IActionResult> Password(PasswordInput input)
    {
        var u=(await users.GetUserAsync(User))!;var result=await users.ChangePasswordAsync(u,input.CurrentPassword,input.NewPassword);
        if(!result.Succeeded)return BadRequest(new ProblemDetails{Title=string.Join(" ",result.Errors.Select(x=>x.Description)),Status=400});
        await db.RefreshSessions.Where(x=>x.UserId==u.Id).ExecuteUpdateAsync(x=>x.SetProperty(s=>s.Revoked,true));return NoContent();
    }
}
