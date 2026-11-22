using AutoCar.Api.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace AutoCar.Api.Services;

public sealed class DatabaseStatus
{
    public string? InitializationError { get; set; }

    public static string Explain(Exception exception)
    {
        var sql = exception as SqlException ?? exception.InnerException as SqlException;
        return sql?.Number switch
        {
            18456 => "SQL Server từ chối đăng nhập. Kiểm tra SQL Authentication, user và mật khẩu trong appsettings.Local.json.",
            4060 => "Không mở được AutoCarDB. Kiểm tra database tồn tại và quyền của SQL login.",
            20 => "Kết nối gặp lỗi TLS/SChannel trước khi đăng nhập. Đây chưa phải bằng chứng mật khẩu sai.",
            26 or 40 or 53 => "Không tìm thấy SQL Server. Kiểm tra server/instance hoặc địa chỉ TCP và cổng.",
            2714 => "Schema đã có bảng nhưng migration history chưa khớp. Chạy toàn bộ database/scripts/AutoCarDB.sql đã cập nhật trong SSMS.",
            _ => "Kiểm tra chi tiết lỗi SQL trong console AutoCar.Api. Không thay connection string trong AutoCar.Web."
        };
    }

    public async Task<IResult> Check(AppDbContext db, IWebHostEnvironment environment)
    {
        var connection = new SqlConnectionStringBuilder(db.Database.GetConnectionString());
        try
        {
            await db.Database.OpenConnectionAsync();
            var pending = (await db.Database.GetPendingMigrationsAsync()).ToArray();
            if (InitializationError != null || pending.Length > 0)
                return Results.Json(new { status = "needs-initialization", server = connection.DataSource, database = connection.InitialCatalog, pendingMigrations = pending, detail = environment.IsDevelopment() ? InitializationError : null }, statusCode: 503);
            return Results.Ok(new { status = "connected", server = connection.DataSource, database = connection.InitialCatalog, brands = await db.Brands.CountAsync(), cars = await db.CarVariants.CountAsync() });
        }
        catch (Exception ex) when (ex is SqlException or InvalidOperationException)
        {
            var sql = ex as SqlException ?? ex.InnerException as SqlException;
            return Results.Json(new { status = "unavailable", server = environment.IsDevelopment() ? connection.DataSource : null, database = connection.InitialCatalog, errorNumber = sql?.Number, hint = Explain(ex), detail = environment.IsDevelopment() ? sql?.Message ?? ex.Message : null }, statusCode: 503);
        }
        finally { await db.Database.CloseConnectionAsync(); }
    }
}
