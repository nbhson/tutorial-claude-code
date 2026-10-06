# /setup-vertex — Wizard cắm Claude Code vào Google Vertex AI

> Loại Built-in · Nhóm Provider & Cloud · Nguy hiểm Thấp (chỉ ghi config + test kết nối; nhưng Có nếu bạn dán service-account JSON vào repo — để ngoài repo + gitignore)

> Nói nôm na: `/setup-vertex` là wizard cấu hình Claude Code chạy qua Google Vertex AI: hỏi project, region, auth (`gcloud` ADC/service-account), ghi config rồi test 1 câu chào. Sinh ra cho team đã ở GCP (billing chung, IAM org, data residency EU...) muốn xài Claude qua hạ tầng Google. Hiểu `/setup-vertex` là hiểu "anh em song sinh của `/setup-bedrock`, nhưng đấu vào ổ điện Google".

## Khi nào dùng

- Dùng /setup-vertex khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /setup-vertex **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /setup-vertex thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/setup-vertex`
`/setup-vertex --check`
`/status`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Login ADC trước:
gcloud auth application-default login --project my-team-123
# → browser OK

/setup-vertex
# → project my-team-123 [Yes] → region asia-southeast1 [Yes]
# → auth ADC [Yes] → model sonnet [Yes]
# → test "hello" → "Hello! (via Vertex, 1.4s)" ✓
```

Kết quả mong đợi:

- Claude trả đúng việc của /setup-vertex (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| "API aiplatform.googleapis.com not enabled" | Project chưa bật Vertex AI API | Console bật API (link wizard đưa); đợi 2-3 phút propagation rồi chạy lại |
| "Model not found in region" dù auth OK | Sai region (region đó chưa có Claude) | Đổi region có Claude (`asia-southeast1`/`us-central1`... check docs); đừng sửa auth |
| "Permission denied aiplatform.endpoints.predict" | Thiếu role `aiplatform.user` | Xin role tối thiểu; test `gcloud ai models list --region=...` |

## Tham khảo

- [../setup-bedrock/README.md](../../auth-settings/setup-bedrock/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /setup-vertex sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
