using AutoCar.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
var builder=WebApplication.CreateBuilder(args);
// Local secrets stay outside source control; environment variables retain priority.
if (builder.Environment.IsDevelopment())
    builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: true).AddEnvironmentVariables();
builder.Logging.ClearProviders();builder.Logging.AddConsole();
builder.Services.AddControllersWithViews(o=>o.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddAntiforgery(o=>o.HeaderName="X-CSRF-TOKEN");
builder.Services.AddHttpContextAccessor();builder.Services.AddSingleton<SessionVault>();
builder.Services.AddHttpClient("BrandLogos",c=>{c.Timeout=TimeSpan.FromSeconds(20);c.DefaultRequestHeaders.UserAgent.ParseAdd("AutoCar-Showroom/1.0");});
builder.Services.AddHostedService<BrandLogoCacheService>();
builder.Services.AddSingleton<CarPhotoCatalog>();
builder.Services.AddHttpClient("CarPhotos",c=>{c.Timeout=TimeSpan.FromSeconds(40);c.DefaultRequestHeaders.UserAgent.ParseAdd("AutoCar-Educational-Showroom/1.0 (model photo attribution; local development)");});
builder.Services.AddHostedService<CarPhotoCacheService>();
builder.Services.AddHttpClient<AutoCarClient>(c=>{c.BaseAddress=new Uri(builder.Configuration["Api:BaseUrl"]??"http://localhost:5180/");c.Timeout=TimeSpan.FromSeconds(20);});
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(o=>{o.LoginPath="/dang-nhap";o.AccessDeniedPath="/khong-co-quyen";o.Cookie.Name="AutoCar.Session";o.Cookie.HttpOnly=true;o.Cookie.SameSite=SameSiteMode.Lax;o.Cookie.SecurePolicy=CookieSecurePolicy.SameAsRequest;o.ExpireTimeSpan=TimeSpan.FromHours(8);o.Events.OnValidatePrincipal=async context=>{var vault=context.HttpContext.RequestServices.GetRequiredService<SessionVault>();if(vault.Get(context.Principal?.FindFirst("session")?.Value)==null){context.RejectPrincipal();await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);}};});
builder.Services.AddAuthorization();
if(builder.Environment.IsDevelopment())
{
    builder.Services.AddDataProtection().UseEphemeralDataProtectionProvider();
    builder.Services.Configure<Microsoft.AspNetCore.DataProtection.KeyManagement.KeyManagementOptions>(o=>{o.XmlRepository=new MemoryKeyRepository();o.XmlEncryptor=new Microsoft.AspNetCore.DataProtection.XmlEncryption.NullXmlEncryptor();});
}
else builder.Services.AddDataProtection().SetApplicationName("AutoCar.Web");
builder.Services.AddHttpClient("ShowroomAI", c => c.Timeout = TimeSpan.FromSeconds(40));
builder.Services.AddHttpClient("LocalAI", c => c.Timeout = TimeSpan.FromSeconds(120));
builder.Services.AddRateLimiter(o => {
 o.RejectionStatusCode = 429;
 o.AddPolicy("chat", context => System.Threading.RateLimiting.RateLimitPartition.GetFixedWindowLimiter(context.Connection.RemoteIpAddress?.ToString() ?? "unknown", _ => new System.Threading.RateLimiting.FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});
var app=builder.Build();
app.Use(async(context,next)=>
{
    context.Response.Headers["X-Content-Type-Options"]="nosniff";context.Response.Headers["Referrer-Policy"]="strict-origin-when-cross-origin";
    try{await next();}
    catch(Exception e)when(e is HttpRequestException or ApiException or TaskCanceledException)
    {
        if(context.Response.HasStarted)throw;
        var status=e is ApiException a?a.Status:503;context.Response.StatusCode=status;
        if(context.Request.Path.StartsWithSegments("/gateway")){await context.Response.WriteAsJsonAsync(new{title="Dịch vụ API chưa sẵn sàng."});return;}
        context.Response.ContentType="text/html; charset=utf-8";await context.Response.WriteAsync("<!doctype html><html lang='vi'><meta charset='utf-8'><meta name='viewport' content='width=device-width'><title>AutoCar · Dịch vụ chưa sẵn sàng</title><link rel='stylesheet' href='/css/site.css'><main class='container section'><a class='logo' href='/'>AutoCar<span>®</span></a><p class='eyebrow'>KẾT NỐI DỊCH VỤ</p><h1>Hành trình sẽ sớm tiếp tục.</h1><p>"+(status==404?"Không tìm thấy nội dung bạn yêu cầu.":"AutoCar.Api hoặc SQL Server chưa sẵn sàng. Vui lòng khởi động cả hai project và kiểm tra cấu hình database.")+"</p><a class='btn primary' href='/'>Thử lại</a> <a class='btn' href='/dang-nhap'>Đăng nhập</a></main></html>");
    }
});
if(!app.Environment.IsDevelopment()){app.UseExceptionHandler("/loi");app.UseHsts();app.UseHttpsRedirection();}
app.UseStaticFiles();app.UseRouting();app.UseRateLimiter();app.UseAuthentication();app.UseAuthorization();
app.MapGet("/car-photo-catalog",(CarPhotoCatalog catalog)=>Results.Json(catalog.All));
if(app.Environment.IsDevelopment())app.MapGet("/health/car-photos",(CarPhotoCatalog catalog)=>Results.Json(new{expected=CarPhotoCatalog.Models.Count,downloaded=catalog.All.Count(),errors=catalog.Errors}));
app.MapGet("/car-photo",(string brand,string model,CarPhotoCatalog catalog)=>Results.Redirect(catalog.Find(brand,model) is {} photo?"/images/cars/"+photo.File:"/images/car-pending.svg"));
app.MapControllerRoute(name:"default",pattern:"{controller=Home}/{action=Index}/{id?}");app.Run();
