# /btw — Hỏi nhanh full-context, không tools, không thêm history (by-the-way)

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (không gọi tools, không sửa file, không ghi history — hỏi xong là quên)

> Nói nôm na: `/btw` (by the way) là câu hỏi xen ngang: tận dụng full context hiện tại để trả lời nhanh 1 thắc mắc nhỏ — nhưng KHÔNG gọi tools (không đọc thêm file, không chạy lệnh) và KHÔNG thêm vào history hội thoại. Hỏi xong, phiên chính tiếp tục như chưa có gì xảy ra. Tiện cho "nhân tiện hỏi..." mà không muốn pollute mạch làm việc.

## Khi nào dùng

- Dùng /btw khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /btw **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /btw thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/btw <câu hỏi>`
`/btw`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/btw idempotency key là gì, vì sao webhook MoMo cần nó? 3 dòng thôi.
# → trả lời gọn từ context payments đang có.
# → mạch plan không bị xen 1 turn dài, history sạch.
```

Kết quả mong đợi:

- Claude trả đúng việc của /btw (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/btw` trả lời sai về file X | File X chưa trong context, btw không đọc mới | Hỏi trực tiếp (có tools) để model đọc file rồi trả lời |
| `/btw` báo unknown command | Bản cũ chưa có | Hỏi thường ngắn gọn thay thế |
| Ý hay từ btw bị mất | Không history by design | Hỏi lại bằng câu thường + bảo ghi ra file |

## Tham khảo

- [../fast/README.md](../../model-mode/fast/README.md)
- [../plan/README.md](../../model-mode/plan/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /btw sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
