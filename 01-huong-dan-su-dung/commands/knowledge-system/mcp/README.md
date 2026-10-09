# /mcp — Kết nối công cụ ngoài: cho Claude dùng database, API, browser, GitHub

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Có nếu cấu hình ẩu (OAuth/token lọt vào file commit git; server độc hại đọc file local; auto-allow MCP tools nguy hiểm)
> **Nói nôm na:** `/mcp` mở trung tâm quản lý MCP (Model Context Protocol): kết nối Claude Code với thế giới ngoài — database, GitHub, Slack, browser, Figma... MCP server phơi ra `tools` (hàm Claude gọi được), `resources` (dữ liệu đọc) và `prompts` (mẫu việc). Từ bản ≥2.1.292, MCP mặc định negotiate protocol `2026-07-28`. Hiểu `/mcp` là hiểu cách "cắm thêm tay" cho Claude.

## Khi nào dùng

- Dùng khi cần cắm thêm tool ngoài: database, GitHub, Slack, browser, Figma...
- Dùng **trước khi** context phình vì tự dán dữ liệu: để MCP server cấp tool/resources thay vì copy-paste.
- Không dùng thay kiểm soát quyền: MCP tool vẫn phải qua permissions, đừng auto-allow ẩu.

## Cách gọi

```bash
/mcp                        # mở trung tâm quản lý server
/mcp add <tên> -- <lệnh>    # thêm server
/mcp remove <tên>           # gỡ server
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: thêm server (DSN qua env, không hardcode pass)
/mcp add db -- npx -y @bytebase/dbhub --dsn "${DB_DSN}"

# Bước 2: kiểm tra tools
/mcp show db
# → query, list_tables, describe_table

# Bước 3: dùng ngay trong chat
```

Kết quả mong đợi:

- Server handshake xanh, `tools/list` hiện đúng tool; gọi được ngay trong chat.
- DSN/token lấy từ env, không nằm trong `.mcp.json` commit.

**Kiểm tra nhanh:** `/mcp` xem status (xanh/đỏ); nếu đỏ thì `/mcp logs` đọc lỗi.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `MCP error: connection closed` sau sleep | Process stdio bị kill | `/mcp reconnect <tên>`; hoặc chuyển sang server HTTP |
| `auth expired` (vàng) | OAuth token hết hạn | `/mcp reconnect` để login lại |
| Thêm server mà model không thấy tools | Sai tên/cấu trúc `.mcp.json`, hoặc chưa handshake | `/mcp` xem status đỏ → `/mcp logs` đọc lỗi; validate JSON; thử lệnh `npx ...` tay ngoài terminal |

## Tham khảo

- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../plugin/README.md](../../knowledge-system/plugin/README.md)
- [../hooks/README.md](../../knowledge-system/hooks/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _giữ secrets qua `${ENV}` trong .mcp.json, đừng để token lọt vào git._
