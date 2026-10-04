# /keybindings — Xem và đổi phím tắt: Ctrl, Alt, Esc, vim-style

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ đổi phím — nhưng Có nhẹ nếu remap đè phím huỷ lệnh quen tay rồi bấm nhầm lúc nguy hiểm)

`/keybindings` liệt kê và remap phím tắt CLI: gửi prompt, huỷ lệnh, duyệt permission, lịch sử, multi-line... Hiểu `/keybindings` là hiểu "sắp lại bàn phím cho vừa tay" — tay vim, tay Emacs, tay IDE đều có chỗ.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/keybindings` | _(không có)_ | Mở bảng phím hiện tại (theo nhóm) |
| `/keybindings set <hành-động> <phím>` | action + key | Remap 1 phím (ví dụ `cancel Ctrl+G`) |
| `/keybindings reset` | action | Về mặc định (1 phím hoặc tất cả với `--all`) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem đang có phím gì
/keybindings
# → Send: Enter · Cancel: Ctrl+C · History: ↑/↓ · Multiline: Alt+Enter...
```

```bash
# Dạng 2: tay vim — huỷ lệnh bằng Ctrl+G cho gần
/keybindings set cancel Ctrl+G
```

```bash
# Dạng 3: remap lỗi, về zin
/keybindings reset --all
```

```bash
# Dạng 4: xem phím của 1 nhóm
/keybindings permission
# → Yes: y · No: n · Yes-all-session: shift+y...
```

---

## Cách nó hoạt động

### Cơ chế sâu: keybindings ánh xạ thế nào?

1. **Bảng ánh xạ action → key:** mỗi hành động (send, cancel, history, permission-yes/no, autocomplete-accept...) có key mặc định. Remap ghi vào local settings (`keybindings: {"cancel": "Ctrl+G"}`) — theo máy, không theo repo.
2. **Xung đột terminal:** `Ctrl+C`, `Ctrl+D`, `Shift+Enter` là terminal "ăn" trước rồi mới tới CLI — remap mà terminal chặn thì không ăn (phải fix ở `/terminal-setup`: iTerm2/VSCode/Ktty/Alacritty/Zed/Warp/WezTerm mỗi cái 1 kiểu).
3. **Vim mode liên quan:** bật `/vim` thì `Esc` về normal mode, `i` nhập lại — keybindings insert-mode vẫn giữ, normal-mode theo vim.
4. **Permission phím nhanh nguy hiểm nhất:** `shift+y` (yes cả session) gần `y` (yes 1 lần) — bấm nhầm là mở toang cả buổi. Tay to thì remap `yes-all` ra xa hoặc tắt hẳn.

### Bảng mặc định đáng nhớ

```text
Enter        gửi prompt (Shift+Enter / Alt+Enter: xuống dòng — cần terminal-setup đúng)
Ctrl+C       huỷ lệnh đang chạy (bấm 2 lần: thoát CLI)
↑ / ↓        lịch sử prompt · Tab: gợi ý · Esc: đóng popup
y / n        Yes/No permission · shift+y: yes cả session (CẨN THẬN)
Ctrl+R       tìm lịch sử · Ctrl+L: dọn màn hình (giữ context)
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Đổi gì? | Dùng khi nào? |
|---|---|---|
| `/keybindings` | Phím bấm | Phím mặc định ngược tay |
| `/vim` | Chế độ soạn (normal/insert) | Tay vim muốn `hjkl` khắp nơi |
| `/terminal-setup` | Cấu hình terminal ngoài | Phím bị terminal ăn mất |

> Quy tắc ngón tay cái:
>
> - **Bấm không ăn → `/terminal-setup` trước (terminal ăn mất). Bấm ăn nhưng ngược tay → `/keybindings`.**

---

## Ví dụ thực tế

### Kịch bản 1: Shift+Enter không xuống dòng mà gửi luôn (bệnh kinh điển)

```bash
# Gõ prompt 2 dòng, Shift+Enter lại gửi mất:
/keybindings
# → Multiline: Shift+Enter (đúng rồi — vậy là terminal ăn mất, không phải CLI sai)
# → sang /terminal-setup fix theo terminal đang dùng (iTerm2/VSCode/Kitty...)
# → quay lại test: Shift+Enter xuống dòng ✓
```

> Kết quả: biết bệnh ở terminal chứ không phải CLI — khỏi remap lung tung.

### Kịch bản 2: Tay vim — gom phím huỷ/duyệt về gần home row

```bash
/keybindings set cancel Ctrl+G
/keybindings set permission-yes Ctrl+Y
# → tay không rời home row, duyệt nhanh mà không với xa
# → shift+y (yes-all) giữ nguyên xa xa để khỏi bấm nhầm
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Remap `cancel` sang phím lạ rồi quên | Lúc lệnh nguy hiểm chạy, bấm mãi không huỷ được | Giữ `Ctrl+C` luôn là 1 trong các cách huỷ; ghi lại map mới vào note |
| `yes-all` để gần `yes` | Bấm nhầm mở toang cả session | Remap `yes-all` ra xa hoặc không dùng; đọc bài 10 |
| Keybindings theo máy, sang máy mới tưởng còn | Teleport không mang keybindings (local scope) | Cấu lại mỗi máy hoặc sync file settings tay |

### Tốn token?

- Không. Phím là input local.

### Version / provider

- Remap custom: v2.x. Bản cũ chỉ xem, không sửa.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/keybindings` + `/terminal-setup` | Phím multiline không ăn | Setup terminal trước, remap sau |
| `/keybindings` + `/vim` | Tay vim full | Vim mode + remap insert-mode |
| `/keybindings` + `/permissions` | Duyệt nhanh mà an toàn | Phím yes gần, yes-all xa |

Workflow chuẩn "setup phím 5 phút": `/terminal-setup` (Shift+Enter ăn) → `/keybindings` (xem) → remap 1-2 phím ngược tay → test.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Remap xong bấm không ăn | Terminal/compositor ăn phím trước | `/terminal-setup` fix terminal; chọn phím khác ít đụng (Ctrl+G, Alt+...) |
| `Ctrl+C` không huỷ được nữa | Remap đè mất | `/keybindings reset cancel`; luôn giữ 1 cách huỷ quen |
| Sang máy mới phím khác | Local scope không đi theo | Sync `~/.claude/settings.json` tay hoặc cấu lại |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../vim/README.md](../vim/README.md) — chế độ vim (phím normal/insert)
  - [../terminal-setup/README.md](../terminal-setup/README.md) — fix terminal ăn phím (Shift+Enter...)
  - [../statusline/README.md](../statusline/README.md) — (hiển thị, không phải phím)
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — setup lần đầu
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — phím khác nhau mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — phím duyệt permission và an toàn

> Mẹo 1 dòng: _giữ `yes-all` xa khỏi `yes` — 1 phím gần nhau có thể tốn cả buổi dọn hậu quả._
