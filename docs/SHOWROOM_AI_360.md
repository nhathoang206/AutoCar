# Chatbot và xem xe 360°

**Chế độ mặc định hiện tại:** AI miễn phí chạy trên máy qua Ollama, xem [cách bật AI miễn phí](FREE_AI.md). Phần OpenAI dưới đây chỉ áp dụng khi chủ động chọn `AI:Provider=OpenAI`.

Trang chủ hiển thị 3 xe nổi bật đầu tiên từ `cars/featured`. Chỉ trang chi tiết của 3 xe này có trình xem 360°. Khi quản trị thay đổi danh sách nổi bật, phạm vi 360° cập nhật tương ứng.

Trình xem dùng mô hình polygon 3D dựng tại chỗ bằng Canvas, không tải thư viện ngoài. Có kéo chuột/chạm, mũi tên bàn phím, thanh góc 0–359°, tự xoay, đặt lại, cuộn thu phóng. Đây là mô hình kiểu dáng minh họa, không phải mô hình hay ảnh 360° chính xác của từng hãng xe. Muốn tái hiện đúng từng dòng cần cung cấp bộ ảnh đa góc hoặc tài sản 3D có quyền sử dụng.

Chatbot gọi OpenAI Responses API từ máy chủ, lấy danh mục showroom (tối đa 100 xe) làm ngữ cảnh, hỗ trợ lịch sử gần nhất và xe đang xem. Không tự tạo đơn. Trình duyệt hiển thị văn bản thuần, không chèn HTML AI. Có CSRF và giới hạn 10 yêu cầu/phút/IP. Hội thoại chỉ giữ trong bộ nhớ trang; payload dùng `store: false`.

Cách kết nối trên máy phát triển: chạy lệnh sau ở thư mục dự án và nhập khóa API tại lời nhắc ẩn. Script gọi thử AI, kiểm tra quyền truy cập model rồi mới lưu cấu hình vào `AutoCar.Web/appsettings.Local.json` (đã được `.gitignore` loại trừ). Model mặc định là `gpt-5-mini`; có thể truyền `-Model` để chọn model tài khoản có quyền sử dụng. Lệnh kiểm tra có sử dụng API.

```powershell
.\scripts\Connect-ShowroomAI.ps1
```

Sau khi thành công, khởi động lại AutoCar.Web. Tệp Local chỉ được đọc trong Development, chỉ lưu trên máy cá nhân. Khi triển khai dùng biến môi trường. Ứng dụng cũng nhận `OPENAI_API_KEY` và `OPENAI_MODEL`. Biến môi trường ưu tiên hơn tệp Local.

Hoặc cấu hình biến môi trường cho tiến trình AutoCar.Web, sau đó khởi động lại:

```powershell
$env:AI__ApiKey = '<khóa API của bạn>'
$env:AI__Model = '<model hỗ trợ Responses API trong tài khoản>'
dotnet run --project AutoCar.Web
```

Không lưu khóa trong mã nguồn hay wwwroot. Khi API/SQL không sẵn sàng, AI chỉ hướng dẫn chung và được yêu cầu không suy đoán giá, tồn kho hoặc dòng xe cụ thể. Lỗi nhà cung cấp được phân biệt theo khóa không hợp lệ, quyền/model, hết hạn mức, giới hạn tần suất, timeout và mất mạng. Không ghi khóa hoặc nội dung phản hồi lỗi thô vào log.

Kiểm tra lại khóa đã lưu (không cần nhập lại): chạy `scripts/Connect-ShowroomAI.ps1`. Lệnh có gọi API thực tế và chỉ lưu lại cấu hình khi có câu trả lời. Kiểm thử hồi quy bằng nhà cung cấp giả lập: `dotnet run --project AutoCar.Web.Tests`.

Tài liệu API chính thức: https://developers.openai.com/api/reference/resources/responses/methods/create

Kiểm tra thủ công: vào trang chủ → mở từng xe nổi bật → kéo xoay đủ vòng, thử phím/thu phóng/tự xoay; mở xe ngoài danh sách và xác nhận không có 360°; thử chat thiếu khóa và sau khi cấu hình khóa hợp lệ; hỏi về xe đang xem, so sánh giá và lái thử.
