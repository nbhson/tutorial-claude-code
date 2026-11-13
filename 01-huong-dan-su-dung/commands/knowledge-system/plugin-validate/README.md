# /plugin-validate — Audit plugin/mod trước khi cài: nó xin hooks gì, gọi calls gì

> Loại CLI (`claude plugin validate`) · Nhóm Plugin & Bảo mật · Mức rủi ro Không (chỉ đọc + in báo cáo; nhưng Có nếu bạn bỏ qua red flags rồi cài — mod độc đọc file + gọi mạng + chạy shell cùng lúc là mất máy)
> **Nói nôm na:** `claude plugin validate <mod>` audit 1 plugin/mod TRƯỚC khi cài. Nó in ra `hooks:` mà plugin đăng ký (tool.check/tool.call/prompt.submit/session.append/ui.render) và `calls:` mà nó được phép gọi (`$.process.run/spawn`, `$.fs.read/write`, `$.http.fetch`, `$.env.get`, `$.settings.read`, `$.model.complete`, `$.prompt.submit`). Gặp red flags (đọc env + ghi file + gọi mạng + chạy shell cùng lúc, prompt.submit lén, ui.render giả mạo...) thì đọc code từng dòng trước khi quyết. Kèm `claude plugin test` để thử mod trong lồng (no-hooks module vs hooks-off). Hiểu `plugin-validate` là hiểu "soi giấy phép lái xe trước khi cho lên xe".

## Khi nào dùng

- Dùng trước khi cài bất kỳ plugin/mod lạ để đọc nó xin hooks gì và được gọi gì.
- Dùng **trước khi** tin: phát hiện red flags (env + fs.write + http + shell cùng lúc) trước khi lên máy.
- Không dùng thay đọc code: red flag nặng thì vẫn phải đọc từng dòng trước khi quyết.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Báo cáo liệt kê `hooks:` và `calls:`; red flags `NONE` là xanh.
- `claude plugin test --no-hooks` xác nhận lõi chạy độc lập.

**Kiểm tra nhanh:** chạy `validate` trên 1 mod đã biết lành để so baseline; xem dòng red flags.

> **Tóm gọn 1 câu:** `/plugin-validate` là soi giấy phép lái xe trước khi cho khách lên xe: hooks và calls nó xin gì đều in ra giấy — red flag nặng thì vẫn phải đọc code tay trước khi cài.

## Lỗi thường gặp

Bảng dưới là những báo cáo bạn có thể gặp khi validate — đối chiếu với cột "Triệu chứng" rồi làm theo "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `validate` báo mod không tồn tại | Sai tên (thiếu scope `@org/mod`) hoặc mod local sai path | Copy đúng tên marketplace; local thì đường dẫn tuyệt đối tới thư mục có manifest |
| `--strict` block mod team tự viết | Mod nội bộ xin rộng nhưng lành (tool.call(*) cho tiện) | Sửa mod hẹp lại (liệt kê tool cụ thể) rồi validate lại — strict đúng, mod sai |
| Test `--no-hooks` PASS nhưng cài vào lỗi | Lõi sạch nhưng hooks xung đột với mod khác (2 mod cùng tool.call Edit) | `/plugin list` tìm xung đột; disable 1 trong 2; báo author gộp |

> **Cách đọc bảng này:** mỗi dòng là một cảnh báo từ `validate`; đọc cột "Vì sao" để hiểu mod xin quyền gì, cột "Cách sửa" là bước xử lý cụ thể.

## Tham khảo

- [../plugin/README.md](../../knowledge-system/plugin/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../sandbox/README.md](../../auth-settings/sandbox/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _red flags "NONE" chưa đủ tự tin — vẫn mở code xem vài dòng runtime._
