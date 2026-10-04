# /ide — Gắn Claude Code vào IDE: VS Code, JetBrains, diff inline, jump-to-file

> Loại Built-in · Nhóm Remote · Nguy hiểm Không (chỉ kết nối editor — nhưng Có nhẹ nếu IDE mở folder nhạy cảm mà Claude được đọc toàn workspace)

`/ide` kết nối session terminal với IDE đang mở: Claude đọc file bạn đang xem, hiện diff inline để duyệt, `jump-to-file` từ lỗi sang đúng dòng, chạy test rồi hiện kết quả trong editor. Hiểu `/ide` là hiểu "mời Claude ngồi cùng bàn IDE" — não vẫn ở terminal, mắt thêm ở editor.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/ide` | _(không có)_ | Hiện trạng thái kết nối + hướng dẫn gắn |
| `/ide connect` | action | Gắn vào IDE đang mở ở workspace này |
| `/ide disconnect` | action | Ngắt kết nối (Claude không đọc IDE nữa) |
| `/ide --list` | flag | Liệt kê IDE/editor phát hiện được |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở VS Code ở repo rồi gắn
/ide connect
# → "Connected to VS Code (workspace /repo) · current file: api/auth.ts"
```

```bash
# Dạng 2: kiểm tra đang gắn gì
/ide
# → "Connected: VS Code · open files: 3 · diff inline: on"
```

```bash
# Dạng 3: nghỉ dùng, ngắt cho nhẹ
/ide disconnect
```

---

## Cách nó hoạt động

### Cơ chế sâu: ide integrations là gì?

1. **Kết nối qua extension + socket local:** IDE cần extension Claude (VS Code marketplace / JetBrains plugin). `/ide connect` bắt tay qua socket local: terminal gửi session ID, extension trả workspace path + file đang mở + con trỏ.
2. **Claude biết bạn đang xem gì:** file active + selection + diagnostics (lỗi đỏ IDE) chảy vào context — bạn nói "sửa hàm này" mà không cần copy tên file.
3. **Diff inline:** Edit của Claude hiện như diff editor (xanh/đỏ từng dòng) — duyệt/undo bằng phím IDE quen tay thay vì đọc patch text.
4. **Jump-to-file:** lỗi test `auth.ts:42` thành link bấm là nhảy đúng dòng. Ngược lại từ IDE bấm "Ask Claude" gửi selection sang terminal.
5. **Workspace = attack surface:** IDE mở cả repo là Claude đọc được cả repo (theo permissions). Đừng mở folder cha chứa secret (`~/` cả home) rồi hỏi bừa.

### Khác gì với lệnh dễ nhầm?

| Lệnh | Não ở đâu? | Dùng khi nào? |
|---|---|---|
| `/ide` | Terminal + mắt ở IDE | Sửa code có duyệt diff trực quan |
| Terminal thuần | Terminal hết | SSH, server, thích phím |
| Web (claude.ai) | Cloud | Không có IDE, việc mới |

> Quy tắc ngón tay cái:
>
> - **Có IDE mở thì `/ide connect` — miễn phí mà duyệt diff sướng hơn hẳn.**

---

## Ví dụ thực tế

### Kịch bản 1: Sửa bug "hàm này" không cần nói tên file

```bash
# VS Code đang mở auth.ts, bôi đen hàm login:
# Sang terminal:
/ide connect
# Hỏi: "sửa hàm này cho chịu được email viết hoa"
# → Claude tự biết file + selection, sửa đúng chỗ, diff hiện inline trong IDE
# → duyệt từng hunk bằng phím IDE, xong chạy test
```

> Kết quả: khỏi copy-paste tên file/dòng. Selection là context miễn phí.

### Kịch bản 2: Test đỏ — từ lỗi nhảy thẳng tới dòng

```bash
# Chạy test, lỗi auth.ts:42 + user.ts:17:
# Trong IDE: lỗi thành link (nhờ diagnostics chảy sang)
# Bấm link → nhảy đúng dòng → hỏi "sửa cả 2 chỗ này"
# → Claude sửa, diff inline hiện 2 file, duyệt 1 lượt
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| IDE mở cả home (`~/`) | Claude thấy `.ssh`, `.aws`, ảnh cá nhân... | Mở đúng folder repo, không mở quá rộng |
| Extension IDE cũ, CLI mới | Bắt tay fail, diff không hiện | Update cả 2 cùng lúc; `/ide disconnect` + connect lại |
| 2 IDE cùng workspace | Kênh lộn xộn (2 extension tranh 1 session) | 1 session — 1 IDE; session khác thì IDE khác |

### Tốn token?

- Metadata IDE (tên file, diagnostics) tốn ít. Đừng lo — tốn là ở code đọc vào, không phải ở kết nối.

### Version / provider

- VS Code: ổn định nhất. JetBrains: plugin riêng, update theo bản. Vim/Neovim: xem `/vim` (không phải `/ide`).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/ide` + `/cd` | Đổi package, IDE theo | Cd → IDE tự cập nhật workspace |
| `/ide` + `/review` | Review diff trực quan | Review rồi duyệt inline |
| `/ide` + `/teleport` | Về nhà gắn IDE nhà | Teleport → ide connect lại (kết nối không đi theo) |

Workflow chuẩn "sửa bug có IDE (10 phút)":

```bash
/ide connect
# → chọn file trong IDE, hỏi việc, duyệt diff inline, chạy test, disconnect khi xong
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `No IDE detected` | Chưa cài extension hoặc IDE mở folder khác | Cài extension; mở đúng folder; connect lại |
| Diff không hiện inline | Extension cũ hoặc file quá lớn | Update extension; file >1MB duyệt bằng text |
| Diagnostics không sang | Extension chưa quyền đọc problems panel | Bật trong settings extension; reload IDE |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../vim/README.md](../../auth-settings/vim/README.md) — chế độ vim trong terminal (không phải IDE)
  - [../keybindings/README.md](../../auth-settings/keybindings/README.md) — phím tắt terminal vs phím IDE
  - [../cd/README.md](../../auth-settings/cd/README.md) — đổi dir, IDE cập nhật theo
  - [../teleport/README.md](../../auth-settings/teleport/README.md) — sang máy mới phải connect lại
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md) — cài extension IDE
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../../02-cac-be-mat-terminal-ide-web-desktop.md) — IDE là 1 bề mặt chính thức
  - [../../10-permissions-modes-availability.md](../../../10-permissions-modes-availability.md) — workspace rộng thì phanh ở đâu

> Mẹo 1 dòng: _mở IDE rồi mà chưa `/ide connect` là bỏ phí nửa sức mạnh._
