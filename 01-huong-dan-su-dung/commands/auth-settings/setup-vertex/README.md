# /setup-vertex — Wizard cắm Claude Code vào Google Vertex AI

> Loại Built-in · Nhóm Provider & Cloud · Mức rủi ro Thấp (chỉ ghi config + test kết nối; nhưng Có nếu bạn dán service-account JSON vào repo — để ngoài repo + gitignore)
> **Nói nôm na:** `/setup-vertex` là wizard cấu hình Claude Code chạy qua Google Vertex AI: hỏi project, region, auth (`gcloud` ADC/service-account), ghi config rồi test 1 câu chào. Sinh ra cho team đã ở GCP (billing chung, IAM org, data residency EU...) muốn xài Claude qua hạ tầng Google. Hiểu `/setup-vertex` là hiểu "anh em song sinh của `/setup-bedrock`, nhưng đấu vào ổ điện Google".

## Khi nào dùng

- Dùng khi bạn/team muốn xài Claude qua Google Vertex AI (billing chung, IAM org, data residency EU...) thay vì tài khoản claude.ai.
- Dùng **trước khi** làm việc thật trên repo dùng Vertex (máy mới, đầu project): wizard chạy 1 lần xong project + region + auth, khỏi sửa tay lúc gấp.
- Không dùng `/setup-vertex` thay cho việc tự giữ service-account key an toàn — JSON phải để ngoài repo + gitignore.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Wizard ghi config Vertex (project + region + auth) rồi test 1 câu chào.
- `/status` báo đang chạy qua Vertex AI thay vì tài khoản claude.ai.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các lỗi kết nối/quyền hay gặp khi cắm Claude Code vào Google Vertex AI — message lỗi báo rõ nguyên nhân, tra đúng dòng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| "API aiplatform.googleapis.com not enabled" | Project chưa bật Vertex AI API | Console bật API (link wizard đưa); đợi 2-3 phút propagation rồi chạy lại |
| "Model not found in region" dù auth OK | Sai region (region đó chưa có Claude) | Đổi region có Claude (`asia-southeast1`/`us-central1`... check docs); đừng sửa auth |
| "Permission denied aiplatform.endpoints.predict" | Thiếu role `aiplatform.user` | Xin role tối thiểu; test `gcloud ai models list --region=...` |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là message lỗi bạn thấy, "Vì sao" chỉ tầng gây lỗi (API/region/quyền), "Cách sửa" là bước xử lý tương ứng.

> **Tóm gọn 1 câu:** `/setup-vertex` cắm phích một lần là xong: project đúng, region có Claude, role đủ — sau đó mọi session chạy qua hạ tầng Google nhà mình.

## Tham khảo

- [../setup-bedrock/README.md](../../auth-settings/setup-bedrock/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /setup-vertex sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
