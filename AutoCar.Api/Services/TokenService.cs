using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace AutoCar.Api.Services;
public class JwtSettings
{
    public string Key { get; set; } = "";
    public string Issuer { get; set; } = "AutoCar.Api";
    public string Audience { get; set; } = "AutoCar.Web";
    public TokenValidationParameters Validation => new()
    {
        ValidateIssuer=true, ValidIssuer=Issuer, ValidateAudience=true, ValidAudience=Audience,
        ValidateIssuerSigningKey=true, IssuerSigningKey=new SymmetricSecurityKey(Encoding.UTF8.GetBytes(Key)),
        ValidateLifetime=true, ClockSkew=TimeSpan.FromSeconds(15), ValidAlgorithms=[SecurityAlgorithms.HmacSha256]
    };
}
public class TokenService(AppDbContext db,UserManager<AppUser> users,JwtSettings settings)
{
    public static string Hash(string token)=>Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    public async Task<UserDto> Profile(AppUser u)=>new(u.Id,u.Email!,u.FullName,u.PhoneNumber,u.Address,(await users.GetRolesAsync(u)).ToArray());
    public async Task<TokenDto> Issue(AppUser u)
    {
        var refresh=Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var session=new RefreshSession{UserId=u.Id,TokenHash=Hash(refresh),ExpiresAt=DateTimeOffset.UtcNow.AddDays(7)};
        db.RefreshSessions.Add(session);await db.SaveChangesAsync();
        var profile=await Profile(u);
        var expires=DateTimeOffset.UtcNow.AddMinutes(15);
        var claims=new List<Claim>{new(ClaimTypes.NameIdentifier,u.Id),new(ClaimTypes.Name,u.FullName),new("sid",session.Id.ToString())};
        claims.AddRange(profile.Roles.Select(r=>new Claim(ClaimTypes.Role,r)));
        var jwt=new JwtSecurityToken(settings.Issuer,settings.Audience,claims,expires:expires.UtcDateTime,
            signingCredentials:new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.Key)),SecurityAlgorithms.HmacSha256));
        return new(new JwtSecurityTokenHandler().WriteToken(jwt),refresh,expires,profile);
    }
}
public class JwtAuthenticationHandler(IOptionsMonitor<AuthenticationSchemeOptions> options,ILoggerFactory logger,
    UrlEncoder encoder,JwtSettings settings,AppDbContext db) : AuthenticationHandler<AuthenticationSchemeOptions>(options,logger,encoder)
{
    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var header=Request.Headers.Authorization.ToString();
        if(!header.StartsWith("Bearer ",StringComparison.OrdinalIgnoreCase))return AuthenticateResult.NoResult();
        try
        {
            var principal=new JwtSecurityTokenHandler().ValidateToken(header[7..],settings.Validation,out _);
            var uid=principal.FindFirstValue(ClaimTypes.NameIdentifier);
            if(!int.TryParse(principal.FindFirstValue("sid"),out var sid))return AuthenticateResult.Fail("Invalid session");
            var valid=await db.RefreshSessions.AnyAsync(x=>x.Id==sid&&x.UserId==uid&&!x.Revoked&&x.ExpiresAt>DateTimeOffset.UtcNow);
            var u=await db.Users.FindAsync(uid);
            if(!valid||u==null||u.LockoutEnd>DateTimeOffset.UtcNow)return AuthenticateResult.Fail("Session expired");
            // Roles are read from the database so demotion is effective immediately.
            var identity=(ClaimsIdentity)principal.Identity!;
            foreach(var claim in identity.FindAll(ClaimTypes.Role).ToArray())identity.RemoveClaim(claim);
            var roles=await (from l in db.UserRoles join r in db.Roles on l.RoleId equals r.Id where l.UserId==uid select r.Name!).ToListAsync();
            identity.AddClaims(roles.Select(x=>new Claim(ClaimTypes.Role,x)));
            return AuthenticateResult.Success(new AuthenticationTicket(principal,Scheme.Name));
        }
        catch(SecurityTokenException){return AuthenticateResult.Fail("Token invalid or expired");}
        catch(ArgumentException){return AuthenticateResult.Fail("Malformed token");}
    }
}
