using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Api.Services;
using AutoCar.Tests;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;
using AutoCar.Shared.Contracts;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
if(args.Contains("--scaffold")){Scaffolding.Generate(Directory.GetCurrentDirectory());return;}
if(args.Contains("--script"))
{
    using var db=new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseSqlServer("Server=.;Database=AutoCarDB;Integrated Security=true").Options);
    var script=SqlScriptWriter.Generate(db);
    Directory.CreateDirectory("database/scripts");
    File.WriteAllText("database/scripts/AutoCarDB.sql",script);
    Console.WriteLine("Generated idempotent SQL from migrations.");return;
}
if(args.Contains("--database"))
{
    var config=new ConfigurationBuilder().AddJsonFile(Path.Combine(Directory.GetCurrentDirectory(),"AutoCar.Api/appsettings.json")).AddJsonFile(Path.Combine(Directory.GetCurrentDirectory(),"AutoCar.Api/appsettings.Local.json"),true).AddEnvironmentVariables().Build();var services=new ServiceCollection().AddLogging().AddDbContext<AppDbContext>(o=>o.UseSqlServer(config.GetConnectionString("DefaultConnection")));
    services.AddIdentityCore<AppUser>(o=>{o.Password.RequiredLength=10;o.User.RequireUniqueEmail=true;}).AddRoles<IdentityRole>().AddUserStore<UserStore>().AddRoleStore<RoleStore>();using var provider=services.BuildServiceProvider();using var scope=provider.CreateScope();var db=scope.ServiceProvider.GetRequiredService<AppDbContext>();await db.Database.MigrateAsync();await SeedData.Run(scope.ServiceProvider,config);Console.WriteLine($"SQL Server: {await db.Brands.CountAsync()} brands; {await db.CarVariants.CountAsync()} variants.");return;
}
var failed=0;var count=0;
void Check(string name,bool ok){count++;Console.WriteLine($"{(ok?"PASS":"FAIL")} {name}");if(!ok)failed++;}
Check("Pending -> Confirmed",OrderRules.CanTransition("Pending","Confirmed"));
Check("Pending cannot skip confirmation",!OrderRules.CanTransition("Pending","Completed"));
Check("Confirmed cancellation allowed",OrderRules.CanTransition("Confirmed","Cancelled"));
Check("Completed order is terminal",!OrderRules.CanTransition("Completed","Cancelled"));
Check("Rejected order is terminal",!OrderRules.CanTransition("Rejected","Confirmed"));
Check("Cancelled order is terminal",!OrderRules.CanTransition("Cancelled","Confirmed"));
Check("Revenue only paid completed",OrderRules.RecognizesRevenue("Completed","Paid")&&!OrderRules.RecognizesRevenue("Cancelled","Paid")&&!OrderRules.RecognizesRevenue("Confirmed","Paid")&&!OrderRules.RecognizesRevenue("Completed","Unpaid"));
Check("Refresh hash not plaintext",TokenService.Hash("secret")!="secret"&&TokenService.Hash("secret").Length==64);
var badCar=new CarInput{Price=-1,Seats=1};Check("Invalid car input rejected",!Validator.TryValidateObject(badCar,new ValidationContext(badCar),new List<ValidationResult>(),true));
var adminLogin=new LoginInput{Email="admin",Password="12345"};
Check("Login accepts an administrator username",Validator.TryValidateObject(adminLogin,new ValidationContext(adminLogin),new List<ValidationResult>(),true));
var invalidRegistration=new RegisterInput{Email="admin",Password="StrongPassword!123",FullName="Test"};
Check("Registration still requires a valid email",!Validator.TryValidateObject(invalidRegistration,new ValidationContext(invalidRegistration),new List<ValidationResult>(),true));
using(var db=new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseSqlServer("Server=.;Database=AutoCarDB;Integrated Security=true").Options))
{
    var model=db.Model;
    var required=new[]{"Brands","CarModels","CarVariants","CarImages","CarInventories","Favorites","Orders","OrderItems","TestDriveBookings","QuoteRequests","Payments","Reviews","Promotions","Contacts","Notifications","AuditLogs","AspNetUsers","AspNetRoles","AspNetUserRoles","RefreshSessions","OrderHistories"};
    Check("Schema contains every required table",required.All(name=>model.GetEntityTypes().Any(e=>e.GetTableName()==name)));
    Check("Inventory concurrency token",model.FindEntityType(typeof(CarInventory))!.FindProperty("RowVersion")!.IsConcurrencyToken);
    Check("Money uses decimal 18,2",model.FindEntityType(typeof(CarVariant))!.FindProperty("Price")!.GetPrecision()==18&&model.FindEntityType(typeof(CarVariant))!.FindProperty("Price")!.GetScale()==2);
    Check("No cascade deletes on transactions",model.FindEntityType(typeof(OrderItem))!.GetForeignKeys().All(f=>f.DeleteBehavior==DeleteBehavior.Restrict));
    Check("SQL schema generates",db.Database.GenerateCreateScript().Contains("CK_Inventory_Stock"));
    Check("Initial migration compiled in API assembly",db.Database.GetMigrations().Any(x=>x.EndsWith("InitialCreate")));
    Check("Idempotent migration includes domain tables",db.GetService<IMigrator>().GenerateScript(options:MigrationsSqlGenerationOptions.Idempotent).Contains("CREATE TABLE [CarInventories]"));
    var bootstrap=SqlScriptWriter.Generate(db);
    Check("Bootstrap checks existing indexes",bootstrap.Contains("IF NOT EXISTS (SELECT 1 FROM sys.indexes")&&bootstrap.Contains("name = N'IX_AspNetUserRoles_RoleId'"));
    Check("Bootstrap checks existing tables",bootstrap.Contains("IF OBJECT_ID(N'[dbo].[CarVariants]', N'U') IS NULL"));
    Check("Bootstrap validates schema before commit",bootstrap.Contains("Foreign key mismatch")&&bootstrap.Contains("Check constraint mismatch")&&bootstrap.IndexOf("Index definition mismatch",StringComparison.Ordinal)<bootstrap.IndexOf("COMMIT TRANSACTION;",StringComparison.Ordinal));
    Check("Bootstrap rolls back history on mismatch",bootstrap.Contains("SET XACT_ABORT ON;")&&bootstrap.Contains("IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;"));
    var indexCount=db.GetService<Microsoft.EntityFrameworkCore.Metadata.IDesignTimeModel>().Model.GetRelationalModel().Tables.Sum(t=>t.Indexes.Count());
    Check("Every index including filtered indexes has an existence guard",System.Text.RegularExpressions.Regex.Matches(bootstrap,"IF NOT EXISTS \\(SELECT 1 FROM sys.indexes WHERE").Count==indexCount);
}
Console.WriteLine($"{count-failed}/{count} checks passed. SQL integration checks run separately with --database or scripts/Test-Integration.ps1.");Environment.ExitCode=failed==0?0:1;
