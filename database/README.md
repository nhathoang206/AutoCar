# Database

1. Cấu hình connection string riêng, không commit credential.
2. Chạy `dotnet run --project AutoCar.Tests -- --database` từ root, hoặc `dotnet ef database update --project AutoCar.Api`.
3. API Development tự migrate/seed nếu `Database:Initialize=true`.

`scripts/AutoCarDB.sql` là script idempotent sinh trực tiếp từ migration. Có thể mở bằng SSMS và chạy bằng tài khoản có quyền tạo database. Không chạy song song migration từ nhiều process; lần đầu khởi tạo chỉ chạy một instance API. Không chạy lại CREATE TABLE thủ công.

Sinh lại SQL khi thêm migration: `dotnet run --project AutoCar.Tests -- --script`.

## Khi gặp lỗi index đã tồn tại

Script EF idempotent nguyên bản dựa vào `__EFMigrationsHistory`, không dựa vào từng bảng/index. Nếu schema đã được tạo thủ công hoặc lần chạy bị gián đoạn trước khi ghi migration history, phần CREATE có thể bị chạy lại.

`AutoCarDB.sql` hiện có thêm các guard cho từng bảng/index (kể cả filtered unique index), kiểm tra schema theo EF model và transaction TRY/CATCH. Mở **bản file mới nhất**, tạo một query connection mới trong SSMS và Execute **toàn bộ file**, không bôi đen riêng phần CREATE INDEX. Không cần DROP database/bảng/index.

Trước COMMIT, script đối chiếu column/type/nullability/identity, PK, index/unique/filter, FK và check constraints. Nếu schema cũ không khớp, script báo tên đối tượng và rollback, bao gồm mọi thay đổi migration history trong lần chạy đó. Không tự chèn bản ghi migration history bằng tay để bỏ qua kiểm tra. Nếu có statistics trùng tên nhưng không phải index, hoặc định nghĩa index khác, cần chẩn đoán riêng thay vì xóa mù quáng.

Kiểm tra sau khi migration/seed:

```sql
USE AutoCarDB;
SELECT * FROM __EFMigrationsHistory;
SELECT COUNT(*) AS Brands FROM Brands;
SELECT COUNT(*) AS Variants FROM CarVariants;
SELECT MIN(Stock) AS MinStock, SUM(Stock) AS Stock, SUM(Sold) AS Sold FROM CarInventories;
SELECT Status, PaymentStatus, COUNT(*) AS Orders, SUM(Total) AS Amount
FROM Orders GROUP BY Status, PaymentStatus;
SELECT SUM(Total) AS Revenue FROM Orders WHERE Status='Completed' AND PaymentStatus='Paid';
```

Trong phiên agent, migration SQL đã sinh; áp dụng lên server bị lỗi SSPI. Không có bằng chứng seed đã được ghi vào SQL Server cho đến khi bạn chạy với kết nối hợp lệ.
