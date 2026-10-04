# /theme — Đổi giao diện: sáng/tối, tương phản cao, mù màu

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ đổi màu — không đụng code, auth, hay permissions)

`/theme` đổi bảng màu CLI: tối (mặc định), sáng (ra nắng), tương phản cao (mắt kém), thân thiện mù màu. Hiểu `/theme` là hiểu "đổi áo" — mặc gì thì làm việc vẫn thế, nhưng nhìn lâu đỡ mỏi.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/theme` | _(không có)_ | Mở picker chọn theme (xem trước trực tiếp) |
| `/theme <tên>` | dark, light, high-contrast, colorblind | Đặt thẳng không cần picker |
| `/theme --list` | flag | Liệt kê theme khả dụng |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: chọn bằng mắt
/theme
# → picker: Dark (current) · Light · High Contrast · Deuteranopia-safe...
```

```bash
# Dạng 2: ra quán nắng, chữ chìm — đổi nhanh
/theme light
```

```bash
# Dạng 3: xem có những áo nào
/theme --list
```

---

## Cách nó hoạt động

### Cơ chế sâu: theme đổi gì dưới đĩa?

1. **Chỉ đổi mã màu render:** theme là file bảng màu (`~/.claude/themes/` hoặc trong settings `theme: "dark"`). Đổi theme = đổi mã ANSI cho diff xanh/đỏ, prompt, border — logic giữ nguyên.
2. **Áp ngay, nhớ mãi:** đổi xong session hiện tại render lại luôn; lựa chọn lưu local scope nên session sau vẫn giữ. Muốn theo từng máy (công ty tối, nhà sáng) thì để local, đừng commit.
3. **High-contrast / colorblind:** không chỉ "đẹp" — diff pass/fail dùng thêm ký tự (`+`/`-`, đậm/nhạt) chứ không chỉ màu, nên mù màu vẫn phân biệt được.
4. **Terminal hỗ trợ kém (16 màu)?** CLI tự hạ cấp: màu xấp xỉ + thêm ký tự phân biệt. Theme đẹp nhất trên terminal truecolor (xem `/terminal-setup`).

### Khác gì với lệnh dễ nhầm?

| Lệnh | Đổi gì? | Dùng khi nào? |
|---|---|---|
| `/theme` | Màu CLI | Mỏi mắt, đổi môi trường sáng |
| `/terminal-setup` | Cấu hình terminal (font, Shift+Enter...) | Phím/lỗi hiển thị |
| `/statusline` | Dòng thông tin tùy biến | Muốn taplo gọn |

> Quy tắc ngón tay cái:
>
> - **Nhìn không rõ → `/theme`. Bấm không ăn → `/terminal-setup` + `/keybindings`.**

---

## Ví dụ thực tế

### Kịch bản 1: Demo ngoài nắng, diff chìm nghỉm

```bash
# Đang theme dark, ra sân demo với khách, màn hình lóa:
/theme light
# → diff đọc được ngay, demo tiếp không mất mặt
# Về văn phòng: /theme dark (1 giây)
```

### Kịch bản 2: Đồng nghiệp mù màu đỏ-lục không duyệt được diff

```bash
/theme
# → chọn Deuteranopia-safe (diff dùng xanh/cam + ký tự +/-)
# → duyệt pass/fail không cần nhờ người khác nhìn hộ
```

---

## Rủi ro & lưu ý

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Tưởng diff sai vì màu lạ | Chỉ là theme (xanh/cam thay vì xanh/đỏ) | Đọc ký tự `+`/`-`, đừng đọc màu |
| Theme light chụp màn hình share | Nền sáng lộ nội dung rõ hơn khi share | Che secret trước khi share ảnh (mọi theme đều thế) |

### Tốn token?

- Không. Theme là render local thuần.

### Version / provider

- Mọi bản đều có dark/light. High-contrast + colorblind-safe: v2.x.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/theme` + `/terminal-setup` | Setup máy mới | Terminal truecolor → theme đẹp |
| `/theme` + `/statusline` | Taplo dễ đọc | Theme tương phản + statusline gọn |

Workflow chuẩn "setup nhìn cho sướng (2 phút)": `/terminal-setup` → `/theme` → `/statusline`.

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Đổi theme mà màu không đổi | Terminal ép 16 màu hoặc `NO_COLOR` set | Kiểm tra terminal truecolor; `unset NO_COLOR` |
| Picker theme trống | Themes dir bị xoá | Reinstall CLI hoặc copy themes từ máy khác |
| Theme không nhớ sau restart | Sửa file tay sai scope | Đổi bằng `/theme` (lưu local đúng chỗ) thay vì sửa tay |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../terminal-setup/README.md](../terminal-setup/README.md) — terminal truecolor + Shift+Enter
  - [../statusline/README.md](../statusline/README.md) — dòng trạng thái tuỳ biến
  - [../keybindings/README.md](../keybindings/README.md) — phím tắt (không liên quan màu)
- Bài tổng quan:
  - [../../01-cai-dat-va-xac-thuc.md](../../01-cai-dat-va-xac-thuc.md) — setup lần đầu
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — hiển thị mỗi bề mặt
  - [../../10-permissions-modes-availability.md](../../10-permissions-modes-availability.md) — (không liên quan trực tiếp, đọc khi rảnh)

> Mẹo 1 dòng: _mỏi mắt là năng suất tụt — đừng chịu đựng theme sai, đổi mất 1 giây._
