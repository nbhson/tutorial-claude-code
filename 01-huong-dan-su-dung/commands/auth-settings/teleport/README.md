# /teleport — Chuyển session đang chạy giữa terminal local và cloud (hoặc máy ↔ máy)

> Loại Built-in · Nhóm Remote · Mức rủi ro Có nhẹ (session + file context di chuyển qua mạng — mạng lạ/VPN công ty có thể nhìn thấy metadata; nhưng Không mất code nếu làm đúng)
> **Nói nôm na:** `/teleport` "dịch chuyển tức thời" session đang chạy: đang làm trên terminal công ty, teleport sang cloud (hoặc sang laptop ở nhà) là tiếp tục đúng chỗ — history, todos, file đang sửa đi theo. Hiểu `/teleport` là hiểu "bê cả bàn làm việc sang phòng khác" — khác `/mobile` (điều khiển từ điện thoại) và `/remote-env` (cấu hình môi trường remote).

## Khi nào dùng

- Dùng khi muốn mang session đang chạy đi chỗ khác: terminal công ty → cloud → laptop nhà, tiếp tục đúng chỗ đang dở.
- Dùng **trước khi** rời máy/close máy giữa task: commit checkpoint rồi `/teleport cloud` sớm, về nhà `/teleport local` kéo về là tiếp.
- Không dùng `/teleport` thay cho việc tự commit checkpoint — mạng đứt giữa chừng mà chưa commit thì vẫn mất công.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Session chạy tiếp ở đích; terminal báo link (cloud) hoặc kết quả pull (local).
- History, todos, file đang sửa đi theo; code vẫn an toàn trong git.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các sự cố hay gặp khi dời session giữa các máy — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/teleport cloud` treo ở `Uploading...` | Diff quá lớn (node_modules/build lọt vào) hoặc mạng yếu | `git status` xem diff; thêm `.gitignore` đúng; commit bớt rồi teleport lại; thử region gần hơn |
| Kéo về báo `conflict: 3 files` | Cả 2 bên cùng sửa lúc xa nhau | Đọc diff từng file (`git diff`), chọn tay; đừng `--force` mù |
| `--list` thấy device `(offline)` | Máy kia sleep/tắt/mất mạng | Bật máy kia hoặc đi vòng qua cloud relay |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là thông báo bạn thấy lúc teleport, "Vì sao" chỉ nguyên nhân (diff to, mạng, máy tắt), "Cách sửa" là bước xử lý tương ứng.

> **Tóm gọn 1 câu:** `/teleport` là bê nguyên bàn làm việc sang phòng khác — commit checkpoint trước thì đến đâu làm tiếp đến đó, không mất công dở dang.

## Tham khảo

- [../mobile/README.md](../../auth-settings/mobile/README.md)
- [../remote-env/README.md](../../auth-settings/remote-env/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /teleport sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
