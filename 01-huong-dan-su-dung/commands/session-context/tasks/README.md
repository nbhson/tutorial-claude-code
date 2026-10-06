# /tasks — Quản lý background jobs đang chạy ngầm (alias /bashes)

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ liệt kê/theo dõi jobs; kill job có thể dừng việc đang chạy — không xóa code)

> Nói nôm na: `/tasks` (alias `/bashes`) là "trình quản lý tác vụ nền": xem jobs nào đang chạy (test suite, dev server, agent Explore dài), kiểm tra output, hoặc dừng job kẹt.

## Khi nào dùng

- Dùng /tasks khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /tasks **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /tasks thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/tasks`
`/bashes`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bảo chạy test nặng nền
Hãy chạy npm test ở background, tôi làm docs trong lúc chờ.

# 5 phút sau kiểm tra
/tasks
# → npm test: running (5:00), dev server: running
# → làm tiếp docs, 5 phút nữa check lại
```

Kết quả mong đợi:

- Claude trả đúng việc của /tasks (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/tasks` trống dù vừa chạy lệnh | Lệnh chạy foreground xong nhanh, không thành job nền | Đúng hành vi; chỉ lệnh lâu mới thành background job |
| Job running mãi không xong | Kẹt watch mode / chờ input / test treo | Kill rồi chạy lại với flags non-interactive (`--watchAll=false`, `--reporter=min`) |
| Kill nhầm dev server | Kill theo tên chung chung | Ghi rõ id: "kill job <id> test, giữ dev server" |

## Tham khảo

- [../todos/README.md](../../session-context/todos/README.md)
- [../usage/README.md](../../session-context/usage/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../export/README.md](../../session-context/export/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /tasks sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
