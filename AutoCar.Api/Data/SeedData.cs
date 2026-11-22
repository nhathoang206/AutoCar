using AutoCar.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Data;
public static class SeedData
{
    public static async Task Run(IServiceProvider services,IConfiguration config)
    {
        var db=services.GetRequiredService<AppDbContext>();var roles=services.GetRequiredService<RoleManager<IdentityRole>>();var users=services.GetRequiredService<UserManager<AppUser>>();
        foreach(var role in new[]{"Admin","Sales","Customer"})if(!await roles.RoleExistsAsync(role))await roles.CreateAsync(new(role));
        var password=config["Seed:Password"];
        if(!string.IsNullOrWhiteSpace(password))
        {
            var accounts=new[]{("admin@autocar.local","Quản trị AutoCar","Admin"),("sales@autocar.local","Tư vấn AutoCar","Sales"),("customer1@autocar.local","Nguyễn Minh Anh","Customer"),("customer2@autocar.local","Trần Hoàng Nam","Customer"),("customer3@autocar.local","Lê Thanh Hà","Customer"),("customer4@autocar.local","Phạm Gia Huy","Customer"),("customer5@autocar.local","Võ Ngọc Mai","Customer")};
            foreach(var (email,name,role) in accounts)if(await users.FindByEmailAsync(email)==null)
            {
                var u=new AppUser{UserName=email,Email=email,FullName=name,PhoneNumber="0900000000",LockoutEnabled=true};var result=await users.CreateAsync(u,password);if(!result.Succeeded)throw new InvalidOperationException(string.Join(";",result.Errors.Select(x=>x.Description)));await users.AddToRoleAsync(u,role);
            }
        }
        await DevelopmentAdminDefaults.Apply(services,config);
        var catalog=new (string Brand,string[] Models)[]{("Audi",["A4","A6","Q5","Q7"]),("Toyota",["Vios","Corolla Cross","Camry","Fortuner"]),("Honda",["City","Civic","CR-V"]),("Hyundai",["Accent","Tucson","Santa Fe"]),("Volvo",["XC60","XC90"]),("Mercedes-Benz",["C-Class","E-Class","GLC"]),("BMW",["3 Series","5 Series","X5"]),("Kia",["K3","Sportage","Sorento"]),("Ford",["Everest","Ranger"]),("Mazda",["Mazda3","CX-5"]),("Lexus",["ES","RX"]),("Porsche",["Macan","Cayenne"]),("Volkswagen",["Tiguan","Teramont"]),("Mitsubishi",["Xpander","Outlander"]),("VinFast",["VF 7","VF 8"])};
        var n=0;
        foreach(var (brand,models) in catalog)
        {
            var b=await db.Brands.SingleOrDefaultAsync(x=>x.Name==brand);if(b==null){b=new(){Name=brand};db.Brands.Add(b);await db.SaveChangesAsync();}
            foreach(var model in models)
            {
                var m=await db.CarModels.SingleOrDefaultAsync(x=>x.BrandId==b.Id&&x.Name==model);if(m==null){m=new(){BrandId=b.Id,Name=model};db.CarModels.Add(m);await db.SaveChangesAsync();}
                for(var v=0;v<2;v++)
                {
                    n++;var code=$"DEMO-{b.Id:D2}-{m.Id:D3}-{v}";if(await db.CarVariants.AnyAsync(x=>x.Code==code))continue;
                    db.CarVariants.Add(new(){CarModelId=m.Id,Code=code,Name=v==0?"Standard (minh họa)":"Premium (minh họa)",Year=2025,Price=450000000m+n*47000000m+v*120000000m,Seats=n%3==0?7:5,Fuel=brand=="VinFast"?"Điện":n%4==0?"Hybrid":"Xăng",Transmission=n%7==0?"Số sàn":"Tự động",BodyStyle=n%3==0?"SUV":n%3==1?"Sedan":"Crossover",Origin="Minh họa",Engine="Thông số minh họa",Power="Chưa xác minh",Torque="Chưa xác minh",Drivetrain="Minh họa",Colors="Trắng, Đen, Bạc",Dimensions="Chưa xác minh",Consumption="Chưa xác minh",Description="Sản phẩm phục vụ đồ án. Giá, phiên bản và thông số là dữ liệu minh họa; không phải báo giá thị trường. Hình vẽ xe chỉ minh họa kiểu dáng.",IsFeatured=n%5==0,Inventory=new(){Stock=n%9==0?0:n%5+1}});
                }
            }
        }
        if(!await db.Promotions.AnyAsync())db.Promotions.Add(new(){Title="Khởi đầu hành trình mới",Description="Đăng ký tư vấn và trải nghiệm lái thử. Chương trình minh họa dành cho đồ án AutoCar.",StartsAt=DateTimeOffset.UtcNow.AddDays(-1),EndsAt=DateTimeOffset.UtcNow.AddYears(1)});
        await db.SaveChangesAsync();
    }
}
