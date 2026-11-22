using System.Security.Claims;
using AutoCar.Api.Data;
using AutoCar.Api.Services;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/[controller]"),Authorize]
public class OrdersController(AppDbContext db,OrderService service) : ControllerBase
{
    private string Uid=>User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    private IQueryable<Models.Order> Accessible=>db.Orders.Where(x=>User.IsInRole("Admin")||(User.IsInRole("Sales")?x.AssignedSalesId==Uid:x.UserId==Uid));
    [HttpGet]
    public async Task<IActionResult> List(int page=1,int pageSize=20,string? search=null,string? status=null)
    {
        if(page<1||page>100000||pageSize<1||pageSize>100)return BadRequest();
        var q=Accessible;
        if(!string.IsNullOrWhiteSpace(search))q=q.Where(x=>x.User.FullName.Contains(search)||x.Status.Contains(search)||x.Items.Any(i=>i.CarVariant.CarModel.Name.Contains(search)));
        if(!string.IsNullOrWhiteSpace(status))q=q.Where(x=>x.Status==status);
        var items=await q.OrderByDescending(x=>x.Id).Skip((page-1)*pageSize).Take(pageSize).Select(x=>new{x.Id,x.Status,x.PaymentStatus,x.Total,x.CreatedAt,x.AssignedSalesId,Customer=x.User.FullName,Items=x.Items.Select(i=>new{i.CarVariantId,Name=i.CarVariant.CarModel.Brand.Name+" "+i.CarVariant.CarModel.Name+" "+i.CarVariant.Name,i.Quantity,i.UnitPrice})}).ToListAsync();
        return Ok(new{items,total=await q.CountAsync(),page,pageSize});
    }
    [HttpGet("{id:int}")]
    public async Task<IActionResult> Get(int id)
    {
        var o=await Accessible.Where(x=>x.Id==id).Select(x=>new{x.Id,x.Status,x.Total,x.PaymentStatus,x.CreatedAt,x.Note,x.AssignedSalesId,Customer=x.User.FullName,Items=x.Items.Select(i=>new{i.CarVariantId,Name=i.CarVariant.CarModel.Brand.Name+" "+i.CarVariant.CarModel.Name,i.Quantity,i.UnitPrice}),History=x.History.OrderBy(h=>h.At).Select(h=>new{h.Status,h.Note,h.At,Actor=h.Actor.FullName}),Payments=x.Payments.Select(p=>new{p.Amount,p.Reference,p.At})}).SingleOrDefaultAsync();
        return o==null?NotFound():Ok(o);
    }
    [HttpPost,Authorize(Roles="Customer")]
    public async Task<IActionResult> Create(OrderInput i){var o=await service.Create(Uid,i);return CreatedAtAction(nameof(Get),new{id=o.Id},new{o.Id,o.Status,o.Total});}
    [HttpPut("{id:int}/status"),Authorize(Roles="Admin,Sales")]
    public async Task<IActionResult> Status(int id,StatusInput i){await service.Change(id,i,Uid,User.IsInRole("Admin"));return NoContent();}
    [HttpPost("{id:int}/cancel"),Authorize(Roles="Customer")]
    public async Task<IActionResult> Cancel(int id)
    {
        var o=await db.Orders.SingleOrDefaultAsync(x=>x.Id==id&&x.UserId==Uid);if(o==null)return NotFound();
        if(o.Status!="Pending")throw new BusinessException(409,"Chỉ tự hủy đơn đang chờ; vui lòng liên hệ cửa hàng với đơn đã xác nhận.");
        await service.Change(id,new("Cancelled","Khách hàng hủy",null),Uid,true);return NoContent();
    }
    [HttpPost("{id:int}/payments"),Authorize(Roles="Admin")]
    public async Task<IActionResult> Pay(int id,PaymentInput i){await service.Pay(id,i,Uid);return StatusCode(201);}
}
