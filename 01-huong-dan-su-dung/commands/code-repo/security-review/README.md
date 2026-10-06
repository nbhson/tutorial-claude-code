# /security-review — Lượt quét bảo mật on-demand trên branch hiện tại

> Loại Built-in · Nhóm Review & Bảo mật · Nguy hiểm Không (chỉ đọc + báo cáo; nhưng Có nếu bạn auto-apply fix bảo mật mà không review — patch sai có thể mở lỗ hổng mới)

> Nói nôm na: `/security-review` chạy một lượt kiểm tra bảo mật theo yêu cầu (on-demand) trên branch hiện tại: soi diff + file nhạy cảm, xếp hạng lỗ hổng theo mức độ, gợi ý patch từng chỗ (bạn duyệt mới sửa). Nó đi cặp với GitHub Action review PR tự động (comment inline từng dòng, lọc false-positive), nhưng lượt tay này sâu hơn vì bạn đối thoại được. Hiểu `/security-review` là hiểu "vòng check bảo mật trước khi gọi `/review` hay mở PR".

## Khi nào dùng

- Dùng /security-review khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /security-review **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /security-review thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/security-review`
`/security-review --quick`
`/security-review <path>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Vừa xong feature Stripe, chuẩn bị mở PR:
git status
# M  src/payments/stripe.ts
# M  src/auth/middleware.ts
# A  src/payments/webhook.ts

/security-review

```

Kết quả mong đợi:

- Claude trả đúng việc của /security-review (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Quét báo "no changes" dù vừa code | Branch chưa commit + không dùng `--quick`; mặc định so với base nên diff unstaged bị bỏ | Dùng `/security-review --quick` cho code chưa commit, hoặc commit rồi quét full |
| Toàn LOW nhiễu, không có gì thật | Sensitivity `high` trên code đã có guard đầy đủ | Về `medium`; đọc LOW lướt qua, chỉ fix khi chạm PII/tiền |
| Bỏ sót secret trong `.env` | `.env` trong `.gitignore` nên không nằm trong diff → tool không thấy | Tự `git grep -i "sk-\|api[_-]key" -- . ':!.git'` bằng mắt; thêm pre-commit hook quét secret |

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../ultrareview/README.md](../../code-repo/ultrareview/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /security-review sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
