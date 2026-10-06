# /memory — Quản lý bộ nhớ dài hạn: xem/sửa/xoá những gì Claude nhớ giữa các session

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (nhưng Có nếu lưu secret/API key vào memory — sẽ bị nạp lại mọi session sau)

> Nói nôm na: `/memory` mở trình quản lý bộ nhớ dài hạn (long-term memory): những sự thật, sở thích, quy ước dự án mà Claude tự ghi nhớ hoặc bạn dạy thủ công, để session sau tự động nạp lại mà không cần nhắc lại. Hiểu `/memory` là hiểu "não dài hạn" của Claude Code — khác với CLAUDE.md (file tĩnh trong repo) và khác context ngắn hạn (mất khi `/clear`).

## Khi nào dùng

- Dùng /memory khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /memory **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /memory thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/memory`
`/memory show`
`/memory add <nội dung>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/memory add Trả lời bằng tiếng Việt. Code trước, giải thích sau, ngắn gọn. Commit message kiểu conventional commits, không emoji.
/memory add Tôi dùng macOS + zsh. Khi gợi ý lệnh shell, dùng cú pháp macOS.
```

Kết quả mong đợi:

- Claude trả đúng việc của /memory (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Dạy rồi mà session sau model quên | Lưu vào project memory repo A, đang mở repo B | Kiểm tra scope: chuyển mục đó sang user memory để theo mọi repo |
| Model cứ hỏi "có lưu không?" gây phiền | Auto-memory nhạy quá | Tắt đề xuất trong settings, chỉ thêm tay bằng `/memory add` |
| `/memory` báo empty dù đã dạy | Dạy trong session chưa duyệt Yes, hoặc nhầm profile `~/.claude` | Mở lại `/memory`, kiểm tra; đảm bảo đã bấm Yes khi model hỏi |

## Tham khảo

- [../rules/README.md](../../knowledge-system/rules/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /memory sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
