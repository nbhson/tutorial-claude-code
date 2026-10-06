# /compact — Nén lịch sử hội thoại thành tóm tắt, giữ đà task mà nhẹ context

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file code; chỉ thay conversation dài bằng bản tóm tắt — chi tiết gốc không khôi phục trong phiên)

> Nói nôm na: `/compact` là "nén RAM có chọn lọc": thay vì xóa trắng như `/clear`, nó tóm tắt toàn bộ hội thoại thành 1 bản summary gọn rồi tiếp tục task từ đó. Dùng khi context đầy nhưng bạn vẫn đang làm dở cùng 1 task.

## Khi nào dùng

- Dùng /compact khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /compact **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /compact thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/compact`
`/compact <focus>`
Auto-compact
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: kiểm tra
/context
# → usage 72%, phần lớn là log test cũ

# Bước 2: compact có focus
/compact Giữ lại: mục tiêu chuyển sang JWT rotation, 8 file đã sửa trong src/auth/, quyết định dùng refresh-token 7 ngày, bước tiếp theo là fix 2 test fail ở auth.test.ts.

# Bước 3: tiếp tục ngay, không cần đọc lại file
```

Kết quả mong đợi:

- Claude trả đúng việc của /compact (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Compact xong model quên tên file quan trọng | Focus quá chung chung ("tóm tắt giúp tôi") | Compact lại không cứu được (history đã mất); lần sau focus nêu tên file cụ thể. Trước mắt bảo model đọc lại file / `glob` tìm lại |
| Compact xong todos biến mất | Summary bỏ qua todos | Gõ `/todos` kiểm tra, tạo lại tay; lần sau focus ghi "giữ nguyên todo list" |
| Auto-compact tự chạy giữa chừng, summary xấu | Chạm ngưỡng ~80% mà không compact tay trước | Chủ động `/compact <focus>` ở ~60%; vào settings chỉnh ngưỡng nếu bản bạn cho phép |

## Tham khảo

- [../clear/README.md](../../session-context/clear/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../todos/README.md](../../session-context/todos/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /compact sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
