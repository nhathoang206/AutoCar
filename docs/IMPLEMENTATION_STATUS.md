# Trạng thái bàn giao theo giai đoạn

## 1. Kiến trúc

Đã tạo AutoCar.sln, AutoCar.Api/Web/Shared/Tests, project references và packages target net8.0. Solution build0 lỗi,0 cảnh báo. Giữ nguyên project mẫu có sẵn ngoài solution mới.

## 2. SQL Server

Đã triển khai21 bảng nghiệp vụ/Identity, relationships/index/checks/rowversions, migration InitialCreate + designer + snapshot, script SQL idempotent và seed15 hãng/39 dòng/78 phiên bản. Migration discovery và generated SQL đã kiểm tra. **Chưa áp dụng vào SQL:** Windows Authentication từ agent lỗi SSPI. Không dùng JSON/SQLite/InMemory thay SQL.

## 3. RESTful API

Đã có generic IRepository/Repository và các endpoints bắt buộc: auth, brands, cars, models, variants, favorites, orders, test-drive-bookings, quote-requests, reviews, dashboard. Thêm uploads, users, payments, contacts, notifications, audit và reports CSV. Swagger runtime sinh46 paths; `docs/openapi.json` lấy từ ứng dụng đang chạy. Brands/car CRUD code đã build; live CRUD còn chờ SQL.

## 4. Authentication

ASP.NET Core Identity managers/hashers + EF stores, JWT signing/validation, hashed rotating refresh session, logout revocation, role guard, lockout và rate limit. MVC cookie/vault server, không lưu API token trong localStorage. Anonymous401/CSRF400 đã kiểm HTTP; login/Customer403/live role checks chưa chạy SQL.

## 5. Website

Trang chủ, tìm/lọc/phân trang xe, hãng, chi tiết/gallery/fullscreen, so sánh2–3 xe, yêu thích, login/register, tài khoản, hồ sơ/password, lịch sử và thông báo. Static journal/about/contact. HttpClient và gateway là nguồn nghiệp vụ; Web không tham chiếu EF/API project. Responsive CSS, original SVG và favicon; Bootstrap local; SweetAlert2/Chart.js qua CDN có fallback. Razor compile và HTTP các trang không cần SQL đạt. Homepage trả503 kèm hero/errorstate khi SQL không sẵn sàng, không bịa danh sách xe. **Visual QA chưa chạy.**

## 6. Giao dịch

OrderService với giá snapshot, Serializable, check stock, rowversion, state machine, hoàn tồn khi hủy, xác nhận chuyển khoản thủ công, Completed chỉ khi Paid và thông báo/audit. Booking/quote phân công và role scope. Có integration script kiểm cả race bằng hai HTTP tasks đồng thời; chưa chạy do SQL.

## 7. Quản trị

Admin/Sales layout, danh mục, form nhiều ảnh/stock/spec, quản lý người dùng/khóa/quyền, phân công, lịch hẹn/tư vấn, đơn/lịch sử/thanh toán, dashboard/chart/table, reports theo ngày/hãng và CSV, contacts/audit. Sales chỉ có work dashboard và công việc được giao. API filters/server pagination cho catalog/orders/users. Các danh sách lịch/tư vấn/contacts/reviews/notifications hiện có giới hạn số bản ghi gần nhất; chưa mở rộng phân trang toàn bộ.

## 8. Kiểm thử/tài liệu

16 unit/schema checks,14 HTTP smoke checks đã chạy đạt; JavaScript và PowerShell syntax đã kiểm tra. SQL integration, restart persistence, browser desktop/mobile chưa xác minh. Có API documentation, ERD, use cases, installation, test matrix, demo guide và OpenAPI JSON. Xem TEST_CASES.md và SMOKE_RESULTS.json.

## Còn cần thực hiện trước khi bảo vệ

1. Chạy SQL migration/seed với kết nối hợp lệ ngoài phiên agent bị hạn chế.
2. Chạy Test-Integration.ps1 và kiểm tra lại các lỗi runtime nếu xuất hiện; chưa có bằng chứng live SQL pass.
3. Demo ba role, dữ liệu lưu sau restart và race tồn kho; đối chiếu SSMS.
4. Kiểm tra UI desktop/mobile trên browser thật; thay/thu thập ảnh xe có quyền dùng nếu muốn ảnh chụp chính xác.

Không tuyên bố đã hoàn thành tiêu chuẩn end-to-end trước các bước này. Email reset, thanh toán thẻ, tự động hoàn tiền ngân hàng, external login/2FA, multi-node session storage và Excel export chưa triển khai; có CSV và thanh toán trạng thái thủ công.
