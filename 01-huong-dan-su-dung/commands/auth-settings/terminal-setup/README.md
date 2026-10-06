# /terminal-setup — Fix terminal: Shift+Enter, truecolor, font, từng app

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ hướng dẫn + kiểm tra cấu hình terminal — không đụng code hay auth)

> Nói nôm na: `/terminal-setup` chẩn đoán và hướng dẫn fix terminal ngoài: Shift+Enter không xuống dòng, màu xấu, font rỗ, Esc lag... cho từng app (iTerm2, VS Code, Kitty, Alacritty, Zed, Warp, WezTerm). Hiểu `/terminal-setup` là hiểu "thợ điện của xưởng" — CLI ngon mà điện (terminal) chập chờn thì làm gì cũng giật.

## Khi nào dùng

- Dùng /terminal-setup khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /terminal-setup **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /terminal-setup thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/terminal-setup`
`/terminal-setup <app>`
`/terminal-setup --check`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/terminal-setup
# → "iTerm2 · Shift+Enter: ✗ nothing received"
# → Fix: Preferences → Profiles → Keys → + → Shift+Enter → Send Escape Sequence "[13;2u"
# → quay lại test: gõ 2 dòng, Shift+Enter xuống dòng ✓
```

Kết quả mong đợi:

- Claude trả đúng việc của /terminal-setup (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Fix đúng hướng dẫn mà Shift+Enter vẫn gửi | tmux/screen ở giữa ăn mã (chưa passthrough) | `set -g extended-keys on` (tmux 3.2+); hoặc test ngoài tmux để loại trừ |
| Màu xấu dù truecolor ✓ | `TERM` sai (`xterm` thay vì `xterm-256color`) | `export TERM=xterm-256color` (hoặc theo app) |
| Icon hiện ô vuông □ | Thiếu Nerd Font | Cài font + chỉnh terminal dùng nó |

## Tham khảo

- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../vim/README.md](../../auth-settings/vim/README.md)
- [../theme/README.md](../../auth-settings/theme/README.md)
- [../statusline/README.md](../../auth-settings/statusline/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /terminal-setup sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
