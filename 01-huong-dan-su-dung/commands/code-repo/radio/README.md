# /radio — Kênh dev trực tiếp: hỏi-đáp nhanh, tính khả dụng hạn chế theo provider

> Loại Built-in (version-gated) · Nhóm Session/Realtime · Nguy hiểm Thấp (chủ yếu hỏi-đáp + nghe; nhưng Trung bình nếu bạn đọc secrets lên kênh công cộng)

> Nói nôm na: `/radio` mở kênh realtime với Claude trong session: hỏi nhanh bằng giọng/text, nghe giải thích, brainstorm mà không phá mạch code chính. Hiểu `/radio` là hiểu "đài nội bộ của session" — bật lên hỏi, tắt đi code tiếp, history chính vẫn sạch.

## Khi nào dùng

- Dùng /radio khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /radio **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /radio thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/radio`
`/radio status`
`/radio ask <câu hỏi>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Mạch chính đang sửa auth, không muốn chèn 30 dòng thảo luận:
/radio ask "refresh token nên xoay ở đâu: middleware hay API route?"
# → kênh radio trả lời trade-off 5 bullets, mạch chính vẫn gọn

/radio off
# → áp quyết định vào code ở kênh chính
```

Kết quả mong đợi:

- Claude trả đúng việc của /radio (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `unknown command: /radio` | Bản cũ hoặc provider không hỗ trợ | Update mới nhất; gõ `/` kiểm tra; vắng thì dùng `/btw` |
| Hỏi mà trả lời chung chung | Câu hỏi quá rộng ("giải thích cả repo") | Hẹp scope: 1 file/1 luồng/1 quyết định |
| Transcript voice sai từ khóa | Mic/tiếng ồn/thuật ngữ | Gõ lại từ khóa (tên file/hàm) bằng text |

## Tham khảo

- [../btw/README.md](../../code-repo/btw/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../plan/README.md](../../model-mode/plan/README.md)
- [../export/README.md](../../session-context/export/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /radio sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
