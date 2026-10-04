# FAQ 04 — MCP: Kết Nối & Sự Cố

**Thêm server thế nào?** `claude mcp add --transport <stdio|sse|http> <name> ...` (xem bài 08).
Scope: `--scope project` (`.mcp.json` share team) / `local` / `user`. Secrets qua env, không commit.

**Xem/sửa connections?** `/mcp` (list), `/mcp reconnect <name>`, `enable/disable [name|all]`.
CLI: `claude mcp list|get|remove|reset-project-choices`. `-p` ≥2.1.205: `/mcp` no-arg in text.

**Server disconnected?** Check token hết hạn, URL sai, OAuth chưa xong (`/mcp` reconnect + hoàn OAuth).

**MCP prompts là gì?** Prompts server expose → hiện `/mcp__<server>__<prompt>`, discover động, gõ `/` để thấy.

**Khi nào cần MCP vs đọc repo?** Data ngoài repo (DB, tickets, docs, browser, API internal) → MCP.
Data đã trong repo → đọc trực tiếp, thêm MCP chỉ tốn maintenance.

**Bao nhiêu server là đủ?** 3–6 thực dùng (GitHub + Playwright + DB + search + tickets...). >10 tools visible → accuracy giảm.

**Lên cloud mất MCP local?** Đúng — cloud chỉ dùng repo + cloud environment. Cấu hình lại servers/vars/setup script
trong environment (dùng `/web-setup` khởi tạo).

**Skill vs MCP?** MCP = kết nối; skill = cách dùng kết nối đó đúng (schema, format rules). Team dùng sâu → viết skill kèm.
