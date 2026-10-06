# /plugin — Chợ ứng dụng của Claude: cài 1 lần được cả bộ skill + agent + MCP

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có (plugin chạy code trên máy bạn: hooks + MCP server của plugin có thể đọc file, gọi mạng — chỉ cài nguồn tin cậy)

> Nói nôm na: `/plugin` mở trình quản lý plugin (plugin manager): khám phá (Discover), duyệt (Browse) và quản lý (Manage) các gói mở rộng. Một plugin = bundle gồm `skills/` (quy trình), `agents/` (subagent chuyên), `hooks/` (tự động hoá), MCP config (tools mới) và `commands/` (slash command mới) — cài 1 lần là có cả bộ, khỏi lắp từng mảnh. Hiểu `/plugin` là hiểu "app store" của Claude Code.

## Khi nào dùng

- Dùng /plugin khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /plugin **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /plugin thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/plugin`
`/plugin discover`
`/plugin browse`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Cài cho cả team (ghi vào settings commit git)
/plugin install commit-commands
/plugin install pr-review-toolkit

# File .claude/settings.json:
```

Kết quả mong đợi:

- Claude trả đúng việc của /plugin (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Gõ lệnh plugin báo not found | Plugin disabled hoặc session cũ chưa nạp | `/plugin` Manage kiểm tra enabled; `/clear` nạp lại |
| `/review` hiện picker mỗi lần | 2 plugin cùng tên lệnh | Gọi đầy đủ `pluginA:review`; hoặc gỡ 1 plugin |
| Install báo marketplace not found | Sai tên marketplace hoặc mạng chặn | Kiểm tra `marketplaces:` trong settings; thử `gh:owner/repo` trực tiếp |

## Tham khảo

- [../hooks/README.md](../../knowledge-system/hooks/README.md)
- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /plugin sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
