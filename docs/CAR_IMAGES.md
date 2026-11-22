# Bộ ảnh dòng xe AutoCar

Đã bổ sung 39 ảnh thật cho 39 dòng xe, sử dụng cho 78 phiên bản seed minh họa. Mỗi dòng có ảnh riêng; hai phiên bản Standard/Premium dùng chung ảnh tham khảo. Không xác nhận ảnh đúng năm 2025, cấu hình Việt Nam hoặc phiên bản thương mại cụ thể.

## Vị trí và luồng dữ liệu

- Ảnh WebP và thông tin tác giả/giấy phép: `AutoCar.Web/wwwroot/images/cars/`.
- Ảnh được API phục vụ: `AutoCar.Api/wwwroot/catalog/`.
- `ModelPhotoSeed` gắn ảnh vào bảng SQL Server `CarImages` khi khởi tạo Development, chỉ cho xe seed chưa có ảnh. Ảnh do quản trị viên upload được giữ lại.
- Web nhận đường dẫn qua RESTful API và lấy ảnh qua `/media/catalog/{filename}`. Trang danh sách, chi tiết, yêu thích, so sánh và bảng quản trị dùng chung luồng chọn ảnh.
- Ghi công: trang `/nguon-anh` và từng trang chi tiết. Nguồn, tác giả và giấy phép riêng từng ảnh có trong `sources.json`.
- Ảnh được thu nhỏ tối đa 1280 px và chuyển WebP, giữ nguyên nội dung và giấy phép gốc. Tổng dung lượng bộ ảnh từ 78.592.546 byte xuống 7.828.158 byte.
- Ảnh concept ở hero và bài viết vẫn được ghi nhãn AI minh họa riêng. Không dùng ảnh concept thay thế ảnh sản phẩm.

## Kiểm tra thực tế

Đã chạy:

```text
dotnet build AutoCar.sln --no-restore
dotnet run --project AutoCar.Tests --no-build
python scripts/Verify-CarPhotos.py
```

Kết quả: build không lỗi/cảnh báo; 23/23 kiểm tra hiện có thành công. Bộ kiểm tra ảnh xác nhận 39 ảnh WebP hợp lệ, 78 xe API có đúng ảnh theo hãng/dòng, 78 trang chi tiết chứa đường dẫn ảnh và ghi công, các trang chủ/danh sách/nguồn ảnh trả 200. Nội dung ảnh từ API và Web proxy khớp byte với tệp lưu trong dự án.

Đã dừng cả API/Web trong Visual Studio, khởi động lại, rồi chạy lại `Verify-CarPhotos.py`: thành công, mỗi xe seed vẫn có đúng một ảnh, không phát sinh ảnh trùng. Báo cáo gần nhất: `CAR_IMAGES_VERIFICATION.json`.

Đã xem contact sheet của toàn bộ 39 ảnh để kiểm tra ảnh khớp dòng xe. Chưa kiểm tra trực quan các trang bằng trình duyệt trong lượt này; kiểm tra trang được thực hiện qua HTTP.

## Công cụ ảnh

`scripts/Optimize-CarPhotos.py` và `scripts/Verify-CarPhotos.py` dùng Pillow. Bộ ảnh đã tối ưu và được đóng gói sẵn nên không cần chạy lại script để sử dụng website. Bộ tải dùng ảnh kích thước chuẩn 1280 px từ máy chủ thumbnail Wikimedia, theo [tài liệu MediaWiki](https://www.mediawiki.org/wiki/Common_thumbnail_sizes).
