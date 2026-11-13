# /tasks — Quản lý background jobs đang chạy ngầm (alias /bashes)

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (chỉ liệt kê/theo dõi jobs; kill job có thể dừng việc đang chạy — không xóa code)
> **Nói nôm na:** `/tasks` (alias `/bashes`) là "trình quản lý tác vụ nền": xem jobs nào đang chạy (test suite, dev server, agent Explore dài), kiểm tra output, hoặc dừng job kẹt. Giống bảng đèn ở bếp nhà hàng: món nào đang lên, món nào chờ, nhìn một cái biết.

## Khi nào dùng

- Dùng `/tasks` (alias `/bashes`) khi muốn xem job nền nào đang chạy (test suite, dev server, agent Explore dài).
- Dùng `/tasks` để kiểm tra output hoặc dừng một job đang kẹt/watch mode.
- Không dùng `/tasks` như lịch sử lệnh — chỉ lệnh chạy nền lâu mới xuất hiện ở đây.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Danh sách job nền kèm trạng thái (running/done) và thời gian đã chạy.
- Kiểm tra output hoặc kill job kẹt ngay trong session.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/tasks` trống dù vừa chạy lệnh | Lệnh chạy foreground xong nhanh, không thành job nền | Đúng hành vi; chỉ lệnh lâu mới thành background job |
| Job running mãi không xong | Kẹt watch mode / chờ input / test treo | Kill rồi chạy lại với flags non-interactive (`--watchAll=false`, `--reporter=min`) |
| Kill nhầm dev server | Kill theo tên chung chung | Ghi rõ id: "kill job <id> test, giữ dev server" |

> **Cách đọc bảng này:** cột **Triệu chứng** là chuyện xảy ra với job nền, **Vì sao** cho biết đó là hành vi đúng hay job kẹt, **Cách sửa** là cách chạy lại hoặc kill chính xác.

## Tham khảo

- [../todos/README.md](../../session-context/todos/README.md)
- [../usage/README.md](../../session-context/usage/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../export/README.md](../../session-context/export/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _job nền nên chạy non-interactive để đỡ kẹt — test với `--watchAll=false` / `--reporter=min`._

> **Tóm gọn 1 câu:** `/tasks` là khu quan sát tầng hầm: job nào đang chạy ngầm, job nào kẹt thì dừng đúng id.
