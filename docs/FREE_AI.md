# Chatbot AI miễn phí

Showroom mặc định dùng Ollama với `qwen2.5:1.5b`, hỗ trợ tiếng Việt. Không cần tài khoản, khóa API hoặc trả phí theo câu hỏi. Chạy AI vẫn dùng RAM/CPU, điện và dung lượng máy; chất lượng và tốc độ tùy phần cứng.

1. Nhấp đúp `Bat-AI-Mien-Phi.cmd` trong thư mục gốc dự án.
2. Lần đầu đợi tải Ollama và mô hình khoảng 986 MB (bộ chạy cần thêm vài GB). Cần Internet cho lần tải này.
3. Khi hiện `READY`, khởi động lại AutoCar.Web rồi mở chatbot trong showroom.
4. Sau khi khởi động lại Windows, chạy lại tệp này để bật AI. Các lần sau dùng mô hình đã tải, không cần tải lại hoặc Internet để sinh câu trả lời.

Tệp tự dùng Ollama có sẵn hoặc tải bản portable từ GitHub chính thức vào `.runtime/ollama` (được loại khỏi Git), bật dịch vụ nền tại `127.0.0.1:11434`, kiểm tra câu trả lời thật và lưu cấu hình. Nếu gặp lỗi tải, cài từ https://ollama.com/download/windows rồi chạy lại tệp. Không mở cổng Ollama ra Internet.

AI chạy trên máy đặt AutoCar.Web; khách truy cập website không cần cài Ollama. API danh mục và SQL vẫn cần hoạt động để chatbot tư vấn theo xe trong showroom. Khi không có danh mục, AI chỉ được hướng dẫn tư vấn chung. Ngữ cảnh chọn tối đa 8 xe liên quan/nổi bật để giảm tải cho mô hình nhỏ, không tìm kiếm toàn bộ danh mục theo ngữ nghĩa.

Nhà cung cấp mặc định là `AI:Provider=Ollama`; model dùng `AI:OllamaModel`, địa chỉ dùng `AI:OllamaUrl`. Khóa OpenAI cũ không được dùng trong chế độ này. Muốn quay lại OpenAI phải đặt rõ `AI:Provider=OpenAI`. Script `Connect-ShowroomAI.ps1` dành riêng cho chế độ trả phí.

Tài liệu: https://docs.ollama.com/api/chat · https://docs.ollama.com/windows · https://ollama.com/library/qwen2.5:1.5b
