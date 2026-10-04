# /terminal-setup — Fix terminal: Shift+Enter, truecolor, font, từng app

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ hướng dẫn + kiểm tra cấu hình terminal — không đụng code hay auth)

`/terminal-setup` chẩn đoán và hướng dẫn fix terminal ngoài: Shift+Enter không xuống dòng, màu xấu, font rỗ, Esc lag... cho từng app (iTerm2, VS Code, Kitty, Alacritty, Zed, Warp, WezTerm). Hiểu `/terminal-setup` là hiểu "thợ điện của xưởng" — CLI ngon mà điện (terminal) chập chờn thì làm gì cũng giật.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/terminal-setup` | _(không có)_ | Chẩn đoán terminal hiện tại + hướng dẫn fix (theo app phát hiện được) |
| `/terminal-setup <app>` | iterm2, vscode, kitty, alacritty, zed, warp, wezterm | Xem hướng dẫn cho app cụ thể (khi đang dùng app khác) |
| `/terminal-setup --check` | flag | Chỉ kiểm tra (không đổi gì): Shift+Enter? truecolor? font? |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: Shift+Enter hỏng — chạy chẩn đoán
/terminal-setup
# → "Detected: iTerm2 · Shift+Enter: ✗ (sends nothing) · Truecolor: ✓ · Fix: ..."
```

```bash
# Dạng 2: chuẩn bị đổi sang Kitty, xem trước cần chỉnh gì
/terminal-setup kitty
```

```bash
# Dạng 3: kiểm tra nhanh sau khi đổi máy
/terminal-setup --check
# → "Shift+Enter ✓ · Truecolor ✓ · Font ligatures ✓ · Esc delay 0ms ✓"
```

---

## Cách nó hoạt động

### Cơ chế sâu: vì sao Shift+Enter hay hỏng + fix từng app?

1. **Gốc bệnh:** Shift+Enter không phải ký tự chuẩn — mỗi terminal gửi 1 mã khác nhau (CSI `13;2u`, hoặc không gửi gì). CLI chỉ hiểu nếu mã tới nơi. Terminal "ăn" mất = CLI không bao giờ thấy = bạn Shift+Enter là gửi luôn dòng dở.
2. **Fix theo app (mỗi app 1 kiểu):**
   - **iTerm2:** Preferences → Profiles → Keys → bật `Left/Right Option as Esc+` (nếu cần) + đảm bảo `Shift+Enter` gửi `Escape [ 1 3 ; 2 u` (CSI-u). Bản mới có preset "Claude Code" — chọn là xong.
   - **VS Code:** `settings.json`: `"terminal.integrated.sendKeybindingsToShell": true`, keybinding `shift+enter` → `workbench.action.terminal.sendSequence` với `"\u001b[13;2u"`. Hoặc dùng Alt+Enter (VS Code ăn ít hơn).
   - **Kitty:** `kitty.conf`: `map shift+enter send_text all \x1b[13;2u`. Kitty hỗ trợ keyboard protocol tốt nhất — bật `modify_other_keys` là gần như không bao giờ hỏng.
   - **Alacritty:** `alacritty.toml`: `[keyboard] bindings = [{ key: "Enter", mods: "Shift", chars: "\x1b[13;2u" }]`.
   - **Zed:** settings → `terminal.send_keybindings_to_shell: true`, kiểm tra assistant panel keymap không đè Shift+Enter.
   - **Warp:** Settings → Features → bật `Send Shift+Enter as escape sequence`; Warp AI panel đôi khi "cướp" phím — tắt panel khi dùng Claude.
   - **WezTerm:** `wezterm.lua`: `keys = {{ key="Enter", mods="SHIFT", action=SendString("\x1b[13;2u") }}`. Bật `enable_kitty_keyboard = true` để ăn full protocol.
3. **Truecolor + font:** `/terminal-setup` kiểm tra `COLORTERM=truecolor`, gợi ý font Nerd Font (icon ✓⛔⎇ hiện đúng thay vì ô vuông), ligatures cho `→` `≠` đẹp.
4. **Esc delay:** `ESCDELAY`/`KEYTIMEOUT` cao (50ms+) là vim-mode `Esc` chậm — setup gợi trị số 10-25ms.
5. **Kiểm tra là local:** `--check` chỉ gửi mã test trong terminal, không gọi mạng, không tốn token.

### Checklist sau setup (copy-paste test)

```bash
/terminal-setup --check
# Expect: Shift+Enter ✓ · Truecolor ✓ · Font ✓ · Esc 10ms ✓
# Test tay:
# 1. Gõ "dòng 1" + Shift+Enter → phải XUỐNG DÒNG (không gửi)
# 2. Gõ "dòng 2" + Enter → gửi cả 2 dòng
# 3. /theme → màu chuyển mượt (truecolor OK)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Sửa ở đâu? | Dùng khi nào? |
|---|---|---|
| `/terminal-setup` | Terminal ngoài (app) | Phím/màu/font hỏng |
| `/keybindings` | Map phím trong CLI | Phím ăn rồi nhưng ngược tay |
| `/theme` | Màu CLI | Màu xấu nhưng terminal khoẻ |

> Quy tắc ngón tay cái:
>
> - **Bấm không ăn → `/terminal-setup` (điện). Bấm ăn nhưng ngược → `/keybindings` (nội thất). Nhìn xấu → `/theme` (sơn).**

---

## Ví dụ thực tế

### Kịch bản 1: iTerm2 — Shift+Enter gửi mất dòng dở (bệnh phổ biến nhất macOS)

```bash
/terminal-setup
# → "iTerm2 · Shift+Enter: ✗ nothing received"
# → Fix: Preferences → Profiles → Keys → + → Shift+Enter → Send Escape Sequence "[13;2u"
# → quay lại test: gõ 2 dòng, Shift+Enter xuống dòng ✓
```

> Kết quả: prompt nhiều dòng không còn gửi nửa chừng. Fix 1 lần nhớ cả năm.

### Kịch bản 2: VS Code terminal — Alt+Enter làm đường vòng

```bash
# VS Code cướp Shift+Enter cho editor dù đã sendKeybindingsToShell:
/terminal-setup vscode
# → gợi ý: dùng Alt+Enter thay thế (VS Code nhả phím này ngoan hơn)
# → /keybindings → multiline: Alt+Enter → xong, Shift giữ cho editor
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Copy config terminal từ internet mù | Keymap lạ đè phím khác (mất Ctrl+R tìm lịch sử...) | Áp từng dòng, test sau mỗi dòng; backup config terminal trước |
| Fix trên máy A, sang máy B tưởng còn | Config terminal theo app/máy, không theo account | Chạy `--check` mỗi máy mới; note lại fix của mình |
| Warp AI panel cướp phím | Shift+Enter vào AI panel thay vì Claude | Tắt panel/khác keymap khi dùng Claude Code |

### Tốn token?

- Không. Chẩn đoán terminal là thao tác local.

### Version / provider

- Mọi bản CLI đều có hướng dẫn cơ bản. Preset/CSI-u đầy đủ: v2.x + terminal bản mới (Kitty/WezTerm mới nhất ăn ngon nhất).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/terminal-setup` + `/keybindings` | Setup phím multiline | Setup terminal trước, remap sau |
| `/terminal-setup` + `/theme` | Setup nhìn | Truecolor OK → theme mới đẹp |
| `/terminal-setup` + `/vim` | Tay vim | Esc delay thấp → vim mượt |

Workflow chuẩn "máy mới setup terminal (5 phút)": `--check` → fix Shift+Enter theo app → font Nerd → truecolor → test 2 dòng.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Fix đúng hướng dẫn mà Shift+Enter vẫn gửi | tmux/screen ở giữa ăn mã (chưa passthrough) | `set -g extended-keys on` (tmux 3.2+); hoặc test ngoài tmux để loại trừ |
| Màu xấu dù truecolor ✓ | `TERM` sai (`xterm` thay vì `xterm-256color`) | `export TERM=xterm-256color` (hoặc theo app) |
| Icon hiện ô vuông □ | Thiếu Nerd Font | Cài font + chỉnh terminal dùng nó |
| Qua SSH mọi thứ hỏng | TERM không forward, tmux cũ trên server | `export TERM=xterm-256color` trên server; update tmux server |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../keybindings/README.md](../../auth-settings/keybindings/README.md) — map phím trong CLI sau khi terminal đã ngon
  - [../vim/README.md](../../auth-settings/vim/README.md) — Esc delay ảnh hưởng vim mode
  - [../theme/README.md](../../auth-settings/theme/README.md) — truecolor xong theme mới đẹp
  - [../statusline/README.md](../../auth-settings/statusline/README.md) — font Nerd cho icon statusline
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — setup terminal lần đầu
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — khác biệt terminal/IDE/web
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — (không liên quan trực tiếp)

> Mẹo 1 dòng: _Shift+Enter hỏng thì lỗi ở terminal chứ không phải Claude — `/terminal-setup` 2 phút là khỏi._
