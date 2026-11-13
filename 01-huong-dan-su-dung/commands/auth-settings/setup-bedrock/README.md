# /setup-bedrock — Wizard cắm Claude Code vào AWS Bedrock

> Loại Built-in · Nhóm Provider & Cloud · Mức rủi ro Thấp (chỉ ghi config + test kết nối; nhưng Có nếu bạn dán access key vào file rồi commit — dùng IAM role/SSO thay vì key cứng)
> **Nói nôm na:** `/setup-bedrock` là wizard cấu hình Claude Code chạy qua AWS Bedrock: hỏi region, model entitlement, auth (IAM role/SSO/keys), ghi config rồi test 1 câu chào. Sinh ra cho team đã ở AWS (quỹ tín dụng, compliance, VPC) muốn xài Claude qua hạ tầng nhà. Hiểu `/setup-bedrock` là hiểu "đấu dây từ Claude Code vào ổ điện AWS".

## Khi nào dùng

- Dùng khi bạn/team muốn xài Claude qua AWS Bedrock (quỹ tín dụng AWS, compliance, VPC) thay vì tài khoản claude.ai.
- Dùng **trước khi** làm việc thật trên repo dùng Bedrock (máy mới, đầu project): wizard chạy 1 lần xong auth + region + model, khỏi sửa cấu hình tay lúc gấp.
- Không dùng `/setup-bedrock` thay cho việc tự lo IAM/SSO từ công ty — wizard chỉ cấu hình client, quyền hạn phải do admin cấp.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Wizard ghi config Bedrock (region + auth + model) rồi test 1 câu chào.
- `/status` báo đang chạy qua Bedrock thay vì tài khoản claude.ai.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các lỗi kết nối/quyền hay gặp khi cắm Claude Code vào AWS Bedrock — lỗi nào cũng báo rõ qua message, tra đúng dòng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| "Model not available in region" dù auth OK | Sai region hoặc model chưa enable trong console | Console → Bedrock → Model access → Enable; chọn region có Claude |
| "ExpiredToken / InvalidClientTokenId" | Key cũ 90 ngày / SSO session hết hạn | `aws sso login` lại; key cứng thì chuyển SSO/role cho bền |
| "AccessDenied: not authorized bedrock:InvokeModel" | IAM policy thiếu quyền | Xin policy `bedrock:InvokeModel` trên ARN model; test bằng `aws bedrock list-foundation-models` |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là message lỗi bạn copy được từ log, "Vì sao" chỉ tầng gây lỗi (region/auth/quyền), "Cách sửa" là bước xử lý tương ứng.

> **Tóm gọn 1 câu:** `/setup-bedrock` cắm phích một lần là xong: region đúng, auth đúng, model enable — sau đó mọi session chạy qua hạ tầng AWS nhà mình.

## Tham khảo

- [../setup-vertex/README.md](../../auth-settings/setup-vertex/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /setup-bedrock sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
