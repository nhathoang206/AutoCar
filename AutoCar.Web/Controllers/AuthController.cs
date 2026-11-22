using System.Security.Claims;
using AutoCar.Shared.Contracts;
using AutoCar.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Web.Controllers;
public class AuthController(AutoCarClient api,SessionVault vault) : Controller
{
    [HttpGet("/dang-nhap")]public IActionResult Login()=>View(new LoginInput());
    [HttpPost("/dang-nhap")]
    public async Task<IActionResult> Login(LoginInput input)
    {
        if(!ModelState.IsValid)return View(input);
        try{var t=await api.Authenticate("login",input);await SignIn(t);return Redirect(t.User.Roles.Contains("Admin")||t.User.Roles.Contains("Sales")?"/admin":"/tai-khoan");}
        catch(ApiException e){ModelState.AddModelError("",e.Message);}catch(HttpRequestException){ModelState.AddModelError("","API chưa sẵn sàng. Vui lòng kiểm tra dịch vụ.");}return View(input);
    }
    [HttpGet("/dang-ky")]public IActionResult Register()=>View(new RegisterInput());
    [HttpPost("/dang-ky")]
    public async Task<IActionResult> Register(RegisterInput input)
    {
        if(!ModelState.IsValid)return View(input);
        try{await SignIn(await api.Authenticate("register",input));return Redirect("/tai-khoan");}
        catch(ApiException e){ModelState.AddModelError("",e.Message);}catch(HttpRequestException){ModelState.AddModelError("","API chưa sẵn sàng.");}return View(input);
    }
    private async Task SignIn(TokenDto t)
    {
        var old=User.FindFirstValue("session");if(old!=null)vault.Remove(old);
        var claims=new List<Claim>{new("session",vault.Add(t)),new(ClaimTypes.NameIdentifier,t.User.Id),new(ClaimTypes.Name,t.User.FullName)};claims.AddRange(t.User.Roles.Select(r=>new Claim(ClaimTypes.Role,r)));
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,new ClaimsPrincipal(new ClaimsIdentity(claims,CookieAuthenticationDefaults.AuthenticationScheme)),new(){IsPersistent=false,ExpiresUtc=DateTimeOffset.UtcNow.AddHours(8)});
    }
    [Authorize,HttpPost("/dang-xuat")]
    public async Task<IActionResult> Logout()
    {
        try{using var result=await api.Send(HttpMethod.Post,"auth/logout");}catch(Exception e)when(e is HttpRequestException or ApiException){}
        var key=User.FindFirstValue("session");if(key!=null)vault.Remove(key);await HttpContext.SignOutAsync();return Redirect("/");
    }
    [HttpGet("/khong-co-quyen")]public IActionResult Denied(){Response.StatusCode=403;return View();}
}
