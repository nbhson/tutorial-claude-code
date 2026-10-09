# /plugin — Chợ ứng dụng của Claude: cài 1 lần được cả bộ skill + agent + MCP

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Có (plugin chạy code trên máy bạn: hooks + MCP server của plugin có thể đọc file, gọi mạng — chỉ cài nguồn tin cậy)
> **Nói nôm na:** `/plugin` mở trình quản lý plugin (plugin manager): khám phá (Discover), duyệt (Browse) và quản lý (Manage) các gói mở rộng. Một plugin = bundle gồm `skills/` (quy trình), `agents/` (subagent chuyên), `hooks/` (tự động hoá), MCP config (tools mới) và `commands/` (slash command mới) — cài 1 lần là có cả bộ, khỏi lắp từng mảnh. Hiểu `/plugin` là hiểu "app store" của Claude Code.

## Khi nào dùng

- Dùng khi muốn cài bundle sẵn (skill + agent + hook + MCP + command) thay vì lắp từng mảnh.
- Dùng **trước khi** tự build lại thứ đã có plugin: discover trước, tự viết sau.
- Không dùng thay audit: plugin chạy code trên máy bạn, chỉ cài nguồn tin cậy.

## Cách gọi

```bash
/plugin              # mở trình quản lý plugin
/plugin discover     # khám phá plugin
/plugin browse       # duyệt marketplace
# cài từ marketplace: claude plugin install --marketplace (cần ≥2.1.292)
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Cài cho cả team (ghi vào settings commit git)
/plugin install commit-commands
/plugin install pr-review-toolkit

# File .claude/settings.json:
```

Kết quả mong đợi:

- Plugin enabled, lệnh/skill/agent/hook từ plugin xuất hiện sau khi nạp lại.
- Cài từ marketplace cần ≥2.1.292 (`claude plugin install --marketplace`).

**Kiểm tra nhanh:** `/plugin` Manage thấy enabled; gõ thử 1 lệnh của plugin để chắc đã nạp.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
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

> Mẹo 1 dòng: _cài 1 plugin rồi /doctor ngay — plugin mới là chỗ dễ lệch cấu hình._
