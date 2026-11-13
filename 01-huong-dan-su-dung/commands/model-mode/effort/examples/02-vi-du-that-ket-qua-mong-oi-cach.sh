# Bước 1: đang medium, đoán sai → tăng high thay vì đổi Opus ngay
/effort high

# Bước 2: giao lại với yêu cầu tự kiểm chứng
Bug vẫn còn: GET /api/users?page=3&limit=20 trả total=95 nhưng thực tế 100 rows.
Hãy đọc src/api/users.ts + query COUNT, tự viết script reproduce,
rồi fix. Không đoán mò, phải có bằng chứng chạy được.
