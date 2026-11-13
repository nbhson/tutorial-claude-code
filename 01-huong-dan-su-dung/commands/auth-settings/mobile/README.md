# /mobile — Pair điện thoại: quét QR, điều khiển session từ xa, persist cross-device

> Loại Built-in · Nhóm Remote · Mức rủi ro Có nhẹ (điện thoại thành remote full-quyền của session — mất điện thoại = mất điều khiển; nhưng Không chuyển nơi chạy, code vẫn ở máy cũ)
> **Nói nôm na:** `/mobile` ghép điện thoại với session đang chạy trên desktop: hiện QR, quét bằng app là điện thoại thành "điều khiển từ xa" — xem log, gõ prompt, duyệt permission (`Yes/No`) từ quán cà phê. Execution vẫn ở máy desktop (khác `/teleport` là bê cả session đi). Hiểu `/mobile` là hiểu "cầm remote TV ra sân" — TV vẫn trong nhà, bạn chỉ mang remote đi.

## Khi nào dùng

- Dùng khi bạn phải rời bàn giữa task mà vẫn muốn xem log, gõ prompt, duyệt `Yes/No` từ điện thoại.
- Dùng **trước khi** rời nhà giữa task chạy dài (test 45 phút, migrate): pair từ trước, ra ngoài chỉ còn bấm duyệt.
- Không dùng `/mobile` thay cho việc tự đọc kỹ lệnh: bấm `Yes` từ xa mà không đọc vẫn nguy hiểm như bấm ở máy.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- QR hiện ra; quét xong terminal báo `Paired: <device> ✓`.
- Điện thoại nhận được prompt lẫn permission prompt (`Yes/No`) từ session desktop.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Quét QR báo `expired` | Pairing token TTL 5-10 phút, để lâu quá | `/mobile --qr` sinh mới rồi quét ngay |
| Quét QR báo `account mismatch` | App login mail khác với desktop | Đăng xuất app, login đúng mail desktop rồi quét lại |
| App hiện `host offline` | Desktop sleep/mất mạng/tắt | Bật desktop, tắt sleep (`caffeinate` macOS); desktop tắt là remote chịu |

> **Cách đọc bảng này:** cột "Triệu chứng" là thông báo trên app hoặc terminal, "Vì sao" giải thích pairing hoạt động kiểu gì, "Cách sửa" là việc làm ngay — pair thất bại hay remote im lặng đều tra được ở đây.

> **Tóm gọn 1 câu:** `/mobile` là cầm remote TV ra sân — bạn điều khiển từ xa được, nhưng "cái TV" (session, code) vẫn chạy ở desktop, và bấm Yes từ xa cũng phải đọc kỹ như ngồi trước màn hình.

## Tham khảo

- [../teleport/README.md](../../auth-settings/teleport/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../remote-env/README.md](../../auth-settings/remote-env/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /mobile sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
