# /ide — Gắn Claude Code vào IDE: VS Code, JetBrains, diff inline, jump-to-file

> Loại Built-in · Nhóm Remote · Nguy hiểm Không (chỉ kết nối editor — nhưng Có nhẹ nếu IDE mở folder nhạy cảm mà Claude được đọc toàn workspace)

> Nói nôm na: `/ide` kết nối session terminal với IDE đang mở: Claude đọc file bạn đang xem, hiện diff inline để duyệt, `jump-to-file` từ lỗi sang đúng dòng, chạy test rồi hiện kết quả trong editor. Hiểu `/ide` là hiểu "mời Claude ngồi cùng bàn IDE" — não vẫn ở terminal, mắt thêm ở editor.

## Khi nào dùng

- Dùng /ide khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /ide **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /ide thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/ide`
`/ide connect`
`/ide disconnect`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# VS Code đang mở auth.ts, bôi đen hàm login:
# Sang terminal:
/ide connect
# Hỏi: "sửa hàm này cho chịu được email viết hoa"
# → Claude tự biết file + selection, sửa đúng chỗ, diff hiện inline trong IDE
# → duyệt từng hunk bằng phím IDE, xong chạy test
```

Kết quả mong đợi:

- Claude trả đúng việc của /ide (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `No IDE detected` | Chưa cài extension hoặc IDE mở folder khác | Cài extension; mở đúng folder; connect lại |
| Diff không hiện inline | Extension cũ hoặc file quá lớn | Update extension; file >1MB duyệt bằng text |
| Diagnostics không sang | Extension chưa quyền đọc problems panel | Bật trong settings extension; reload IDE |

## Tham khảo

- [../vim/README.md](../../auth-settings/vim/README.md)
- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../cd/README.md](../../auth-settings/cd/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /ide sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
