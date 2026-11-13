# /background — Đẩy session đang chạy thành agent nền, rảnh tay làm việc khác

> **Loại:** Built-in · **Nhóm:** Session & Song song · **Mức rủi ro:** Thấp (chạy nền vẫn dùng quyền session hiện tại; nhưng "Có" nếu task nền ghi file/xóa/migrate mà bạn quên đang có nó chạy)
> **Nói nôm na:** `/background` detach session hiện tại thành một background agent: nó tự làm tiếp (code, test, research...), bạn rảnh terminal làm việc khác hoặc mở session mới. Muốn dừng: `Ctrl+X Ctrl+K` bấm 2 lần (kill background agent). Hiểu `/background` là hiểu "giao việc cho đàn em làm ở phòng bên, mình đi họp".

## Khi nào dùng

- Dùng `/background` khi task đang chạy lâu (đọc nhiều file, test dài) mà bạn không cần ngồi nhìn.
- Dùng `/background` để rảnh terminal mở session mới làm việc khác song song.
- Không dùng `/background` cho task ghi file/xóa/migrate mà bạn không theo dõi — nền vẫn dùng quyền session hiện tại.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Session hiện tại được detach thành agent nền: terminal trả lại cho bạn, agent vẫn chạy tiếp task.
- `/tasks` thấy agent ở trạng thái `running`; xong thì báo kết quả (report/log) trong phiên nền.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

> **Tóm gọn 1 câu:** `/background` là giao việc cho đàn em làm ở phòng bên: bạn rảnh tay đi họp, nhưng vẫn phải ghé phòng (`/tasks`) kiểm tra — đàn em dùng chung chìa khóa quyền của bạn nên đừng giao việc phá nhà.

## Lỗi thường gặp

Bảng dưới là những lần "giao việc hụt" hay gặp — đối chiếu triệu chứng với cột đầu rồi xử theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/background` xong terminal vẫn bận | Detach fail (tool đang chạy dở 1 lệnh dài) | Chờ lệnh hiện tại xong hẳn rồi `/background` lại |
| `Ctrl+X Ctrl+K` không kill | Bấm 1 lần (mới là hỏi), hoặc focus không ở terminal (đang ở IDE pane) | Bấm đủ 2 lần, focus đúng terminal; `/tasks` xác nhận stopped |
| `/tasks` không thấy agent vừa detach | Session ID chưa sync (detach ngay khi mạng lag) | Đợi 5s `/tasks` lại; không thấy nữa thì `/resume` mới nhất |

> **Cách đọc bảng này:** mỗi dòng là một hiện tượng sau khi detach; cột "Vì sao" cho biết chậm ở đâu (tool đang chạy, phím bấm, mạng), cột "Cách sửa" là thao tác xử lý theo đúng thứ tự.

## Tham khảo

- [../tasks/README.md](../../session-context/tasks/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _task đọc nhiều file hoặc test dài thì `/background` ngay từ đầu để rảnh tay, đừng ngồi nhìn tiến trình._
