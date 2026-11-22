# Kịch bản trình diễn AutoCar (10–15 phút)

## Chuẩn bị

1. Kết nối SQL hợp lệ, cấu hình seed password riêng và chạy API để migration/seed.
2. Build solution; chạy kiểm tra unit/schema và script integration trong Development.
3. Mở Web5080, Swagger5180, SSMS AutoCarDB. Kiểm tra có15 hãng/78 phiên bản. Không dùng kết quả `/health` để thay thế kiểm tra database.
4. Mở nhiều cửa sổ/trình duyệt để đăng nhập ba role. Chỉ demo HTTP trên localhost; không đưa credential lên slide hoặc commit.

## 1. Giới thiệu kiến trúc

Mở cấu trúc solution: Shared DTO → API entities/context/repository/services/controller; Web chỉ HttpClient. Chỉ ra `BrandsController` dùng đúng generic repository theo tài liệu giảng viên. Phân biệt `CarModel` (dòng xe) và `CarVariant` (phiên bản), `cars` là resource tổng hợp.

## 2. CRUD và Swagger

- Login Admin, Authorize JWT.
- POST hãng mới, sửa tên; tạo model, tạo phiên bản với tồn1.
- GET id, giải thích 201/Location,200,204,400,404 và409.
- Sửa xe ở Web `/admin/cars`, xem dữ liệu mới trong Swagger và SSMS.
- Thử DELETE hãng có model: bị vô hiệu hóa; DELETE xe chỉ ẩn, không mất lịch sử đơn.

## 3. Website khách hàng

Trang chủ → chọn hãng, lọc giá/nhiên liệu/số chỗ → chi tiết → gallery → so sánh2 xe. Đăng nhập Customer → lưu yêu thích → đặt lái thử ngày mai → gửi tư vấn. Tài khoản hiển thị dữ liệu API thật; công cụ trả góp ghi rõ giả định.

## 4. Phân quyền

Customer gọi POST `/api/brands` phải403; request không token tới `/api/orders` phải401. Truy cập `/admin` bằng Customer bị chặn. Admin phân công đơn/lịch cho Sales; Sales chỉ thấy dữ liệu của mình, không truy cập users/brands CRUD. Đổi quyền/khóa tài khoản thu hồi session.

## 5. Đơn hàng và tồn kho

Customer tạo hai đơn mỗi đơn1 xe khi stock1 → cả hai Pending (chưa giữ xe). Admin xác nhận đơn1 → Stock0, Sold1; xác nhận đơn2 →409. Hủy đơn1 → Stock1, Sold0; xác nhận đơn2 → thành công. Mở SSMS kiểm tra.

Admin nhập giao dịch chuyển khoản mô phỏng bằng đúng Total, reference unique → Paid. Chuyển Completed → dashboard doanh thu tăng bằng Total. Thử đổi Completed về Pending/Cancelled →409. Sửa giá xe → OrderItems.UnitPrice không thay đổi.

## 6. Dashboard và báo cáo

Admin dashboard hiển thị số lượng thật, doanh thu Completed+Paid, đơn theo trạng thái, top views và doanh số hãng. Chọn khoảng ngày/hãng trong báo cáo → CSV; đối chiếu SUM(Total) ở SSMS. Không tạo doanh thu hardcode chỉ để biểu đồ có dữ liệu.

## 7. Restart và lưu dữ liệu

Dừng hai project rồi F5 lại. Kiểm tra xe/đơn vẫn tồn tại trong SQL, đăng nhập lại vì Web session RAM và Development Data Protection ephemeral. Kiểm tra `__EFMigrationsHistory` không tạo trùng bảng. Đây là bước cần chạy thực tế, chưa được xác nhận trong phiên agent có lỗi SSPI.

## Câu hỏi bảo vệ

- Vì sao generic repository vẫn cần service riêng? Giao dịch đặt xe liên quan nhiều bảng và transaction, không phù hợp ép vào CRUD tổng quát.
- Vì sao dùng DTO? Kiểm soát field được ghi/đọc, tránh lộ hash/password và vòng tham chiếu entity.
- Tồn kho chống race thế nào? Serializable + rowversion + check SQL không âm + transition terminal.
- Đơn hủy có tính doanh thu không? Không; Completed+Paid mới ghi nhận. Tiền đã nhận trước hủy cần hoàn thủ công, có trạng thái RefundRequired.
- MVC có DbContext không? Không; mọi dữ liệu nghiệp vụ qua API, kiểm tra project references để chứng minh.
- Token ở đâu? Access/refresh ở server RAM; browser chỉ cookie HttpOnly, antiforgery cho mutation; API xác minh JWT và session SQL.
- Dữ liệu xe có phải giá hiện tại? Không; toàn bộ seed là minh họa, ảnh SVG tự tạo.

## Phạm vi chưa tích hợp

Email reset password, thanh toán thẻ, hoàn tiền ngân hàng tự động, external login/2FA, thông báo realtime và production multi-node token vault chưa được triển khai. Các danh sách lịch/tư vấn/reviews/contacts có giới hạn lấy gần nhất; chưa có export Excel (có CSV). Visual QA và end-to-end SQL cần chạy lại ở môi trường kết nối hợp lệ.
