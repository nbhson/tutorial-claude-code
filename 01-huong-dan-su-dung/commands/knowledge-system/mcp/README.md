# /mcp — Kết nối công cụ ngoài: cho Claude dùng database, API, browser, GitHub

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có nếu cấu hình ẩu (OAuth/token lọt vào file commit git; server độc hại đọc file local; auto-allow MCP tools nguy hiểm)

> Nói nôm na: `/mcp` mở trung tâm quản lý MCP (Model Context Protocol): kết nối Claude Code với thế giới ngoài — database, GitHub, Slack, browser, Figma... MCP server phơi ra `tools` (hàm Claude gọi được), `resources` (dữ liệu đọc) và `prompts` (mẫu việc). Hiểu `/mcp` là hiểu cách "cắm thêm tay" cho Claude.

## Khi nào dùng

- Dùng /mcp khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /mcp **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /mcp thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/mcp`
`/mcp add <tên> <lệnh>`
`/mcp remove <tên>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

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

- Claude trả đúng việc của /mcp (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `MCP error: connection closed` sau sleep | Process stdio bị kill | `/mcp reconnect <tên>`; hoặc chuyển sang server HTTP |
| `auth expired` (vàng) | OAuth token hết hạn | `/mcp reconnect` để login lại |
| Thêm server mà model không thấy tools | Sai tên/caấu trúc `.mcp.json`, hoặc chưa handshake | `/mcp` xem status đỏ → `/mcp logs` đọc lỗi; validate JSON; thử lệnh `npx ...` tay ngoài terminal |

## Tham khảo

- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../plugin/README.md](../../knowledge-system/plugin/README.md)
- [../hooks/README.md](../../knowledge-system/hooks/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /mcp sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
