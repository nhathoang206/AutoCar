using System.Data;
using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Shared.Contracts;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Services;
public static class OrderRules
{
    public static bool CanTransition(string from,string to)=> (from,to) is
        ("Pending","Confirmed") or ("Pending","Cancelled") or ("Pending","Rejected") or
        ("Confirmed","Completed") or ("Confirmed","Cancelled");
    public static bool RecognizesRevenue(string status,string payment)=>status=="Completed"&&payment=="Paid";
}
public class OrderService(AppDbContext db)
{
    public async Task<Order> Create(string uid,OrderInput i)
    {
        var c=await db.CarVariants.Include(x=>x.Inventory).Include(x=>x.CarModel.Brand).SingleOrDefaultAsync(x=>x.Id==i.CarId&&x.IsVisible&&x.CarModel.Brand.IsActive)??throw new BusinessException(404,"Xe không tồn tại.");
        if(c.Inventory.Stock<i.Quantity)throw new BusinessException(409,"Số lượng xe hiện có không đủ.");
        if(c.Price<=0)throw new BusinessException(409,"Xe chưa có giá đặt hàng. Vui lòng gửi yêu cầu báo giá.");
        var o=new Order{UserId=uid,Total=c.Price*i.Quantity,Note=i.Note,Items=[new(){CarVariantId=c.Id,Quantity=i.Quantity,UnitPrice=c.Price}],History=[new(){Status="Pending",ActorId=uid,Note="Tạo yêu cầu đặt xe; chưa giữ tồn kho."}]};
        db.Orders.Add(o);await db.SaveChangesAsync();return o;
    }
    public async Task Change(int id,StatusInput input,string actor,bool admin)
    {
        await using var tx=await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var o=await db.Orders.Include(x=>x.Items).ThenInclude(x=>x.CarVariant.Inventory).Include(x=>x.Payments).SingleOrDefaultAsync(x=>x.Id==id)??throw new BusinessException(404,"Đơn không tồn tại.");
        if(!admin&&o.AssignedSalesId!=actor)throw new BusinessException(403,"Đơn chưa được phân công cho bạn.");
        if(input.AssignedSalesId!=null)
        {
            if(!admin)throw new BusinessException(403,"Chỉ Admin được phân công.");
            if(!await (from u in db.Users join l in db.UserRoles on u.Id equals l.UserId join r in db.Roles on l.RoleId equals r.Id where u.Id==input.AssignedSalesId&&r.Name=="Sales"&&(!u.LockoutEnd.HasValue||u.LockoutEnd<=DateTimeOffset.UtcNow) select u).AnyAsync())throw new BusinessException(400,"Nhân viên Sales không hợp lệ.");
            o.AssignedSalesId=input.AssignedSalesId;
        }
        if(input.Status!=o.Status)
        {
            if(!OrderRules.CanTransition(o.Status,input.Status))throw new BusinessException(409,"Chuyển trạng thái đơn không hợp lệ.");
            if(input.Status=="Confirmed")foreach(var item in o.Items)
            {
                var inventory=item.CarVariant.Inventory;
                if(inventory.Stock<item.Quantity)throw new BusinessException(409,"Không đủ tồn kho để xác nhận đơn.");
                inventory.Stock-=item.Quantity;inventory.Sold+=item.Quantity;
            }
            if(input.Status=="Cancelled"&&o.Status=="Confirmed")foreach(var item in o.Items){item.CarVariant.Inventory.Stock+=item.Quantity;item.CarVariant.Inventory.Sold-=item.Quantity;}
            if(input.Status=="Cancelled"&&o.Payments.Count>0)o.PaymentStatus="RefundRequired";
            if(input.Status=="Completed")
            {
                if(o.PaymentStatus!="Paid")throw new BusinessException(409,"Cần xác nhận thanh toán đủ trước khi hoàn tất.");
                o.CompletedAt=DateTimeOffset.UtcNow;
            }
            o.Status=input.Status;
        }
        o.History.Add(new(){ActorId=actor,Status=o.Status,Note=input.Note});
        db.Notifications.Add(new(){UserId=o.UserId,Message=$"Đơn #{id}: {o.Status}. {input.Note}"});
        db.AuditLogs.Add(new(){ActorId=actor,Action="OrderStatus",Resource=$"Order/{id}/{o.Status}"});
        await db.SaveChangesAsync();await tx.CommitAsync();
    }
    public async Task Pay(int id,PaymentInput i,string actor)
    {
        await using var tx=await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var o=await db.Orders.Include(x=>x.Payments).SingleOrDefaultAsync(x=>x.Id==id)??throw new BusinessException(404,"Không tìm thấy đơn.");
        if(o.Status!="Confirmed")throw new BusinessException(409,"Chỉ ghi nhận thanh toán đơn đã xác nhận.");
        var paid=o.Payments.Sum(x=>x.Amount);
        if(i.Amount+paid>o.Total)throw new BusinessException(409,"Thanh toán vượt giá trị đơn.");
        db.Payments.Add(new(){OrderId=id,Amount=i.Amount,Reference=i.Reference.Trim(),ConfirmedById=actor});
        o.PaymentStatus=paid+i.Amount==o.Total?"Paid":"Partial";
        o.History.Add(new(){ActorId=actor,Status=o.Status,Note=$"Xác nhận chuyển khoản thủ công: {i.Amount:N0} VNĐ"});
        db.AuditLogs.Add(new(){ActorId=actor,Action="ManualPayment",Resource=$"Order/{id}"});
        await db.SaveChangesAsync();await tx.CommitAsync();
    }
}
