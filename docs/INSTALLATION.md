# Chạy AutoCar trên Visual Studio 2022

## Điều kiện

- Visual Studio 2022 17.8 trở lên, workload **ASP.NET and web development**.
- .NET 8 SDK (SDK mới hơn cũng build được target `net8.0`; máy phát triển này build bằng SDK 10.0.400 với runtime 8.0.30).
- SQL Server 2019 trở lên và SSMS. Chọn đúng instance, không mặc định instance của máy khác.
- Internet để restore NuGet lần đầu; có thể dùng cache package cục bộ.

## Thiết lập

1. Mở **AutoCar.sln**. Không mở solution mẫu `AutoCar.slnx` cũ. Thư mục `AutoCar/` ban đầu được giữ nguyên để tránh ghi đè công việc có sẵn.
2. Restore NuGet: chuột phải solution → Restore NuGet Packages; hoặc `dotnet restore AutoCar.sln`.
3. `AutoCar.Api/appsettings.json` chứa connection string mẫu Windows Authentication tới `.\MSSQLSERVER01`. Tạo **AutoCar.Api/appsettings.Local.json** (được gitignore) để cấu hình instance thật:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER;Database=AutoCarDB;Trusted_Connection=True;Encrypt=True;TrustServerCertificate=True"
  },
  "Jwt": { "Key": "REPLACE_WITH_A_RANDOM_SECRET_OF_AT_LEAST_32_CHARACTERS" },
  "Seed": { "Password": "REPLACE_WITH_YOUR_DEVELOPMENT_PASSWORD" }
}
```

Các chuỗi REPLACE là placeholder, không phải mật khẩu có thể dùng để đăng nhập. Mật khẩu seed cần ≥10 ký tự, có hoa, thường, số và ký tự đặc biệt. Không commit file local hoặc bí mật thực. Có thể thay bằng biến môi trường `ConnectionStrings__DefaultConnection`, `Jwt__Key`, `Seed__Password`.

4. SQL Authentication nếu Windows Authentication không khả dụng: dùng login đã được quản trị viên SQL cấp quyền; đặt password trong file local/biến môi trường, không đặt vào file tracked. Cần quyền tạo `AutoCarDB` lần đầu hoặc để quản trị viên tạo trước rồi cấp quyền database thích hợp. Không dùng tài khoản `sa` cho ứng dụng thực tế.
5. Migration: trong **Package Manager Console**, chọn Default project `AutoCar.Api`, Startup project `AutoCar.Api`. Cài tool EF nếu cần:

```powershell
dotnet tool install --global dotnet-ef --version 8.0.31
dotnet ef database update --project AutoCar.Api --startup-project AutoCar.Api
```

Đã có `InitialCreate` và snapshot trong `AutoCar.Api/Migrations`; **không chạy Add-Migration InitialCreate lần nữa**. Development tự gọi `MigrateAsync` và seed khi khởi động (`Database:Initialize=true`). Có thể khởi tạo không cần tool CLI:

```powershell
dotnet run --project AutoCar.Tests -- --database
```

Lệnh trên áp dụng chính migrations hiện có rồi seed; không dùng `EnsureCreated`, không có schema song song. Chạy từ thư mục gốc solution. `appsettings.Local.json` được đọc bởi API và lệnh này. Khi chạy CLI EF từ project, các biến môi trường là cách cấu hình chắc chắn nhất; host của API có tải file local.

6. Seed có 15 hãng, 39 dòng xe và 78 phiên bản (2 phiên bản/dòng); giá/thông số đều là **minh họa**. Seed tạo tài khoản chỉ khi `Seed:Password` đã được cung cấp, chỉ trong quá trình khởi tạo Development hoặc lệnh `--database` chủ động.
7. Chuột phải solution → Configure Startup Projects → Multiple startup projects → **Start AutoCar.Api** và **Start AutoCar.Web**. F5.
8. API: `http://localhost:5180/swagger`; Web: `http://localhost:5080`; quản trị/Sales: `/admin`; khách hàng: `/tai-khoan`.
9. `AutoCar.Web/appsettings.Development.json` đặt `Api:BaseUrl=http://localhost:5180/`. Sửa nếu đổi cổng API. Cập nhật `WebOrigin` trên API nếu đổi cổng Web.
10. Trong SSMS kiểm tra `AutoCarDB`, bảng `Brands`, `CarVariants`, `CarInventories`, `Orders`, `AspNetUsers` và `__EFMigrationsHistory`.

## Tài khoản Development

Admin hiện có thể đăng nhập bằng tên `admin` hoặc email `admin@autocar.local`. Tên và mật khẩu demo riêng của Admin được cấu hình trong `Seed:AdminUserName` và `Seed:AdminPassword` ở `appsettings.Local.json`. Startup Development cập nhật tài khoản Admin hiện có, giữ nguyên ID/quyền/lịch sử và thu hồi phiên cũ. Các tài khoản Sales/Customer vẫn dùng `Seed:Password` như trước. Đăng ký khách hàng vẫn yêu cầu email và chính sách mật khẩu ban đầu.

| Email | Role |
|---|---|
| admin@autocar.local | Admin |
| sales@autocar.local | Sales |
| customer1@autocar.local … customer5@autocar.local | Customer |

Mật khẩu là giá trị bạn tự cấu hình trong `Seed:Password`. Không có mật khẩu mặc định tracked. Đăng ký mới tạo role Customer; Admin có thể phân quyền Sales cho tài khoản mới trong trang người dùng. Tài khoản Admin hiện hữu được bảo vệ khỏi thay đổi role/khóa qua API người dùng.

## Kiểm tra

```powershell
dotnet build AutoCar.sln
dotnet run --project AutoCar.Tests
powershell -File scripts/Test-Smoke.ps1
# Sau khi SQL + seed chạy thành công:
$env:AUTOCAR_TEST_PASSWORD = 'YOUR_CONFIGURED_DEVELOPMENT_PASSWORD'
powershell -File scripts/Test-Integration.ps1
```

Test integration tạo dữ liệu `QA-*`, đơn, tài khoản và thanh toán mô phỏng trong database Development, giữ lại để kiểm tra nhật ký. Không chạy vào database production.

## Giới hạn môi trường thực tế đã gặp

- SQL Server `.\MSSQLSERVER01` chạy, nhưng Windows Authentication từ phiên agent trả **Failed to generate SSPI context**. Chưa áp dụng migration/seed vào SQL trong phiên này. Chạy Visual Studio/PowerShell bằng tài khoản Windows thông thường có quyền SQL, hoặc cấu hình SQL login hợp lệ do bạn quản lý.
- Sandbox chặn socket ra NuGet. Đã restore từ cache máy bằng `dotnet restore AutoCar.sln --packages .packages --source C:/Users/nhath/.nuget/packages -p:NuGetAudit=false`. Máy khác nên dùng restore online bình thường. Lệnh cache chỉ là cách kiểm tra trong môi trường này, không phải cấu hình bắt buộc của solution.
- Bộ package cục bộ thiếu Identity EF integration và JwtBearer net8. Hệ thống vẫn dùng **ASP.NET Core Identity UserManager/RoleManager/PasswordHasher**, với EF SQL stores tường minh trong `Services/IdentityStores.cs`. JWT dùng thư viện `System.IdentityModel.Tokens.Jwt` và `AuthenticationHandler` xác minh chữ ký/issuer/audience/lifetime/session/role. Không băm mật khẩu thủ công, không tạo JWT giả.
- Không cần `IDesignTimeDbContextFactory`: scaffolding EF đã chạy thành công với context options. Không hardcode credential design-time.
- Không thể truy cập browser automation host trong phiên; chưa xác nhận visual QA trên desktop/mobile. HTTP và compile Razor đã kiểm tra.

## HTTPS và môi trường ngoài Development

HTTP loopback là cấu hình demo cục bộ. Trước triển khai mạng thật: cấu hình HTTPS/certificate, connection string có TLS hợp lệ, JWT key bắt buộc, Data Protection key storage được bảo vệ, reverse proxy đúng IP rate limit, backup database và dịch vụ gửi email nếu cần. Web giữ token trong RAM phía server cho một node; restart Web buộc đăng nhập lại. Development dùng Data Protection ephemeral; không coi cookie còn hiệu lực qua restart.

Chart.js và SweetAlert2 tải từ jsDelivr (version cố định); font từ Google Fonts có fallback hệ thống. Bootstrap được lưu local. Khi offline, dữ liệu báo cáo dạng bảng và toàn bộ nghiệp vụ vẫn dùng được, thông báo/xác nhận có fallback; biểu đồ cần tải Chart.js hoặc lưu bản vendor hợp lệ tại local. Không có email reset password, cổng thanh toán thẻ hay ảnh hãng xe có bản quyền được quảng cáo là đã tích hợp.
