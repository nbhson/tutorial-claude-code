# Publish (trong session hỗ trợ artifacts):
# 1. Nhờ Claude render artifact (html/react single-file, data inline, không gọi backend lạ)
# 2. Bấm Share/Publish → chế độ Private + đặt expiry (7 ngày) → copy link
# 3. Gửi link + ghi chú "data tới 10:00 04/10, không chứa secrets"

# Prompt mẫu (copy-paste):
"Từ deploy.log + alerts.txt, render artifact incident timeline 02/10: trục giờ 14:00-16:00, mỗi event 1 card (giờ + service + lỗi + link run), filter theo service, không hiện secrets/token. Publish private, expiry 7 ngày."
