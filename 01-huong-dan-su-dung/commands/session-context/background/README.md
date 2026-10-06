# /background — Đẩy session đang chạy thành agent nền, rảnh tay làm việc khác

> Loại Built-in · Nhóm Session & Song song · Nguy hiểm Thấp (chạy nền vẫn dùng quyền session hiện tại; nhưng Có nếu task nền ghi file/xóa/migrate mà bạn quên đang có nó chạy)

> Nói nôm na: `/background` detach session hiện tại thành một background agent: nó tự làm tiếp (code, test, research...), bạn rảnh terminal làm việc khác hoặc mở session mới. Muốn dừng: `Ctrl+X Ctrl+K` bấm 2 lần (kill background agent). Hiểu `/background` là hiểu "giao việc cho đàn em làm ở phòng bên, mình đi họp".

## Khi nào dùng

- Dùng /background khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /background **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /background thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/background`
`/tasks`
`Ctrl+X Ctrl+K ×2`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bạn: "đọc 10 file src/auth, tìm mọi chỗ verify JWT, báo cáo file:dòng"
# → việc đọc lâu, không cần nhìn nó đọc:
/background
# → "Detached as a3f9. Terminal free."

# Bạn mở session mới review PR đồng nghiệp (10 phút)...
# /tasks → "a3f9 running (7/10)"
# ...5 phút nữa: "a3f9 done — report ready"
```

Kết quả mong đợi:

- Claude trả đúng việc của /background (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/background` xong terminal vẫn bận | Detach fail (tool đang chạy dở 1 lệnh dài) | Chờ lệnh hiện tại xong hẳn rồi `/background` lại |
| `Ctrl+X Ctrl+K` không kill | Bấm 1 lần (mới là hỏi), hoặc focus không ở terminal (đang ở IDE pane) | Bấm đủ 2 lần, focus đúng terminal; `/tasks` xác nhận stopped |
| `/tasks` không thấy agent vừa detach | Session ID chưa sync (detach ngay khi mạng lag) | Đợi 5s `/tasks` lại; không thấy nữa thì `/resume` mới nhất |

## Tham khảo

- [../tasks/README.md](../../session-context/tasks/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /background sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
