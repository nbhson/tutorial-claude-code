# /simplify — Làm code đơn giản lại: bớt phức tạp, giữ nguyên tính năng

> Loại Skill (refactor) · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ refactor; nhưng Có nhẹ nếu simplify đụng logic tinh vi — luôn chạy test sau)

> Nói nôm na: `/simplify`要求 model đọc 1 hàm/file bạn chỉ định, đo độ phức tạp (lồng nhau, nhánh, dài), rồi đề xuất bản gọn hơn mà test vẫn xanh: tách hàm, gộp nhánh, bỏ code chết, đặt tên rõ. Khác `/review` (tìm lỗi) và `/refactor` chung chung (đổi cấu trúc) — simplify chỉ theo 1 hướng: đơn giản hơn.

## Khi nào dùng

- Dùng /simplify khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /simplify **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /simplify thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/simplify <file>`
`/simplify <file>:<hàm>`
`/simplify --aggressive`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/simplify api/auth.py:login
# Trước: if user: → if pw: → if not locked: → try: ... (sâu 5)
# Sau: 4 early-return (không user → raise; sai pw → raise...) + thân chính 10 dòng phẳng
# → test auth xanh → commit
```

Kết quả mong đợi:

- Claude trả đúng việc của /simplify (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Simplify xong test đỏ | Đổi hành vi (bỏ nhánh cần thiết) | Hoàn tác, simplify từng chiêu nhỏ thay vì 1 lần lớn |
| Model chỉ format, không gọn | Hàm đã gọn hoặc prompt chung quá | Chỉ hàm cụ thể + `--aggressive`; đo số trước (độ sâu/nhánh) |
| Gọn xong khó đọc hơn (golf-code) | Model lạm dụng one-liner | Quy tắc: tên rõ > ngắn; từ chối bản lạm dụng comprehension 3 tầng |

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../review/README.md](../../code-repo/review/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /simplify sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
