using AutoCar.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace AutoCar.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<IdentityRole> Roles => Set<IdentityRole>();
    public DbSet<IdentityUserRole<string>> UserRoles => Set<IdentityUserRole<string>>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<CarModel> CarModels => Set<CarModel>();
    public DbSet<CarVariant> CarVariants => Set<CarVariant>();
    public DbSet<CarImage> CarImages => Set<CarImage>();
    public DbSet<CarInventory> CarInventories => Set<CarInventory>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderHistory> OrderHistories => Set<OrderHistory>();
    public DbSet<TestDriveBooking> TestDriveBookings => Set<TestDriveBooking>();
    public DbSet<QuoteRequest> QuoteRequests => Set<QuoteRequest>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Promotion> Promotions => Set<Promotion>();
    public DbSet<Contact> Contacts => Set<Contact>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<RefreshSession> RefreshSessions => Set<RefreshSession>();
    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);
        b.Entity<AppUser>().ToTable("AspNetUsers");
        b.Entity<AppUser>().HasKey(x=>x.Id);
        b.Entity<AppUser>().Property(x=>x.Id).HasMaxLength(450);
        b.Entity<AppUser>().Property(x=>x.NormalizedUserName).HasMaxLength(256);
        b.Entity<AppUser>().Property(x=>x.NormalizedEmail).HasMaxLength(256);
        b.Entity<AppUser>().Property(x=>x.Email).HasMaxLength(256);
        b.Entity<AppUser>().HasIndex(x=>x.NormalizedUserName).IsUnique();
        b.Entity<IdentityRole>().ToTable("AspNetRoles").HasKey(x=>x.Id);
        b.Entity<IdentityRole>().Property(x=>x.Id).HasMaxLength(450);
        b.Entity<IdentityRole>().Property(x=>x.NormalizedName).HasMaxLength(256);
        b.Entity<IdentityRole>().HasIndex(x=>x.NormalizedName).IsUnique();
        b.Entity<IdentityUserRole<string>>().ToTable("AspNetUserRoles").HasKey(x=>new{x.UserId,x.RoleId});
        b.Entity<IdentityUserRole<string>>().HasOne<AppUser>().WithMany().HasForeignKey(x=>x.UserId);
        b.Entity<IdentityUserRole<string>>().HasOne<IdentityRole>().WithMany().HasForeignKey(x=>x.RoleId);
        b.Entity<AppUser>().HasIndex(x=>x.Email).IsUnique();
        b.Entity<Brand>().Property(x=>x.Name).HasMaxLength(80);
        b.Entity<Brand>().HasIndex(x=>x.Name).IsUnique();
        b.Entity<CarModel>().Property(x=>x.Name).HasMaxLength(100);
        b.Entity<CarModel>().HasIndex(x=>new {x.BrandId,x.Name}).IsUnique();
        b.Entity<CarVariant>().Property(x=>x.Code).HasMaxLength(50);
        b.Entity<CarVariant>().Property(x=>x.Name).HasMaxLength(120);
        b.Entity<CarVariant>().HasIndex(x=>x.Code).IsUnique();
        b.Entity<CarVariant>().HasIndex(x=>new {x.IsVisible,x.Price});
        b.Entity<CarVariant>().HasIndex(x=>new {x.Year,x.BodyStyle});
        b.Entity<CarVariant>().ToTable(t=>t.HasCheckConstraint("CK_Car_Price","[Price] >= 0"));
        b.Entity<CarInventory>().HasOne(x=>x.CarVariant).WithOne(x=>x.Inventory).HasForeignKey<CarInventory>(x=>x.CarVariantId);
        b.Entity<CarInventory>().ToTable(t=> {t.HasCheckConstraint("CK_Inventory_Stock","[Stock] >= 0"); t.HasCheckConstraint("CK_Inventory_Sold","[Sold] >= 0");});
        b.Entity<Favorite>().HasIndex(x=>new {x.UserId,x.CarVariantId}).IsUnique();
        b.Entity<Review>().HasIndex(x=>new {x.UserId,x.CarVariantId}).IsUnique();
        b.Entity<Review>().ToTable(t=>t.HasCheckConstraint("CK_Review_Rating","[Rating] BETWEEN 1 AND 5"));
        b.Entity<OrderItem>().ToTable(t=> {t.HasCheckConstraint("CK_OrderItem_Quantity","[Quantity] > 0"); t.HasCheckConstraint("CK_OrderItem_Price","[UnitPrice] >= 0");});
        b.Entity<Payment>().Property(x=>x.Reference).HasMaxLength(200);
        b.Entity<Payment>().HasIndex(x=>x.Reference).IsUnique();
        b.Entity<Payment>().ToTable(t=>t.HasCheckConstraint("CK_Payment_Amount","[Amount] > 0"));
        b.Entity<RefreshSession>().Property(x=>x.TokenHash).HasMaxLength(64);
        b.Entity<RefreshSession>().HasIndex(x=>x.TokenHash).IsUnique();
        b.Entity<Order>().HasIndex(x=>new {x.Status,x.CreatedAt});
        b.Entity<TestDriveBooking>().HasIndex(x=>new {x.AssignedSalesId,x.ScheduledAt});
        foreach(var type in b.Model.GetEntityTypes())
        {
            foreach(var p in type.GetProperties().Where(x=>x.ClrType==typeof(decimal))) {p.SetPrecision(18);p.SetScale(2);}
            foreach(var fk in type.GetForeignKeys()) fk.DeleteBehavior = DeleteBehavior.Restrict;
        }
    }
}
