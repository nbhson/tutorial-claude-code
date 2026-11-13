# /ide — Gắn Claude Code vào IDE: VS Code, JetBrains, diff inline, jump-to-file

> Loại Built-in · Nhóm Remote · Mức rủi ro Không (chỉ kết nối editor — nhưng Có nhẹ nếu IDE mở folder nhạy cảm mà Claude được đọc toàn workspace)
> **Nói nôm na:** `/ide` kết nối session terminal với IDE đang mở: Claude đọc file bạn đang xem, hiện diff inline để duyệt, `jump-to-file` từ lỗi sang đúng dòng, chạy test rồi hiện kết quả trong editor. Hiểu `/ide` là hiểu "mời Claude ngồi cùng bàn IDE" — não vẫn ở terminal, mắt thêm ở editor.

## Khi nào dùng

- Dùng khi bạn muốn Claude thấy đúng file + selection đang mở trong IDE, duyệt diff inline và jump-to-file từ lỗi sang đúng dòng.
- Dùng **trước khi** vào giai đoạn sửa/review nhiều file (đầu task gỡ bug, trước khi review diff dài) — kết nối `/ide` sớm để duyệt từng hunk inline.
- Không dùng `/ide` thay cho việc tự duyệt từng hunk — bạn vẫn là người bấm Accept/Reject.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Terminal báo đã kết nối IDE; Claude đọc được file + selection đang mở.
- Diff hiện inline trong editor để bạn duyệt từng hunk.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `No IDE detected` | Chưa cài extension hoặc IDE mở folder khác | Cài extension; mở đúng folder; connect lại |
| Diff không hiện inline | Extension cũ hoặc file quá lớn | Update extension; file >1MB duyệt bằng text |
| Diagnostics không sang | Extension chưa quyền đọc problems panel | Bật trong settings extension; reload IDE |

> **Cách đọc bảng này:** cột "Triệu chứng" là báo lỗi trên màn hình, "Vì sao" nêu nguyên nhân phía extension, "Cách sửa" là việc làm trong IDE hoặc CLI — tra đúng hàng đang gặp.

> **Tóm gọn 1 câu:** `/ide` mời Claude ngồi cùng bàn editor — mắt thêm ở IDE, não vẫn ở terminal, còn nút Accept/Reject vẫn trong tay bạn.

## Tham khảo

- [../vim/README.md](../../auth-settings/vim/README.md)
- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../cd/README.md](../../auth-settings/cd/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /ide sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
