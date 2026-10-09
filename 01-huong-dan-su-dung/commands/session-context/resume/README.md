# /resume — Mở lại phiên cũ theo ID/tên hoặc picker, tiếp tục đúng chỗ dang dở

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (không xóa/sửa file; chỉ nạp lại transcript cũ vào context — an toàn, nhưng có thể tốn tokens để nạp lại)
> **Nói nôm na:** `/resume` là "cỗ máy thời gian phiên làm việc": liệt kê các session trước (theo ID/tên), cho bạn mở lại đúng chỗ dang dở thay vì giải thích lại từ đầu. Cặp song sinh với CLI flags `--continue` / `--resume`.

## Khi nào dùng

- Dùng `/resume` khi bạn muốn mở lại đúng session cũ theo ID/tên thay vì giải thích lại từ đầu.
- Dùng `/resume` (và `/rename` trước khi nghỉ) để sáng hôm sau vào việc trong vài giây.
- Không dùng `/resume` khi đã chốt bỏ hướng cũ — nạp lại session dài chỉ làm context phình thêm.

## Cách gọi

```bash
`/resume`
`/resume <id-hoặc-tên>`
`claude --continue`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

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

| Triệu chứng | Vì sao | Cách sửa |
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
