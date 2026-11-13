# /terminal-setup — Fix terminal: Shift+Enter, truecolor, font, từng app

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ hướng dẫn + kiểm tra cấu hình terminal — không đụng code hay auth)
> **Nói nôm na:** `/terminal-setup` chẩn đoán và hướng dẫn fix terminal ngoài: Shift+Enter không xuống dòng, màu xấu, font rỗ, Esc lag... cho từng app (iTerm2, VS Code, Kitty, Alacritty, Zed, Warp, WezTerm). Hiểu `/terminal-setup` là hiểu "thợ điện của xưởng" — CLI ngon mà điện (terminal) chập chờn thì làm gì cũng giật.

## Khi nào dùng

- Dùng khi terminal "ăn mất" phím (Shift+Enter không xuống dòng), màu xấu, font rỗ, Esc lag — chạy theo đúng app bạn đang dùng (iTerm2, VS Code, Kitty...).
- Dùng **trước khi** soạn prompt nhiều dòng / vào task phải gõ nhiều — fix Shift+Enter từ đầu khỏi nuốt prompt giữa chừng.
- Không dùng `/terminal-setup` thay cho việc tự chỉnh đúng app đang dùng — kết quả đúng app nào phải chọn đúng app đó.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Chẩn đoán theo đúng app đang dùng và in bước fix cụ thể.
- Không đụng code/auth; chỉ hướng dẫn đổi cấu hình terminal.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các lỗi terminal hay gặp sau khi fix — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Fix đúng hướng dẫn mà Shift+Enter vẫn gửi | tmux/screen ở giữa ăn mã (chưa passthrough) | `set -g extended-keys on` (tmux 3.2+); hoặc test ngoài tmux để loại trừ |
| Màu xấu dù truecolor ✓ | `TERM` sai (`xterm` thay vì `xterm-256color`) | `export TERM=xterm-256color` (hoặc theo app) |
| Icon hiện ô vuông □ | Thiếu Nerd Font | Cài font + chỉnh terminal dùng nó |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng trên terminal, "Vì sao" chỉ tầng gây lỗi (tmux, biến môi trường, font), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/terminal-setup` là thợ điện cho xưởng CLI: điện (terminal) chập chờn thì sửa điện, đừng đổ lỗi cho máy móc (model).

## Tham khảo

- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../vim/README.md](../../auth-settings/vim/README.md)
- [../theme/README.md](../../auth-settings/theme/README.md)
- [../statusline/README.md](../../auth-settings/statusline/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /terminal-setup sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
