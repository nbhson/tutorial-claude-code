# /fork — Tách conversation hiện tại thành nhánh mới, giữ bản gốc nguyên vẹn

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file; chỉ copy context sang session mới — bản gốc giữ nguyên)

> Nói nôm na: `/fork` là "rẽ nhánh không sợ hỏng": copy toàn bộ (hoặc 1 phần) context hiện tại sang 1 conversation mới để thử hướng khác, trong khi bản gốc vẫn an toàn.

## Khi nào dùng

- Dùng /fork khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /fork **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /fork thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/fork`
`/fork <hướng-thử>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bản gốc đang làm Postgres queue, muốn thử Redis queue mà sợ hỏng
/fork Thử lại bằng Redis queue, so sánh latency. Giữ nguyên API ở src/queue/.
# → nhánh mới tự do đập phá, bản gốc vẫn còn nếu Redis thua
```

Kết quả mong đợi:

- Claude trả đúng việc của /fork (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Fork xong 2 nhánh sửa cùng file loạn | Chung filesystem, không cách ly file | Dùng `git worktree` / `git branch` riêng cho mỗi hướng |
| Fork từ session 80% RAM, nhánh mới đã đầy | Copy nguyên history nặng | `/compact` trước khi fork, hoặc fork sớm hơn |
| Không biết đang ở nhánh nào | Quên rename sau fork | `/rename` ngay sau fork; kiểm tra picker `/resume` |

## Tham khảo

- [../branch/README.md](../../session-context/branch/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../rename/README.md](../../session-context/rename/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /fork sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
