using AutoCar.Web.Services;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Web.Controllers;
public sealed class PhotoCreditsController(CarPhotoCatalog photos):Controller
{
    [HttpGet("/nguon-anh")]
    public IActionResult Index()=>View(photos.All.OrderBy(x=>x.Key).ToArray());
}
