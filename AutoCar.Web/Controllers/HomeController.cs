using AutoCar.Shared.Contracts;
using AutoCar.Web.Services;
using AutoCar.Web.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Web.Controllers;
public class HomeController(AutoCarClient api) : Controller
{
    public async Task<IActionResult> Index()
    {
        try
        {
            var latest=api.Get<PageResult<CarDto>>("cars?pageSize=6");var featured=api.Get<PageResult<CarDto>>("cars/featured");var brands=api.Get<PageResult<BrandDto>>("brands");var promotions=api.Get<List<PromotionDto>>("public/promotions");var reviews=api.Get<List<ReviewDto>>("reviews");
            await Task.WhenAll(latest,featured,brands,promotions,reviews);
            return View(new HomeVm(latest.Result,featured.Result,brands.Result,promotions.Result,reviews.Result));
        }
        catch(Exception e)when(e is HttpRequestException or ApiException or TaskCanceledException)
        {
            Response.StatusCode=503;
            return View(new HomeVm(new([],0,1,6),new([],0,1,6),new([],0,1,30),[],[],"Chưa tải được dữ liệu showroom từ API/SQL Server. Vui lòng kiểm tra kết nối database và khởi động AutoCar.Api. Các danh sách được để trống; không hiển thị dữ liệu thay thế."));
        }
    }
    [HttpGet("/xe")]
    public async Task<IActionResult> Cars([FromQuery]CarQuery q)
    {
        if(!ModelState.IsValid){Response.StatusCode=400;ViewBag.Message="Bộ lọc không hợp lệ.";return View("Unavailable");}
        var query=Microsoft.AspNetCore.WebUtilities.QueryHelpers.AddQueryString("cars",Request.Query.ToDictionary(x=>x.Key,x=>(string?)x.Value.ToString()));
        return View(new CatalogVm(await api.Get<PageResult<CarDto>>(query),await api.Get<PageResult<BrandDto>>("brands"),q));
    }
    [HttpGet("/xe/{id:int}/{slug?}")]
    public async Task<IActionResult> Detail(int id,string? slug){var c=await api.Get<CarDto>($"cars/{id}");ViewBag.Has360=(await api.Get<PageResult<CarDto>>("cars/featured")).Items.Take(3).Any(x=>x.Id==id);return View(new DetailVm(c,await api.Get<PageResult<CarDto>>($"cars?brandId={c.BrandId}&pageSize=4")));}
    [HttpGet("/hang-xe")]public async Task<IActionResult> Brands()=>View(await api.Get<PageResult<BrandDto>>("brands"));
    [HttpGet("/so-sanh")]public IActionResult Compare()=>View();
    [HttpGet("/tai-khoan"),Authorize]public IActionResult Account()=>View();
    [HttpGet("/tin-tuc/{slug?}")]public IActionResult News(string? slug){ViewBag.Slug=slug;return View();}
    [HttpGet("/gioi-thieu")]public IActionResult About()=>View();
    [HttpGet("/lien-he")]public IActionResult Contact()=>View();
    [HttpGet("/loi")]public IActionResult Unavailable()=>View();
}
