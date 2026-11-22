using System.Text;
using AutoCar.Api.Data;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/[controller]"),Authorize(Roles="Admin")]
public class DashboardController(AppDbContext db) : ControllerBase
{
    [HttpGet("overview")]
    public async Task<DashboardDto> Overview()=>new()
    {
        Cars=await db.CarVariants.CountAsync(),Brands=await db.Brands.CountAsync(),InStock=await db.CarInventories.SumAsync(x=>x.Stock),Sold=await db.CarInventories.SumAsync(x=>x.Sold),
        Customers=await (from l in db.UserRoles join r in db.Roles on l.RoleId equals r.Id where r.Name=="Customer" select l).CountAsync(),
        Orders=await db.Orders.CountAsync(),PendingOrders=await db.Orders.CountAsync(x=>x.Status=="Pending"),UpcomingBookings=await db.TestDriveBookings.CountAsync(x=>x.ScheduledAt>DateTimeOffset.UtcNow&&(x.Status=="Pending"||x.Status=="Confirmed")),
        Revenue=await db.Orders.Where(x=>x.Status=="Completed"&&x.PaymentStatus=="Paid").SumAsync(x=>(decimal?)x.Total)??0
    };
    [HttpGet("revenue")]
    public async Task<IActionResult> Revenue(DateTimeOffset? from=null,DateTimeOffset? to=null,int? brandId=null)
    {
        var rows=await RevenueQuery(from,to,brandId).Select(x=>new {At=x.Order.CompletedAt!.Value,x.Quantity,x.UnitPrice}).ToListAsync();
        return Ok(rows.GroupBy(x=>x.At.ToOffset(TimeSpan.FromHours(7)).ToString("yyyy-MM")).OrderBy(x=>x.Key).Select(g=>new{label=g.Key,value=g.Sum(x=>x.Quantity*x.UnitPrice)}));
    }
    private IQueryable<Models.OrderItem> RevenueQuery(DateTimeOffset? from,DateTimeOffset? to,int? brandId)
    {
        var q=db.OrderItems.Where(x=>x.Order.Status=="Completed"&&x.Order.PaymentStatus=="Paid");
        if(from.HasValue)q=q.Where(x=>x.Order.CompletedAt>=from);if(to.HasValue)q=q.Where(x=>x.Order.CompletedAt<to);if(brandId.HasValue)q=q.Where(x=>x.CarVariant.CarModel.BrandId==brandId);return q;
    }
    [HttpGet("orders")]public async Task<IActionResult> Orders()=>Ok(await db.Orders.GroupBy(x=>x.Status).Select(g=>new{label=g.Key,value=g.Count()}).ToListAsync());
    [HttpGet("top-cars")]public async Task<IActionResult> TopCars()=>Ok(await db.CarVariants.OrderByDescending(x=>x.Views).Take(5).Select(x=>new{label=x.CarModel.Brand.Name+" "+x.CarModel.Name+" "+x.Name,value=x.Views}).ToListAsync());
    [HttpGet("top-brands")]public async Task<IActionResult> TopBrands()=>Ok(await db.OrderItems.Where(x=>x.Order.Status=="Completed"&&x.Order.PaymentStatus=="Paid").GroupBy(x=>x.CarVariant.CarModel.Brand.Name).Select(g=>new{label=g.Key,value=g.Sum(x=>x.Quantity),revenue=g.Sum(x=>x.UnitPrice*x.Quantity)}).OrderByDescending(x=>x.value).ToListAsync());
    [HttpGet("export")]
    public async Task<IActionResult> Export(DateTimeOffset? from=null,DateTimeOffset? to=null,int? brandId=null)
    {
        var rows=await RevenueQuery(from,to,brandId).Select(x=>new{x.OrderId,x.Order.CompletedAt,x.CarVariant.Code,x.Quantity,x.UnitPrice}).ToListAsync();
        var csv="OrderId,CompletedAt,CarCode,Quantity,UnitPrice,Total\r\n"+string.Join("\r\n",rows.Select(x=>$"{x.OrderId},{x.CompletedAt:O},{Csv(x.Code)},{x.Quantity},{x.UnitPrice.ToString(System.Globalization.CultureInfo.InvariantCulture)},{(x.Quantity*x.UnitPrice).ToString(System.Globalization.CultureInfo.InvariantCulture)}"));
        return File(Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(csv)).ToArray(),"text/csv","AutoCar-Revenue.csv");
    }
    private static string Csv(string text)=>"\""+(text.Length>0&&"=+-@".Contains(text[0])?"'":"")+text.Replace("\"","\"\"")+"\"";
}
