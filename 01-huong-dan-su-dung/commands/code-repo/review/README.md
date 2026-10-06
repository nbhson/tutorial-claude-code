# /review — Xin nhận xét nhanh từ model hiện tại (không tạo subagent mới)

> Loại Built-in · Nhóm Code & Repo · Nguy hiểm Không (chỉ đọc + nhận xét; không sửa file; dùng cùng context phiên hiện tại)

> Nói nôm na: `/review` là "ê xem giúp code này ổn không": model hiện tại (cùng context, cùng lịch sử) đọc diff/code bạn chỉ định và cho nhận xét nhanh — bug, style, thiếu test. Nhanh gọn, nhưng cùng 1 bộ não nên dễ bỏ sót lỗi mà chính nó vừa gây ra. Muốn mắt mới thì dùng `/code-review`.

## Khi nào dùng

- Dùng /review khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /review **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /review thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/review`
`/review <file/PR>`
`/review --focus <mảng>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Vừa refactor login, muốn 1 vòng soi nhanh
/review
```

Kết quả mong đợi:

- Claude trả đúng việc của /review (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/review` khen hết lời nhưng code vẫn bug | Cùng agent tự chấm, mù cùng chỗ | Thêm `/code-review` (mắt mới) + `/verify` (chạy thật) |
| Review chung chung ("code ổn, nên thêm test") | Không chỉ rõ file/phạm vi, effort thấp | `/review src/x.ts` cụ thể + `/effort high` |
| `/review` soi cả file không liên quan | Mặc định đọc cả diff lớn | Chỉ định file: `/review src/payments/stripe.ts` |

## Tham khảo

- [../diff/README.md](../../code-repo/diff/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../ultrareview/README.md](../../code-repo/ultrareview/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /review sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
