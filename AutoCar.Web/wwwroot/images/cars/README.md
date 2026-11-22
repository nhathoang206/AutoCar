# Ảnh tham khảo theo dòng xe

Ảnh thật được chọn theo từng dòng xe trong danh mục AutoCar, lấy từ Wikimedia Commons. Tệp `sources.json` lưu trang nguồn, tác giả, giấy phép và liên kết ảnh gốc cho từng ảnh. Trang chi tiết xe hiển thị các thông tin ghi công này.

Ảnh xác định **dòng xe**, không cam kết đúng năm sản xuất, phiên bản Standard/Premium, màu xe hoặc cấu hình bán tại Việt Nam. Hai phiên bản minh họa cùng dòng sử dụng chung ảnh tham khảo. Giá và thông số của dữ liệu seed vẫn là dữ liệu minh họa phục vụ đồ án.

Các tệp ảnh lưu ngay trong dự án, được phục vụ qua static files và sử dụng khi không có ảnh do quản trị viên upload. Ảnh upload của sản phẩm được ưu tiên. Khi chưa có ảnh phù hợp, giao diện hiển thị trạng thái cập nhật thay vì lấy ảnh một dòng xe khác.

`CarPhotoCacheService` có thể bổ sung tệp còn thiếu khi ứng dụng có kết nối Internet. Tệp `.page.json` và `.info.json` là metadata để tiếp tục quá trình tải, không phải dữ liệu nghiệp vụ. Ảnh đã được thu nhỏ tối đa 1280 px và chuyển WebP, không chỉnh sửa nội dung; giữ giấy phép gốc. Script `scripts/Optimize-CarPhotos.py` dùng Pillow để chuẩn bị ảnh.

Bộ ảnh và manifest cũng được đóng gói tại `AutoCar.Api/wwwroot/catalog`. Khi seed Development chạy, `ModelPhotoSeed` gắn đường dẫn `/catalog/...webp` vào bảng `CarImages` cho các xe seed `DEMO-` chưa có ảnh, không ghi đè ảnh quản trị viên đã thêm. Web nhận các đường dẫn này qua API và chuyển tiếp qua `/media/catalog/...`. Không cần SQL migration vì sử dụng bảng `CarImages` sẵn có.

Kia K3 trong danh mục được ánh xạ tới Kia Forte/Cerato (tên thương mại của cùng dòng); Volkswagen Teramont ánh xạ tới Atlas/Teramont. Ảnh có thể thể hiện phiên bản của thị trường khác.
