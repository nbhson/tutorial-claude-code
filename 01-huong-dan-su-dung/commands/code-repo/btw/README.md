# /btw — hỏi nhanh trong context hiện tại, không mở mạch dài

> Loại Built-in · Nhóm Session/Realtime · Mức rủi ro Không
> **Nói nôm na:** `/btw` giúp bạn hỏi 1 câu ngắn, gọn trong context hiện tại mà không kéo turn dài. Trả lời nhanh, sạch history.

## Khi nào dùng

- Dùng `/btw` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/btw` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/btw` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/btw <câu hỏi>`
`/btw`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/btw idempotency key là gì, vì sao webhook MoMo cần nó? 3 dòng thôi.
# → trả lời gọn từ context payments đang có.
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/btw` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/btw` trả lời sai về file X | File X chưa trong context, `/btw` không đọc mới | Hỏi trực tiếp (có tools) để model đọc file rồi trả lời |
| `/btw` báo unknown command | Bản cũ chưa có | Hỏi thường ngắn gọn thay thế |
| Ý hay từ `/btw` bị mất | Không lưu history by design | Hỏi lại bằng câu thường + bảo ghi ra file |

## Tham khảo

- [../../model-mode/fast/README.md](../../model-mode/fast/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../../model-mode/model/README.md](../../model-mode/model/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/btw` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
