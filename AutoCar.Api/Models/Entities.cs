using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace AutoCar.Api.Models;

public abstract class Entity { public int Id { get; set; } }
public class AppUser : IdentityUser
{
    [MaxLength(100)] public string FullName { get; set; } = "";
    [MaxLength(300)] public string? Address { get; set; }
}
public class Brand : Entity
{
    public string Name { get; set; } = "";
    public string? LogoUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public List<CarModel> Models { get; set; } = [];
}
public class CarModel : Entity
{
    public int BrandId { get; set; }
    public Brand Brand { get; set; } = null!;
    public string Name { get; set; } = "";
    public List<CarVariant> Variants { get; set; } = [];
}
public class CarVariant : Entity
{
    public int CarModelId { get; set; }
    public CarModel CarModel { get; set; } = null!;
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public int Year { get; set; }
    public decimal Price { get; set; }
    public int Seats { get; set; }
    public string Fuel { get; set; } = "";
    public string Transmission { get; set; } = "";
    public string BodyStyle { get; set; } = "";
    public string Origin { get; set; } = "";
    public string Engine { get; set; } = "";
    public string Power { get; set; } = "";
    public string Torque { get; set; } = "";
    public string Drivetrain { get; set; } = "";
    public string Colors { get; set; } = "";
    public string Dimensions { get; set; } = "";
    public string Consumption { get; set; } = "";
    public string Description { get; set; } = "";
    public bool IsFeatured { get; set; }
    public bool IsVisible { get; set; } = true;
    public int Views { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    [Timestamp] public byte[] RowVersion { get; set; } = [];
    public CarInventory Inventory { get; set; } = null!;
    public List<CarImage> Images { get; set; } = [];
}
public class CarImage : Entity
{
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
    public string Url { get; set; } = "";
    public int SortOrder { get; set; }
}
public class CarInventory : Entity
{
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
    public int Stock { get; set; }
    public int Sold { get; set; }
    [Timestamp] public byte[] RowVersion { get; set; } = [];
}
public class Favorite : Entity
{
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
}
public class Order : Entity
{
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public string? AssignedSalesId { get; set; }
    public AppUser? AssignedSales { get; set; }
    public string Status { get; set; } = "Pending";
    public string PaymentStatus { get; set; } = "Unpaid";
    public decimal Total { get; set; }
    public string? Note { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CompletedAt { get; set; }
    [Timestamp] public byte[] RowVersion { get; set; } = [];
    public List<OrderItem> Items { get; set; } = [];
    public List<OrderHistory> History { get; set; } = [];
    public List<Payment> Payments { get; set; } = [];
}
public class OrderItem : Entity
{
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}
public class OrderHistory : Entity
{
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public string Status { get; set; } = "";
    public string ActorId { get; set; } = "";
    public AppUser Actor { get; set; } = null!;
    public string? Note { get; set; }
    public DateTimeOffset At { get; set; } = DateTimeOffset.UtcNow;
}
public class TestDriveBooking : Entity
{
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
    public string? AssignedSalesId { get; set; }
    public AppUser? AssignedSales { get; set; }
    public DateTimeOffset ScheduledAt { get; set; }
    public string Phone { get; set; } = "";
    public string? Note { get; set; }
    public string Status { get; set; } = "Pending";
}
public class QuoteRequest : Entity
{
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
    public string? AssignedSalesId { get; set; }
    public AppUser? AssignedSales { get; set; }
    public string Phone { get; set; } = "";
    public string? Message { get; set; }
    public string Status { get; set; } = "Pending";
    public string? Response { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
public class Payment : Entity
{
    public int OrderId { get; set; }
    public Order Order { get; set; } = null!;
    public decimal Amount { get; set; }
    public string Reference { get; set; } = "";
    public string ConfirmedById { get; set; } = "";
    public AppUser ConfirmedBy { get; set; } = null!;
    public DateTimeOffset At { get; set; } = DateTimeOffset.UtcNow;
}
public class Review : Entity
{
    public int CarVariantId { get; set; }
    public CarVariant CarVariant { get; set; } = null!;
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public int Rating { get; set; }
    public string Comment { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
public class Promotion : Entity
{
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public DateTimeOffset StartsAt { get; set; }
    public DateTimeOffset EndsAt { get; set; }
}
public class Contact : Entity
{
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Message { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
public class Notification : Entity
{
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public string Message { get; set; } = "";
    public bool IsRead { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
public class AuditLog : Entity
{
    public string ActorId { get; set; } = "";
    public AppUser Actor { get; set; } = null!;
    public string Action { get; set; } = "";
    public string Resource { get; set; } = "";
    public DateTimeOffset At { get; set; } = DateTimeOffset.UtcNow;
}
public class RefreshSession : Entity
{
    public string UserId { get; set; } = "";
    public AppUser User { get; set; } = null!;
    public string TokenHash { get; set; } = "";
    public DateTimeOffset ExpiresAt { get; set; }
    public bool Revoked { get; set; }
    [Timestamp] public byte[] RowVersion { get; set; } = [];
}
