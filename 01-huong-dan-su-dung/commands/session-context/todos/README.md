# /todos — Xem và quản lý danh sách việc cần làm của session hiện tại

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (chỉ đọc/ghi todo list trong memory session, không xóa/sửa code)
> **Nói nôm na:** `/todos` là "bảng việc dán tường": liệt kê các đầu việc model đang theo (pending/in-progress/done), để bạn kiểm tra tiến độ, bổ sung, hoặc chốt trước khi compact/clear/bàn giao.

## Khi nào dùng

- Dùng `/todos` khi bạn muốn xem model đang theo những đầu việc nào (pending/in-progress/done).
- Dùng `/todos` **trước khi** compact/clear/bàn giao để không mất danh sách việc đang dở.
- Không dùng `/todos` như bằng chứng hoàn thành — tick `done` phải kèm verify, không tin kế hoạch suông.

## Cách gọi

```bash
`/todos`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).
> `TodoWrite`/`TaskCreate` bị gỡ khỏi Opus 4.8 / Sonnet 5 / Fable 5 (w33/2026), bật lại bằng `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Đang migration billing 5 bước, muốn biết tới đâu
/todos
# → 1.done 2.done 3.doing 4.pending 5.pending
# → nhắn: "Làm tiếp bước 3, xong báo tôi."
```

Kết quả mong đợi:

- Claude trả đúng việc của /todos (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/todos` trống dù task dài | Model chưa tạo todos (task ít bước hoặc prompt chung) | Dặn: "Tạo todo list 5 bước cho task này" |
| Todos mất sau compact/clear | Gắn với conversation đã nén/xóa | Tạo lại tay; lần sau nêu "giữ todo list" trong focus compact, export trước clear |
| Model tick done nhưng code chưa xong | Tick theo kế hoạch, không verify | Bắt verify: "Mỗi todo done phải kèm lệnh test đã chạy + kết quả" |

## Tham khảo

- [../tasks/README.md](../../session-context/tasks/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /todos sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
