# AutoCar · Premium Automotive Management & Online Showroom

ASP.NET Core .NET 8 / C# / SQL Server / EF Core / MVC / REST API.

Mở [AutoCar.sln](AutoCar.sln), cấu hình SQL và seed password theo [hướng dẫn cài đặt](docs/INSTALLATION.md), chạy đồng thời API (5180) và MVC (5080).

```text
Browser → MVC / gateway → Typed HttpClient → REST API
       → Repository / Domain Service → EF Core → SQL Server AutoCarDB
```

- **AutoCar.Api**: Identity/JWT, Swagger, danh mục, đặt xe, tồn kho transactional, lịch lái thử, tư vấn, đánh giá, phân quyền, thống kê và CSV.
- **AutoCar.Web**: showroom Razor tiếng Việt, tìm kiếm/lọc/phân trang, chi tiết/gallery, so sánh, yêu thích, tài khoản, Admin/Sales workspace. Không tham chiếu EF hay DbContext.
- **AutoCar.Shared**: DTO/validation contract.
- **AutoCar.Tests**: executable test harness nghiệp vụ/schema và công cụ áp dụng migration/seed; HTTP integration scripts trong `scripts`.
- **database**, **docs**: schema, API, use cases, test cases và demo.

**Trạng thái thực tế:** build thành công; unit/schema checks và HTTP smoke đã chạy. SQL integration đang bị chặn bởi `Failed to generate SSPI context`; chưa được phép kết luận toàn bộ hệ thống đã chạy end-to-end. Xem [kết quả kiểm tra](docs/TEST_CASES.md).

15 hãng, 78 phiên bản seed; mọi giá/thông số seed được ghi rõ là minh họa, không phải dữ liệu thị trường. SVG xe tự tạo không đại diện chính xác từng model. Project mẫu `AutoCar/` và `AutoCar.slnx` được giữ nguyên, không thuộc solution mới.

Tài liệu: [API](docs/API_DOCUMENTATION.md) · [Database](docs/DATABASE_DESIGN.md) · [Use cases](docs/USE_CASES.md) · [Demo](docs/DEMO_GUIDE.md).
