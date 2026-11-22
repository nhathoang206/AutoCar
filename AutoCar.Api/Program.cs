using System.Security.Cryptography;
using System.Threading.RateLimiting;
using AutoCar.Api.Data;
using AutoCar.Api.Middleware;
using AutoCar.Api.Models;
using AutoCar.Api.Repositories;
using AutoCar.Api.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
var builder=WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();builder.Logging.AddConsole();
builder.Services.AddDataProtection().UseEphemeralDataProtectionProvider();
builder.Services.Configure<Microsoft.AspNetCore.DataProtection.KeyManagement.KeyManagementOptions>(o=>{o.XmlRepository=new MemoryKeyRepository();o.XmlEncryptor=new Microsoft.AspNetCore.DataProtection.XmlEncryption.NullXmlEncryptor();});
builder.Configuration.AddJsonFile("appsettings.Local.json",optional:true,reloadOnChange:false).AddEnvironmentVariables();
builder.Services.AddDbContext<AppDbContext>(o=>o.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped(typeof(IRepository<>),typeof(Repository<>));builder.Services.AddScoped<CarService>();builder.Services.AddScoped<OrderService>();builder.Services.AddScoped<TokenService>();
builder.Services.AddSingleton<DatabaseStatus>();
builder.Services.AddIdentityCore<AppUser>(o=>{o.User.RequireUniqueEmail=true;o.Password.RequiredLength=10;o.Lockout.MaxFailedAccessAttempts=5;o.Lockout.DefaultLockoutTimeSpan=TimeSpan.FromMinutes(15);}).AddRoles<IdentityRole>().AddUserStore<UserStore>().AddRoleStore<RoleStore>();
var jwt=builder.Configuration.GetSection("Jwt").Get<JwtSettings>()??new();
if(jwt.Key.Length<32){if(!builder.Environment.IsDevelopment())throw new InvalidOperationException("Configure Jwt:Key using secrets (at least 32 characters).");jwt.Key=Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));}
builder.Services.AddSingleton(jwt);builder.Services.AddAuthentication("Bearer").AddScheme<AuthenticationSchemeOptions,JwtAuthenticationHandler>("Bearer",_=>{});
builder.Services.AddAuthorization();builder.Services.AddControllers();builder.Services.AddProblemDetails();
builder.Services.AddCors(o=>o.AddDefaultPolicy(p=>p.WithOrigins(builder.Configuration["WebOrigin"]??"http://localhost:5080").AllowAnyHeader().AllowAnyMethod()));
builder.Services.AddRateLimiter(o=>{o.RejectionStatusCode=429;o.AddPolicy("auth",context=>RateLimitPartition.GetFixedWindowLimiter(context.Connection.RemoteIpAddress?.ToString()??"unknown",_=>new(){PermitLimit=10,Window=TimeSpan.FromMinutes(1),QueueLimit=0}));});
builder.Services.AddEndpointsApiExplorer();builder.Services.AddSwaggerGen(o=>{o.SwaggerDoc("v1",new(){Title="AutoCar RESTful API",Version="v1",Description="SQL Server · EF Core · Repository · Identity · JWT. Showroom minh họa."});o.AddSecurityDefinition("Bearer",new(){Type=SecuritySchemeType.Http,Scheme="bearer",BearerFormat="JWT"});o.AddSecurityRequirement(new(){[new OpenApiSecurityScheme{Reference=new(){Type=ReferenceType.SecurityScheme,Id="Bearer"}}]=Array.Empty<string>()});});
var app=builder.Build();app.UseMiddleware<ErrorMiddleware>();app.Use(async(ctx,next)=>{ctx.Response.Headers["X-Content-Type-Options"]="nosniff";await next();});
if(app.Environment.IsDevelopment()){app.UseSwagger();app.UseSwaggerUI();}else app.UseHttpsRedirection();
Directory.CreateDirectory(Path.Combine(app.Environment.ContentRootPath,"wwwroot"));app.UseStaticFiles();app.UseCors();app.UseRateLimiter();app.UseAuthentication();app.UseAuthorization();app.MapControllers();
app.MapGet("/health",()=>Results.Ok(new{status="running",service="AutoCar.Api"}));
app.MapGet("/health/database",(AppDbContext db,DatabaseStatus status,IWebHostEnvironment environment)=>status.Check(db,environment));
if(app.Environment.IsDevelopment()&&builder.Configuration.GetValue<bool>("Database:Initialize"))
{
    using var scope=app.Services.CreateScope();var db=scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try { await db.Database.MigrateAsync();await SeedData.Run(scope.ServiceProvider,builder.Configuration);await ModelPhotoSeed.Run(db,Path.Combine(app.Environment.ContentRootPath,"wwwroot")); }
    catch(Exception ex) when(ex is Microsoft.Data.SqlClient.SqlException or InvalidOperationException)
    {
        app.Services.GetRequiredService<DatabaseStatus>().InitializationError=DatabaseStatus.Explain(ex);
        app.Logger.LogError(ex,"Database initialization failed. Open /health/database for diagnosis. {Hint}",DatabaseStatus.Explain(ex));
    }
}
app.Run();
public partial class Program { }
