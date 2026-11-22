using System.ComponentModel.DataAnnotations;

namespace AutoCar.Shared.Contracts;

public record PageResult<T>(IReadOnlyList<T> Items, int Total, int Page, int PageSize);
public class BrandInput
{
    [Required, StringLength(80)] public string Name { get; set; } = "";
    [StringLength(300)] public string? LogoUrl { get; set; }
    public bool IsActive { get; set; } = true;
}
public record BrandDto(int Id, string Name, string? LogoUrl, bool IsActive);
public class CarInput
{
    [Range(1,int.MaxValue)] public int CarModelId { get; set; }
    [Required, StringLength(50)] public string Code { get; set; } = "";
    [Required, StringLength(120)] public string Name { get; set; } = "";
    [Range(1990,2100)] public int Year { get; set; } = 2025;
    [Range(typeof(decimal),"0","9999999999999999")] public decimal Price { get; set; }
    [Range(2,16)] public int Seats { get; set; } = 5;
    [Required, StringLength(40)] public string Fuel { get; set; } = "Xăng";
    [Required, StringLength(40)] public string Transmission { get; set; } = "Tự động";
    [Required, StringLength(40)] public string BodyStyle { get; set; } = "SUV";
    [StringLength(80)] public string Origin { get; set; } = "Dữ liệu minh họa";
    [StringLength(80)] public string Engine { get; set; } = "Minh họa";
    [StringLength(80)] public string Power { get; set; } = "Minh họa";
    [StringLength(80)] public string Torque { get; set; } = "Minh họa";
    [StringLength(80)] public string Drivetrain { get; set; } = "Minh họa";
    [StringLength(120)] public string Colors { get; set; } = "Trắng, Đen";
    [StringLength(120)] public string Dimensions { get; set; } = "Minh họa";
    [StringLength(100)] public string Consumption { get; set; } = "Minh họa";
    [StringLength(4000)] public string Description { get; set; } = "";
    [Range(0,10000)] public int Stock { get; set; }
    public bool IsFeatured { get; set; }
    public bool IsVisible { get; set; } = true;
    [Required,MaxLength(12)] public string[] Images { get; set; } = [];
    public string? RowVersion { get; set; }
    public string? InventoryVersion { get; set; }
}
public class CarDto : CarInput
{
    public int Id { get; set; }
    public int BrandId { get; set; }
    public string Brand { get; set; } = "";
    public string Model { get; set; } = "";
    public int Sold { get; set; }
    public int Views { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public string DisplayName => $"{Brand} {Model} {Name}";
}
public class CarQuery
{
    public string? Search { get; set; }
    public int? BrandId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public int? Year { get; set; }
    public int? Seats { get; set; }
    public string? Fuel { get; set; }
    public string? Transmission { get; set; }
    public string? BodyStyle { get; set; }
    public bool? InStock { get; set; }
    public bool? Featured { get; set; }
    public bool IncludeHidden { get; set; }
    public string Sort { get; set; } = "newest";
    [Range(1,100000)] public int Page { get; set; } = 1;
    [Range(1,100)] public int PageSize { get; set; } = 12;
}
public class ModelInput
{
    [Range(1,int.MaxValue)] public int BrandId { get; set; }
    [Required,StringLength(100)] public string Name { get; set; } = "";
}
public record ModelDto(int Id,int BrandId,string Name,string Brand);
public class LoginInput
{
    [Required,StringLength(256)] public string Email { get; set; } = "";
    [Required,StringLength(128)] public string Password { get; set; } = "";
}
public class RegisterInput
{
    [Required,EmailAddress] public string Email { get; set; } = "";
    [Required,StringLength(128)] public string Password { get; set; } = "";
    [Required,StringLength(100)] public string FullName { get; set; } = "";
    [Phone] public string? Phone { get; set; }
}
public record UserDto(string Id,string Email,string FullName,string? Phone,string? Address,string[] Roles);
public record TokenDto(string AccessToken,string RefreshToken,DateTimeOffset ExpiresAt,UserDto User);
public record RefreshInput([Required] string RefreshToken);
public class ProfileInput
{
    [Required,StringLength(100)] public string FullName { get; set; } = "";
    [Phone] public string? Phone { get; set; }
    [StringLength(300)] public string? Address { get; set; }
}
public record PasswordInput([Required] string CurrentPassword,[Required,MinLength(10)] string NewPassword);
public record FavoriteInput([Range(1,int.MaxValue)] int CarId);
public record OrderInput([Range(1,int.MaxValue)] int CarId,[Range(1,5)] int Quantity,[StringLength(1000)] string? Note);
public record StatusInput([Required] string Status,string? Note,string? AssignedSalesId);
public class BookingInput
{
    [Range(1,int.MaxValue)] public int CarId { get; set; }
    public DateTimeOffset ScheduledAt { get; set; }
    [Required,Phone] public string Phone { get; set; } = "";
    [StringLength(1000)] public string? Note { get; set; }
}
public record QuoteInput([Range(1,int.MaxValue)] int CarId,[Required,Phone] string Phone,[StringLength(1000)] string? Message);
public record ReviewInput([Range(1,int.MaxValue)] int CarId,[Range(1,5)] int Rating,[Required,StringLength(2000)] string Comment);
public record ContactInput([Required,StringLength(100)] string Name,[Required,EmailAddress] string Email,[Required,StringLength(2000)] string Message);
public record PaymentInput([Range(typeof(decimal),"0.01","9999999999999999")] decimal Amount,[Required,StringLength(200)] string Reference);
public record UserAdminInput([Required] string Role,bool Locked);
public class DashboardDto
{
    public int Cars { get; set; }
    public int Brands { get; set; }
    public int InStock { get; set; }
    public int Sold { get; set; }
    public int Customers { get; set; }
    public int Orders { get; set; }
    public int PendingOrders { get; set; }
    public int UpcomingBookings { get; set; }
    public decimal Revenue { get; set; }
}
public record PromotionDto(int Id,string Title,string Description,DateTimeOffset StartsAt,DateTimeOffset EndsAt);
public record ReviewDto(int Id,int CarVariantId,int Rating,string Comment,DateTimeOffset CreatedAt,string Author,bool IsMine);
