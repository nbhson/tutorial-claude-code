# /vim — Chế độ vim: normal/insert, hjkl, soạn prompt như soạn code

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ đổi cách soạn phím — nhưng Có nhẹ nếu normal-mode bấm nhầm `shift+y` duyệt permission lúc đang tưởng mình soạn text)

`/vim` bật/tắt chế độ soạn kiểu vim trong khung nhập: `Esc` về normal (`hjkl` di chuyển, `w/b` nhảy từ, `dd` xoá dòng), `i/a/o` vào insert gõ tiếp. Hiểu `/vim` là hiểu "khung chat cũng là buffer vim" — tay vim khỏi rời home row.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/vim` | _(không có)_ | Bật/tắt vim mode (toggle) |
| `/vim on` | flag | Bật (mặc định insert, `Esc` về normal) |
| `/vim off` | flag | Tắt (về soạn thường/Emacs-style) |
| `/vim --status` | flag | Xem đang on/off + map nào custom |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: bật (tay vim)
/vim on
# → "Vim mode: ON (insert default, Esc → normal)"
```

```bash
# Dạng 2: thử rồi không hợp, tắt
/vim off
```

```bash
# Dạng 3: kiểm tra (sang máy mới hay quên)
/vim --status
```

---

## Cách nó hoạt động

### Cơ chế sâu: vim mode trong khung nhập là gì?

1. **2 mode, 1 khung:** insert (gõ như thường, keybindings CLI giữ nguyên) và normal (`hjkl`, `w/b/e`, `0/$`, `dd/yy/p`, `/` tìm trong prompt đang soạn). `Esc`/`Ctrl+[` về normal, `i/a/o` vào insert.
2. **Chỉ ảnh hưởng khung nhập:** normal-mode `dd` xoá dòng prompt đang soạn — KHÔNG xoá file repo, KHÔNG gửi prompt. `Enter` ở normal vẫn gửi (cẩn thận khi `o` nhầm thành `Enter`).
3. **Lưu ở đâu?** `vim: true/false` trong local settings — theo máy. Sang máy mới (teleport) phải bật lại.
4. **Kết hợp keybindings:** insert-mode dùng map `/keybindings`; normal-mode theo vim chuẩn + vài map CLI (permission `y/n`). Đừng remap `Esc` — mất đường về normal.
5. **Khi nào TẮT tốt hơn?** Pair với người không vim (họ gõ là loạn), hoặc vừa bật vừa học vim (normal-mode bấm nhầm `y` duyệt permission — nguy hiểm nhất của lệnh này).

### Khác gì với lệnh dễ nhầm?

| Lệnh | Vim ở đâu? | Dùng khi nào? |
|---|---|---|
| `/vim` | Khung nhập CLI | Soạn prompt dài, sửa giữa dòng nhiều |
| Vim thật (nvim) | Editor ngoài | Sửa file repo (kết hợp `/ide`) |
| `/keybindings` | Map phím từng action | Phím ngược tay (không phải mode soạn) |

> Quy tắc ngón tay cái:
>
> - **Soạn prompt 5+ dòng mỗi ngày → `/vim on`. Gõ 1 dòng ngắn → khỏi bật.**

---

## Ví dụ thực tế

### Kịch bản 1: Soạn prompt spec dài, sửa giữa đoạn không cần chuột

```bash
/vim on
# Gõ spec 20 dòng (insert) → Esc → /auth → nhảy tới chỗ cần sửa
# → cw sửa từ, yy p nhân bản đoạn, i gõ tiếp, Enter gửi
# → prompt dài mà sửa nhanh như sửa code
```

### Kịch bản 2: Tắt gấp khi pair với người không vim

```bash
# Đồng nghiệp ngồi cùng, họ gõ mà màn hình cứ nhảy mode:
/vim off
# → về soạn thường, ai gõ cũng được. Hôm sau một mình thì /vim on lại
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Normal-mode bấm nhầm `y` (tưởng yank) đúng lúc dialog permission hiện | Duyệt Yes việc nguy hiểm trong vô thức | Khi dialog hiện, nhìn kỹ rồi mới bấm; cân nhắc tắt vim nếu hay nhầm |
| `Esc` trong tmux/IDE ăn mất | Không về được normal, tưởng vim hỏng | `/terminal-setup` fix Esc passthrough; `Ctrl+[` là đường vòng |
| Vim mode theo máy, sang máy mới mất | Tưởng còn, bấm `hjkl` ra chữ | `/vim --status` sau teleport; bật lại 1 giây |

### Tốn token?

- Không. Mode soạn là input local.

### Version / provider

- Vim mode cơ bản mọi bản v2. Custom map normal-mode: bản mới hơn.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/vim` + `/keybindings` | Tay vim full-stack | Vim mode + remap insert cho vừa tay |
| `/vim` + `/ide` | Soạn prompt kiểu vim, duyệt diff kiểu IDE | Cả 2 cùng bật, không xung đột |
| `/vim` + multiline | Prompt dài nhiều dòng | Vim `o` mở dòng + Shift+Enter (cần terminal-setup) |

Workflow chuẩn "tay vim setup 3 phút": `/terminal-setup` (Esc ăn) → `/vim on` → `/keybindings` (remap insert) → test soạn 5 dòng.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `Esc` không về normal | Terminal/tmux ăn Esc | Fix terminal-setup; dùng `Ctrl+[` tạm |
| `hjkl` gõ ra chữ thay vì di chuyển | Đang insert (chưa Esc) hoặc vim off | `Esc` trước; `/vim --status` kiểm tra |
| `dd` tưởng xoá file | Hiểu nhầm scope — chỉ xoá dòng prompt | Yên tâm, nhưng đọc lại mục cơ chế để chắc |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../keybindings/README.md](../../auth-settings/keybindings/README.md) — map phím từng action (insert-mode)
  - [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md) — fix Esc/Shift+Enter bị terminal ăn
  - [../ide/README.md](../../auth-settings/ide/README.md) — vim thật trong editor ngoài
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — setup lần đầu
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — soạn prompt mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — đừng bấm nhầm Yes khi đang normal-mode

> Mẹo 1 dòng: _bật vim cho khung chat — nhưng khi dialog permission hiện, mắt nhìn trước tay bấm sau._
