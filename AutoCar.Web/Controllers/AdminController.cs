using AutoCar.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Web.Controllers;
[Authorize(Roles="Admin,Sales"),Route("admin")]
public class AdminController : Controller
{
    [HttpGet("{module?}")]
    public IActionResult Index(string module="dashboard")
    {
        var modules=new[]{"dashboard","brands","cars","models","orders","bookings","quotes","users","reports","contacts","audit"};
        if(!modules.Contains(module))return NotFound();
        if(User.IsInRole("Sales")&&!new[]{"dashboard","orders","bookings","quotes"}.Contains(module))return Forbid();
        ViewBag.Module=module;return View();
    }
}
