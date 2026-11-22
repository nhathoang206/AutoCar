using System.Security.Claims;
using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Api.Mapping;
using AutoCar.Api.Services;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/favorites"),Authorize(Roles="Customer")]
public class FavoritesController(AppDbContext db,CarService cars) : ControllerBase
{
    private string Uid=>User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    [HttpGet]public async Task<List<CarDto>> Get()=> (await cars.Full.Where(x=>x.IsVisible&&db.Favorites.Any(f=>f.UserId==Uid&&f.CarVariantId==x.Id)).ToListAsync()).Select(x=>x.Dto()).ToList();
    [HttpPost]public async Task<IActionResult> Add(FavoriteInput i){await cars.Find(i.CarId);if(!await db.Favorites.AnyAsync(x=>x.UserId==Uid&&x.CarVariantId==i.CarId)){db.Favorites.Add(new(){UserId=Uid,CarVariantId=i.CarId});await db.SaveChangesAsync();}return StatusCode(201);}
    [HttpDelete("{carId:int}")]public async Task<IActionResult> Delete(int carId){var f=await db.Favorites.SingleOrDefaultAsync(x=>x.UserId==Uid&&x.CarVariantId==carId);if(f==null)return NotFound();db.Favorites.Remove(f);await db.SaveChangesAsync();return NoContent();}
}
[ApiController,Route("api/reviews")]
public class ReviewsController(AppDbContext db) : ControllerBase
{
    private string Uid=>User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    [HttpGet]public async Task<IActionResult> Get(int? carId=null)=>Ok(await db.Reviews.Where(x=>!carId.HasValue||x.CarVariantId==carId).OrderByDescending(x=>x.Id).Select(x=>new{x.Id,x.CarVariantId,x.Rating,x.Comment,x.CreatedAt,Author=x.User.FullName,IsMine=x.UserId==Uid}).Take(50).ToListAsync());
    [HttpPost,Authorize(Roles="Customer")]
    public async Task<IActionResult> Create(ReviewInput i)
    {
        if(!await db.OrderItems.AnyAsync(x=>x.CarVariantId==i.CarId&&x.Order.UserId==Uid&&x.Order.Status=="Completed"))throw new BusinessException(403,"Chỉ khách hàng đã hoàn tất mua xe này được đánh giá.");
        var r=new Review{UserId=Uid,CarVariantId=i.CarId,Rating=i.Rating,Comment=i.Comment};db.Reviews.Add(r);await db.SaveChangesAsync();return Created($"/api/reviews?carId={i.CarId}",new{r.Id});
    }
    [HttpPut("{id:int}"),Authorize(Roles="Customer")]
    public async Task<IActionResult> Update(int id,ReviewInput i){var r=await db.Reviews.FindAsync(id);if(r==null)return NotFound();if(r.UserId!=Uid)return Forbid();if(r.CarVariantId!=i.CarId)return BadRequest();r.Rating=i.Rating;r.Comment=i.Comment;await db.SaveChangesAsync();return NoContent();}
    [HttpDelete("{id:int}"),Authorize]
    public async Task<IActionResult> Delete(int id){var r=await db.Reviews.FindAsync(id);if(r==null)return NotFound();if(r.UserId!=Uid&&!User.IsInRole("Admin"))return Forbid();db.Reviews.Remove(r);await db.SaveChangesAsync();return NoContent();}
}
[ApiController,Route("api/test-drive-bookings"),Authorize]
public class TestDriveBookingsController(AppDbContext db,CarService cars) : ControllerBase
{
    private string Uid=>User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    [HttpGet]
    public async Task<IActionResult> Get()=>Ok(await db.TestDriveBookings.Where(x=>User.IsInRole("Admin")||(User.IsInRole("Sales")?x.AssignedSalesId==Uid:x.UserId==Uid)).OrderBy(x=>x.ScheduledAt).Select(x=>new{x.Id,x.CarVariantId,Car=x.CarVariant.CarModel.Brand.Name+" "+x.CarVariant.CarModel.Name,Customer=x.User.FullName,x.ScheduledAt,x.Phone,x.Note,x.Status,x.AssignedSalesId}).Take(200).ToListAsync());
    [HttpPost,Authorize(Roles="Customer")]
    public async Task<IActionResult> Create(BookingInput i)
    {
        await cars.Find(i.CarId);if(i.ScheduledAt<DateTimeOffset.UtcNow.AddHours(2)||i.ScheduledAt>DateTimeOffset.UtcNow.AddDays(90))throw new BusinessException(400,"Chọn lịch từ 2 giờ tới 90 ngày kể từ hiện tại.");
        var b=new TestDriveBooking{UserId=Uid,CarVariantId=i.CarId,ScheduledAt=i.ScheduledAt,Phone=i.Phone,Note=i.Note};db.TestDriveBookings.Add(b);await db.SaveChangesAsync();return Created($"/api/test-drive-bookings",new{b.Id});
    }
    [HttpPut("{id:int}"),Authorize(Roles="Admin,Sales")]
    public async Task<IActionResult> Update(int id,StatusInput i)
    {
        var b=await db.TestDriveBookings.FindAsync(id);if(b==null)return NotFound();
        if(!User.IsInRole("Admin")&&b.AssignedSalesId!=Uid)return Forbid();
        if(i.AssignedSalesId!=null){if(!User.IsInRole("Admin"))return Forbid();await Assignment.Validate(db,i.AssignedSalesId);b.AssignedSalesId=i.AssignedSalesId;}
        if(i.Status!=b.Status&&!(b.Status=="Pending"&&new[]{"Confirmed","Cancelled"}.Contains(i.Status)||b.Status=="Confirmed"&&new[]{"Completed","Cancelled"}.Contains(i.Status)))throw new BusinessException(409,"Trạng thái lịch hẹn không hợp lệ.");
        b.Status=i.Status;b.Note=i.Note??b.Note;db.Notifications.Add(new(){UserId=b.UserId,Message=$"Lịch lái thử #{id}: {b.Status}. {i.Note}"});await db.SaveChangesAsync();return NoContent();
    }
}
public static class Assignment
{
    public static async Task Validate(AppDbContext db,string id){if(!await (from l in db.UserRoles join r in db.Roles on l.RoleId equals r.Id where l.UserId==id&&r.Name=="Sales" select l).AnyAsync())throw new BusinessException(400,"Tài khoản Sales không hợp lệ.");}
}
[ApiController,Route("api/quote-requests"),Authorize]
public class QuoteRequestsController(AppDbContext db,CarService cars) : ControllerBase
{
    private string Uid=>User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    [HttpGet]public async Task<IActionResult> Get()=>Ok(await db.QuoteRequests.Where(x=>User.IsInRole("Admin")||(User.IsInRole("Sales")?x.AssignedSalesId==Uid:x.UserId==Uid)).OrderByDescending(x=>x.Id).Select(x=>new{x.Id,Car=x.CarVariant.CarModel.Name,Customer=x.User.FullName,x.Phone,x.Message,x.Status,x.Response,x.AssignedSalesId,x.CreatedAt}).Take(200).ToListAsync());
    [HttpPost,Authorize(Roles="Customer")]public async Task<IActionResult> Create(QuoteInput i){await cars.Find(i.CarId);var q=new QuoteRequest{UserId=Uid,CarVariantId=i.CarId,Phone=i.Phone,Message=i.Message};db.QuoteRequests.Add(q);await db.SaveChangesAsync();return Created("/api/quote-requests",new{q.Id});}
    [HttpPut("{id:int}/status"),Authorize(Roles="Admin,Sales")]
    public async Task<IActionResult> Status(int id,StatusInput i)
    {
        var q=await db.QuoteRequests.FindAsync(id);if(q==null)return NotFound();if(!User.IsInRole("Admin")&&q.AssignedSalesId!=Uid)return Forbid();
        if(i.AssignedSalesId!=null){if(!User.IsInRole("Admin"))return Forbid();await Assignment.Validate(db,i.AssignedSalesId);q.AssignedSalesId=i.AssignedSalesId;}
        if(i.Status!=q.Status&&!(q.Status=="Pending"&&new[]{"InProgress","Closed"}.Contains(i.Status)||q.Status=="InProgress"&&i.Status=="Closed"))throw new BusinessException(409,"Trạng thái tư vấn không hợp lệ.");
        q.Status=i.Status;q.Response=i.Note;db.Notifications.Add(new(){UserId=q.UserId,Message=$"Tư vấn #{id}: {i.Note}"});await db.SaveChangesAsync();return NoContent();
    }
}
