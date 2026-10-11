# /vim — Chế độ vim: normal/insert, hjkl, soạn prompt như soạn code

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ đổi cách soạn phím — nhưng Có nhẹ nếu normal-mode bấm nhầm `shift+y` duyệt permission lúc đang tưởng mình soạn text)
> **Nói nôm na:** `/vim` bật/tắt chế độ soạn kiểu vim trong khung nhập: `Esc` về normal (`hjkl` di chuyển, `w/b` nhảy từ, `dd` xoá dòng), `i/a/o` vào insert gõ tiếp. Hiểu `/vim` là hiểu "khung chat cũng là buffer vim" — tay vim khỏi rời home row.

## Khi nào dùng

- Dùng khi bạn quen vim và muốn soạn prompt như soạn code: `Esc` về normal, `hjkl` di chuyển, `w/b` nhảy từ, `dd` xoá dòng.
- Dùng **trước khi** soạn prompt dài (spec, prompt nhiều dòng, mô tả refactor): bật `/vim on` từ đầu, sửa nhanh bằng lệnh vim thay vì phím mũi tên.
- Không dùng `/vim` thay cho việc tự nhớ chế độ đang ở: quên `Esc` mà bấm phím normal vẫn có thể duyệt nhầm permission.

## Cách gọi

```bash
/vim
/vim on
/vim off
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/vim on
# Gõ spec 20 dòng (insert) → Esc → /auth → nhảy tới chỗ cần sửa
# → cw sửa từ, yy p nhân bản đoạn, i gõ tiếp, Enter gửi
# → prompt dài mà sửa nhanh như sửa code
```

Kết quả mong đợi:

- Khung nhập sang kiểu vim: `Esc` về normal, `hjkl`/`w/b`/`dd` hoạt động.
- `i/a/o` vào insert gõ tiếp; Enter mới gửi prompt.

**Kiểm tra nhanh:**

```bash
/vim --status
# → báo vim mode đang ON/OFF đúng như ý bạn
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `Esc` không về normal | Terminal/tmux ăn Esc | Fix terminal-setup; dùng `Ctrl+[` tạm |
| `hjkl` gõ ra chữ thay vì di chuyển | Đang insert (chưa Esc) hoặc vim off | `Esc` trước; `/vim --status` kiểm tra |
| `dd` tưởng xoá file | Hiểu nhầm scope — chỉ xoá dòng prompt | Yên tâm, nhưng đọc lại mục cơ chế để chắc |

## Tham khảo

- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../ide/README.md](../../auth-settings/ide/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /vim sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
