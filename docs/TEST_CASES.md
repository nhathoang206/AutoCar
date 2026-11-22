# Kiểm thử AutoCar

**Cập nhật 30/10/2026:** SQL đã kết nối khi chạy qua Visual Studio; đã chạy một phần integration thật, phát hiện lỗi trả500 khi deadlock và bổ sung xử lý. Xem [kết quả kết nối mới nhất](SQL_CONNECTION_STATUS.md) và `INTEGRATION_RESULTS.json`. Những ghi chú SSPI bên dưới là kết quả phiên sandbox trước đó, không còn là trạng thái của ứng dụng đang chạy từ Visual Studio.

Ngày thực hiện: 30/10/2026. Phân biệt kiểm tra mã/schema, HTTP không cần SQL và integration thật.

## Đã chạy

| Nhóm | Lệnh | Kết quả |
|---|---|---|
| Build .NET8 + Razor | `dotnet build AutoCar.sln --no-restore` | 0 errors, 0 warnings ở lần build cuối trước bàn giao |
| Unit/schema executable harness | `dotnet run --project AutoCar.Tests` | 16/16: transition terminal, điều kiện doanh thu, refresh hash, validation, bảng bắt buộc, precision, concurrency, restrict FK, schema SQL, migration compiled, idempotent script có bảng nghiệp vụ |
| JavaScript syntax | `node --check` cho site.js, account.js, admin.js | Đạt |
| HTTP smoke | `powershell -File scripts/Test-Smoke.ps1` | 14/14; chi tiết `SMOKE_RESULTS.json` |
| EF scaffolding | `--scaffold` | Sinh InitialCreate + designer + snapshot; migration được compile trong API |
| SQL script | `--script` | Sinh idempotent `database/scripts/AutoCarDB.sql` từ migration |
| SQL migration live | `--database` | Thất bại trước khi áp dụng: **Failed to generate SSPI context** |
| Browser visual QA | Browser inventory | Không thực hiện được: browser access host unavailable |

`AutoCar.Tests` là console test harness chạy không cần tải test framework từ Internet; không giả định `dotnet test` đã chạy xUnit/MSTest. Script integration gọi HTTP thật, không mock database. Kết quả unit không chứng minh EF transaction SQL đã chạy đúng.

## Checklist yêu cầu và trạng thái

| # | Test case | Kỳ vọng | Trạng thái |
|---|---|---|---|
| 1 | GET cars |200, phân trang từ SQL | Chưa chạy SQL |
| 2 | GET car id |200 đúng ID | Chưa chạy SQL |
| 3 | POST brand/car Admin |201, lưu SQL | Chưa chạy SQL |
| 4 | PUT brand/car |204, GET thấy thay đổi | Chưa chạy SQL |
| 5 | DELETE | hãng trống xóa; hãng có xe vô hiệu; xe ẩn | Chưa chạy SQL |
| 6 | ID thiếu |404 | Chưa chạy SQL; route không tồn tại404 đã smoke |
| 7 | Input sai |400 | Đã smoke registration; DTO car đã unit; POST car live chưa chạy |
| 8 | Anonymous gọi protected |401 | Đã smoke orders/dashboard/brands POST |
| 9 | Customer gọi Admin |403 | Có script, chưa chạy SQL |
| 10 | Order quantity > stock |409 | Có script, chưa chạy SQL |
| 11 | Confirm/cancel stock |trừ/hoàn đúng một lần; không âm | Có script, chưa chạy SQL |
| 12 | Dashboard revenue |chỉ Paid+Completed | Điều kiện unit đạt; SQL chưa chạy |
| 13 | Login đúng/sai |200/401 | Có script, chưa chạy SQL |
| 14 | MVC hiển thị xe API |HTML có car-card từ API | Chưa chạy SQL; login/about/contact Razor200 đã smoke |
| 15 | Restart giữ dữ liệu |SQL vẫn có xe/đơn | Chưa chạy; cần quy trình manual dưới đây |

## HTTP smoke 14 mục

Health200; Swagger200; orders401; dashboard401; brand POST anonymous401; register sai400; route thiếu404; MVC login/register/about/compare/contact200; admin anonymous302; gateway POST thiếu antiforgery400. API được chạy với `Database__Initialize=false` để kiểm tra các route không cần SQL. Chế độ này không thay thế DB và không trả catalog giả.

## Integration sau khi sửa kết nối

1. Cấu hình SQL và `Seed:Password`, migrate+seed Development.
2. Chạy cả API/Web; đặt `AUTOCAR_TEST_PASSWORD`, chạy `scripts/Test-Integration.ps1`.
3. Script kiểm CRUD brands/cars, validation,403,404, version stale409, order vượt stock409, xác nhận hai đơn cạnh tranh cùng một stock, hoàn tồn, Paid→Completed, revenue, lái thử, tư vấn, đánh giá sau mua, refresh rotation/logout và Web homepage gọi API. Kết quả được lưu `INTEGRATION_RESULTS.json`; chưa có file kết quả đạt ở phiên này.
4. Script giữ QA records phục vụ đối chiếu, không xóa dữ liệu giao dịch. Chỉ chạy ở Development.

## Race đồng thời thực tế (đã có script, chưa chạy)

`Test-Integration.ps1` tạo riêng xe QA-RACE stock1 và hai Pending orders quantity1, gửi hai `HttpClient.SendAsync` trước khi `Task.WaitAll`. Kỳ vọng một204, một409 (hoặc xung đột deadlock được map409), Stock0, Sold1, chỉ một đơn Confirmed. Script kiểm tồn sau race, hủy đơn Confirmed để hoàn tồn và ẩn xe QA. Chưa chạy do SQL SSPI; không dùng kết quả kiểm tra tuần tự để tuyên bố đã chứng minh race đồng thời. Script cũng kiểm MVC cookie login và gateway gọi auth/me bằng token server.

## Restart persistence (chưa chạy)

Ghi lại ID/Code/OrderId, tắt API/Web, khởi động lại cùng connection string, GET lại và SELECT SSMS. Yêu cầu dữ liệu không mất. Web đăng nhập lại là hành vi dự kiến của vault RAM; không phải mất dữ liệu SQL.

## Visual/responsive (chưa chạy)

Desktop1440, tablet768, mobile390: header/mobile menu, hero, card grid, filter, gallery, modal, form validation, compare table scroll, sidebar admin, status badges, Chart.js empty state, ảnh không vỡ. Kiểm tra keyboard focus/labels/dialog và reduced motion. Hiện CSS breakpoint/alt/aria đã có; chưa thay thế được quan sát trên browser.

## Lỗi đã xử lý trong triển khai

- CLI template cache ngoài workspace: đổi DOTNET_CLI_HOME cục bộ.
- Restore mạng bị chặn: dùng cache NuGet có sẵn; không đổi backend/database.
- Thiếu package Identity EF/JwtBearer net8: Identity EF stores và JWT handler tường minh, vẫn dùng manager/hasher/validator chuẩn.
- Lỗi Razor closing tag/using: đã sửa và build lại.
- Migration ban đầu nằm ngoài project: đã chuyển vào AutoCar.Api/Migrations và thêm test xác minh discovery/script.
- Form stock stale: thêm InventoryVersion và kiểm tra cả hai rowversions.
- Windows EventLog/Data Protection dưới sandbox: console logging, Development ephemeral key repository trong RAM.
- SQL SSPI: đã xác định nhưng chưa thể giải quyết khi không có SQL credential hợp lệ trong phiên agent. Không báo pass integration.
