# /radio — kênh dev trực tiếp: hỏi-đáp nhanh, tính khả dụng hạn chế theo provider

> Loại Built-in (version-gated) · Nhóm Session/Realtime · Mức rủi ro Thấp
> **Nói nôm na:** `/radio` mở kênh realtime với Claude trong session: hỏi nhanh, nghe giải thích, brainstorm mà không phá mạch code chính. History chính vẫn sạch.

## Khi nào dùng

- Dùng `/radio` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/radio` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/radio` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/radio`
`/radio status`
`/radio ask <câu hỏi>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/radio ask "refresh token nên xoay ở đâu: middleware hay API route?"
# → trả lời trade-off 5 bullets, mạch chính vẫn gọn
/radio off
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/radio` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `unknown command: /radio` | Bản cũ hoặc provider không hỗ trợ | Update mới nhất; gõ `/` kiểm tra; vắng thì dùng `/btw` |
| Hỏi mà trả lời chung chung | Câu hỏi quá rộng | Hẹp scope: 1 file/1 luồng/1 quyết định |
| Transcript voice sai từ khóa | Mic/tiếng ồn | Gõ lại từ khóa (tên file/hàm) bằng text |

## Tham khảo

- [../btw/README.md](../../code-repo/btw/README.md)
- [../../session-context/fork/README.md](../../session-context/fork/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)
- [../../session-context/export/README.md](../../session-context/export/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/radio` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
