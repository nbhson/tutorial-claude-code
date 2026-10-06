# /resume — Mở lại phiên cũ theo ID/tên hoặc picker, tiếp tục đúng chỗ dang dở

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file; chỉ nạp lại transcript cũ vào context — an toàn, nhưng có thể tốn tokens để nạp lại)

> Nói nôm na: `/resume` là "cỗ máy thời gian phiên làm việc": liệt kê các session trước (theo ID/tên), cho bạn mở lại đúng chỗ dang dở thay vì giải thích lại từ đầu. Cặp song sinh với CLI flags `--continue` / `--resume`.

## Khi nào dùng

- Dùng /resume khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /resume **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /resume thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/resume`
`/resume <id-hoặc-tên>`
`claude --continue`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Tối thứ Sáu: đang dở bước mock webhook, đặt tên trước khi về
/rename payments-fix

# Sáng thứ Hai: mở terminal trong cùng thư mục dự án
/resume payments-fix
# → model: "Chào, hôm trước ta đang dở bước mock webhook ở src/payments/webhook.test.ts. Tiếp tục nhé?"

# Hỏi tiếp, không cần giải thích lại
```

Kết quả mong đợi:

- Claude trả đúng việc của /resume (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/resume` picker trống | Đứng sai thư mục / sai profile / transcript bị xóa | `pwd` kiểm tra repo, đăng nhập đúng account, kiểm tra `~/.claude/projects/` còn file không |
| `/resume <tên>` báo not found | Sai tên (phân biệt hoa/thường, dấu `-`/`_`) hoặc tên có khoảng trắng chưa quote | Gõ `/resume` không tham số để picker rồi copy tên chính xác; quote nếu có space: `/resume "my session"` |
| Resume xong context vọt 70% | Session cũ quá dài, nạp nguyên 100+ turns | `/compact` ngay với focus rõ; lần sau compact trước khi nghỉ |

## Tham khảo

- [../fork/README.md](../../session-context/fork/README.md)
- [../branch/README.md](../../session-context/branch/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../rename/README.md](../../session-context/rename/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /resume sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
