# /clear — Xóa sạch lịch sử hội thoại, bắt đầu phiên mới trắng tinh

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file code, chỉ xóa conversation context trong bộ nhớ phiên hiện tại; không thể undo)

> Nói nôm na: `/clear` là nút "reset não" của Claude Code: xóa toàn bộ lịch sử hội thoại khỏi context window, giữ nguyên file trên đĩa, giữ nguyên CLAUDE.md / memory, và cho bạn một phiên trắng để bắt đầu task mới.

## Khi nào dùng

- Dùng /clear khi bạn muốn quản lý phiên/context (mở, dọn, lưu, chia nhánh) mà không đụng tới code trên đĩa.
- Dùng /clear **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /clear thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/clear`
`clear` _(gõ nhanh)_
`/clear` + prompt mới
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: đang ở cuối cuộc fix CSS
# (context ~45%, toàn chuyện padding, margin, flexbox)

# Bước 2: reset
/clear

# Bước 3: bắt đầu task mới sạch sẽ, nạp đúng tài liệu cần
Hãy đọc docs/payment-spec.md và triển khai POST /api/payments theo spec.
```

Kết quả mong đợi:

- Claude trả đúng việc của /clear (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/clear` xong model vẫn "nhớ" chuyện cũ | Nhớ từ `CLAUDE.md` / memory file, không phải từ conversation | Sửa `CLAUDE.md` / `~/.claude/CLAUDE.md`, không phải lỗi clear |
| Gõ `/clear` báo `unknown command` | Bản CLI quá cũ hoặc gõ trong `--print` non-interactive | Update `npm i -g @anthropic-ai/claude-code`, hoặc mỗi lần gọi CLI đã là session mới nên không cần clear |
| Clear xong `/resume` vẫn thấy đoạn cũ | Transcript `.jsonl` vẫn lưu, resume đọc từ đĩa | Đúng hành vi; muốn quên hẳn thì không resume session đó nữa, bắt session mới |

## Tham khảo

- [../compact/README.md](../../session-context/compact/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /clear sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
