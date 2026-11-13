# /compact — Nén lịch sử hội thoại thành tóm tắt, giữ đà task mà nhẹ context

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (không xóa/sửa file code; chỉ thay conversation dài bằng bản tóm tắt — chi tiết gốc không khôi phục trong phiên)
> **Nói nôm na:** `/compact` là "nén RAM có chọn lọc": thay vì xóa trắng như `/clear`, nó tóm tắt toàn bộ hội thoại thành 1 bản summary gọn rồi tiếp tục task từ đó. Dùng khi context đầy nhưng bạn vẫn đang làm dở cùng 1 task.

## Khi nào dùng

- Dùng `/compact` khi context đầy nhưng bạn vẫn đang làm dở cùng một task và muốn giữ mạch làm việc.
- Dùng `/compact <focus>` chủ động ở ~60% thay vì đợi auto-compact giữa chừng cho summary đẹp hơn.
- Không dùng `/compact` thay cho `/clear` khi đổi hẳn việc khác — nén lại vẫn mang theo rác của task cũ.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).
> Từ ≥2.1.296, subagent có `autoCompactWindow` để tự compact sớm hơn cửa sổ chính — hữu ích khi bạn giao việc phụ dài.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Hội thoại dài được thay bằng một bản tóm tắt gọn; task tiếp tục từ đó, không cần đọc lại file.
- Chi tiết gốc (log, đoạn đã nén) không khôi phục được trong phiên.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Compact xong model quên tên file quan trọng | Focus quá chung chung ("tóm tắt giúp tôi") | Compact lại không cứu được (history đã mất); lần sau focus nêu tên file cụ thể. Trước mắt bảo model đọc lại file / `glob` tìm lại |
| Compact xong todos biến mất | Summary bỏ qua todos | Gõ `/todos` kiểm tra, tạo lại tay; lần sau focus ghi "giữ nguyên todo list" |
| Auto-compact tự chạy giữa chừng, summary xấu | Chạm ngưỡng ~80% mà không compact tay trước | Chủ động `/compact <focus>` ở ~60%; vào settings chỉnh ngưỡng nếu bản bạn cho phép |

> **Cách đọc bảng này:** cột **Triệu chứng** là chuyện xảy ra sau khi compact, **Vì sao** thường là lỗi của focus (nội dung dặn khi nén), **Cách sửa** nêu cả cách cứu trước mắt lẫn phòng lần sau.

## Tham khảo

- [../clear/README.md](../../session-context/clear/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../todos/README.md](../../session-context/todos/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chủ động `/compact <focus>` ở ~60% (nêu rõ file + quyết định cần giữ), đừng đợi auto-compact ở ~80% cho summary xấu._

> **Tóm gọn 1 câu:** `/compact` gấp cả cuốn hội thoại dày thành một trang ghi chú rồi chạy tiếp từ đó — nhanh, nhưng chi tiết bị gấp mất là không mở lại được.
