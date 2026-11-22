# AutoCar RESTful API v1

Base URL Development: `http://localhost:5180/api`. Swagger: `/swagger`, OpenAPI JSON: `/swagger/v1/swagger.json`. Controllers dùng `[ApiController]`, DTO và Data Annotations; JSON camelCase. Swagger Authorize dùng access token nhận từ login (scheme Bearer).

## Authentication

| Method / path | Quyền | Input / kết quả |
|---|---|---|
| POST /auth/register | Public, rate limit | email, password, fullName, phone → 201 TokenDto; role luôn Customer |
| POST /auth/login | Public, rate limit | email, password → 200 TokenDto; sai/khóa →401 |
| POST /auth/refresh | Public, rate limit | refreshToken →200 TokenDto mới, thu hồi session cũ |
| POST /auth/logout | Auth | 204, thu hồi session hiện tại ngay |
| GET /auth/me | Auth | 200 hồ sơ không có password/token hash |
| PUT /auth/me | Auth | fullName, phone, address →204 |
| POST /auth/change-password | Auth | currentPassword, newPassword →204, thu hồi mọi session |

```json
{
  "email": "admin@autocar.local",
  "password": "YOUR_CONFIGURED_DEVELOPMENT_PASSWORD"
}
```

TokenDto: `accessToken`, `refreshToken`, `expiresAt`, `user{id,email,fullName,phone,address,roles}`. Access token 15 phút, refresh session 7 ngày; refresh token random 64 bytes, database chỉ lưu SHA-256 hash. Rotation dùng transaction và rowversion. Backend kiểm tra session chưa bị thu hồi và người dùng chưa khóa trên mỗi request; role được đọc lại từ SQL để thay đổi quyền có hiệu lực ngay. Sai mật khẩu 5 lần khóa tạm 15 phút. Auth limiter 10 request/phút/IP.

Login chấp nhận tên đăng nhập hoặc email trong field `email` để giữ tương thích với client cũ. Ví dụ `{"email":"admin","password":"YOUR_CONFIGURED_ADMIN_PASSWORD"}`. Register vẫn yêu cầu địa chỉ email hợp lệ. Mật khẩu demo Admin có thể được cấu hình riêng bằng `Seed:AdminPassword` trong local configuration.

Web MVC không trả TokenDto ra JavaScript: server gọi login, giữ token trong SessionVault, cookie chỉ chứa phiên MVC được bảo vệ. Các request ghi qua gateway có antiforgery header.

## Catalog

| Method / path | Quyền | Kết quả |
|---|---|---|
| GET /brands | Public | PageResult, search/page/pageSize; includeHidden chỉ Admin |
| GET /brands/{id} | Public | BrandDto hoặc404 |
| POST /brands | Admin | 201 BrandDto |
| PUT /brands/{id} | Admin | 204 |
| DELETE /brands/{id} | Admin | 204; hãng có model → IsActive=false, chưa dùng → xóa |
| GET /cars | Public | PageResult<CarDto> |
| GET /cars/search | Public | cùng query/pipeline với /cars |
| GET /cars/featured | Public | tối đa6 xe nổi bật |
| GET /cars/{id} | Public | CarDto; ẩn chỉ Admin xem; tăng Views |
| POST /cars | Admin | 201 CarDto và Location |
| PUT /cars/{id} | Admin | 204; bắt buộc rowVersion và inventoryVersion |
| DELETE /cars/{id} | Admin | 204; soft hide |
| GET /car-models | Public | danh sách ModelDto |
| POST /car-models | Admin | brandId, name →201 |
| PUT /car-models/{id} | Admin | brandId, name →204 |
| GET /car-variants | Public | cùng nguồn query CarVariants |
| POST /car-variants | Admin | cùng CarService với /cars →201 |
| PUT /car-variants/{id} | Admin | cùng CarService →204 |
| POST /uploads | Admin | multipart `file`; 201 `{url}` |

`cars` là DTO tổng hợp từ CarVariant + CarModel + Brand + Inventory + Images, **không có bảng Cars riêng**. Không có hai nguồn giá/tồn mâu thuẫn nhau.

Query /cars: `search`, `brandId`, `minPrice`, `maxPrice`, `year`, `seats`, `fuel`, `transmission`, `bodyStyle`, `inStock`, `featured`, `sort=newest|price_asc|price_desc`, `page=1`, `pageSize=12` (1–100), `includeHidden` chỉ Admin.

PageResult:

```json
{"items":[],"total":0,"page":1,"pageSize":12}
```

Ví dụ POST /brands:

```json
{"name":"Hãng minh họa mới","logoUrl":null,"isActive":true}
```

Ví dụ POST /cars (lấy carModelId hợp lệ từ GET /car-models):

```json
{
  "carModelId":1,
  "code":"DEMO-CUSTOM-001",
  "name":"Phiên bản minh họa",
  "year":2025,
  "price":950000000,
  "seats":5,
  "fuel":"Xăng",
  "transmission":"Tự động",
  "bodyStyle":"Sedan",
  "origin":"Minh họa",
  "engine":"Chưa xác minh",
  "stock":2,
  "isFeatured":false,
  "isVisible":true,
  "images":[]
}
```

PUT gửi đủ DTO và **hai version mới nhất từ GET**; version cũ →409. Image URL phải là đường dẫn `/uploads/...` do endpoint upload cấp; JPG/PNG/WebP, kiểm tra magic bytes, mỗi ảnh ≤4MB, tối đa12 ảnh/xe, tên file random. SVG upload không được cho phép. Hình minh họa mặc định ở Web là SVG nội bộ do dự án tạo.

## Customer và giao dịch

| Method / path | Quyền | Input / kết quả |
|---|---|---|
| GET /favorites | Customer | danh sách CarDto của chính mình |
| POST /favorites | Customer | carId →201; thêm trùng idempotent |
| DELETE /favorites/{carId} | Customer | 204/404 |
| GET /orders | Auth | Customer: của mình; Sales: được giao; Admin: tất cả; page/pageSize |
| GET /orders/{id} | Auth theo sở hữu/phân công | chi tiết/items/history/payments hoặc404 |
| POST /orders | Customer | carId, quantity1–5, note →201 |
| PUT /orders/{id}/status | Admin/Sales được giao | status, note, assignedSalesId (chỉ Admin) →204 |
| POST /orders/{id}/cancel | Customer sở hữu | hủy Pending →204 |
| POST /orders/{id}/payments | Admin | amount, reference unique →201, xác nhận thủ công |
| GET /test-drive-bookings | Auth scope | lịch được phép xem |
| POST /test-drive-bookings | Customer | carId, scheduledAt ISO8601, phone, note →201 |
| PUT /test-drive-bookings/{id} | Admin/Sales được giao | status, note, assignedSalesId →204 |
| GET /quote-requests | Auth scope | yêu cầu được phép xem |
| POST /quote-requests | Customer | carId, phone, message →201 |
| PUT /quote-requests/{id}/status | Admin/Sales được giao | status, note/phản hồi, assignedSalesId →204 |
| GET /reviews?carId={id} | Public | 50 đánh giá gần nhất; thiếu carId: gần nhất tất cả xe |
| POST /reviews | Customer đã mua xe hoàn tất | carId, rating1–5, comment →201 |
| PUT /reviews/{id} | Chủ sở hữu | cùng review DTO →204 |
| DELETE /reviews/{id} | Chủ sở hữu/Admin | 204 |
| GET /notifications | Auth của mình | 50 thông báo gần nhất |
| PUT /notifications/{id}/read | Chủ sở hữu | 204 |

Order transitions:

```text
Pending → Confirmed → Completed
Pending → Cancelled / Rejected
Confirmed → Cancelled
Completed / Cancelled / Rejected: terminal
```

Confirmed trừ stock, Cancelled từ Confirmed hoàn stock. Tổng đơn và UnitPrice chụp tại thời điểm POST. Pending không giữ hàng. API xác nhận kiểm tra tồn lần nữa trong Serializable transaction; không thể mua vượt tồn dù hai đơn cùng được tạo khi còn hàng. Completed yêu cầu Paid. Thanh toán không vượt tổng còn thiếu, không xử lý thẻ; hủy có tiền nhận chuyển RefundRequired.

Booking: Pending → Confirmed/Cancelled; Confirmed → Completed/Cancelled. Quote: Pending → InProgress/Closed; InProgress → Closed. Admin có thể chỉ phân công, giữ nguyên status. Customer không được tự chuyển status quản trị.

## Quản trị, báo cáo và công khai

| Endpoint GET | Quyền | Kết quả |
|---|---|---|
| /dashboard/overview | Admin | cars, brands, inStock, sold, customers, orders, pendingOrders, upcomingBookings, revenue |
| /dashboard/revenue | Admin | `{label:yyyy-MM,value}`; from/to exclusive, brandId |
| /dashboard/orders | Admin | số đơn theo status |
| /dashboard/top-cars | Admin | top5 lượt xem |
| /dashboard/top-brands | Admin | xe hoàn tất theo hãng + revenue |
| /dashboard/export | Admin | CSV; cùng from/to/brandId |
| /users | Admin | phân trang20, search, hồ sơ/roles/locked |
| /users/sales | Admin | nhân viên có role Sales |
| /public/promotions | Public | ưu đãi còn hiệu lực |
| /public/contacts | Admin | 100 liên hệ gần nhất |
| /public/audit | Admin | 100 audit gần nhất |

PUT `/users/{id}`: `{role:"Sales",locked:false}`; thu hồi phiên, chặn thay đổi tài khoản Admin hiện hữu. POST `/public/contacts`: `{name,email,message}` →201, có rate limit. `/health` chỉ sức khỏe process; `/health/database` kiểm tra khả năng kết nối SQL, không được coi `/health`200 là bằng chứng CRUD hoạt động.

## Lỗi và status

200 đọc, 201 tạo, 204 cập nhật/xóa; 400 validation; 401 chưa/sai/hết hạn xác thực; 403 thiếu quyền; 404 tài nguyên không tồn tại/không trong scope; 409 trùng key, FK, chuyển trạng thái sai, thiếu tồn hoặc rowversion/deadlock; 429 rate limit; 500 lỗi không công bố stack trace.

Validation dùng ValidationProblemDetails (`errors` theo field). Middleware trả ProblemDetails cho lỗi nghiệp vụ/server. 401/403 mặc định không có body; Web xử lý theo status. 500 chỉ có thông báo chung và traceId; log chi tiết phía server không ghi password/token.

```json
{"status":409,"title":"Không đủ tồn kho để xác nhận đơn.","traceId":"..."}
```

## Kiểm thử CRUD

Login Admin → Swagger Authorize → POST brand → GET id → PUT → DELETE. Với xe: GET model id → POST → GET nhận versions → PUT với versions → DELETE ẩn → public GET404. Đăng nhập Customer và thử POST brand phải403. Chạy `scripts/Test-Integration.ps1` sau khi database và tài khoản seed hoạt động; không báo kiểm thử SQL đã đạt trước khi chạy thành công.
