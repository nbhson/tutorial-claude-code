# 08 — MCP: Kết Nối Claude Tới Thế Giới Ngoài (GitHub, DB, Browser...)

## 1. MCP là gì

**Model Context Protocol** — chuẩn mở để AI tools gọi ra hệ ngoài theo cấu trúc
(files, APIs, DBs, docs, browser actions, internal tools...). MCP server expose **tools/resources/prompts**;
Claude Code discover và gọi như tools built-in.

Công thức: **MCP = reach (vươn ra ngoài), Skill = cách dùng reach đó cho đúng**
(skill chứa schema DB, message-format rules, quy ước repo...).

Khi nào KHÔNG cần MCP: dữ liệu đã nằm trong repo → Claude đọc trực tiếp, thêm MCP chỉ tốn maintenance.

## 2. Thêm server (3 transports)

```bash
# Local stdio — Claude spawn process local
claude mcp add --transport stdio playwright -- npx @playwright/mcp@latest
claude mcp add --transport stdio github -- npx @anthropic/mcp-github@latest
claude mcp add --transport stdio postgres -- npx @modelcontextprotocol/server-postgres@latest \
  postgresql://user:pass@host/db

# Remote SSE / HTTP
claude mcp add --transport sse private-api https://api.example/mcp \
  --header "Authorization: Bearer TOKEN"
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Env + JSON + import từ Claude Desktop
claude mcp add <name> --env KEY=VALUE -- <cmd> [args...]
claude mcp add-json <name> '{"command":"npx","args":[...]}'
claude mcp add-from-claude-desktop
```

Scopes: `--scope project` (ghi `.mcp.json`, share team) / `local` / `user` (`~/.claude.json`).
Credentials **qua env vars, không commit**:

```json
{ "mcpServers": { "internal-api": {
  "type": "http", "url": "${INTERNAL_API_URL}/mcp",
  "headers": { "Authorization": "Bearer ${INTERNAL_API_TOKEN}" } } } }
```

Quản lý: `/mcp` (list/status), `/mcp reconnect <name>`, `enable/disable [name|all]`;
CLI: `claude mcp list|get <name>|remove <name>|reset-project-choices|serve`
(`serve` = biến chính Claude Code thành 1 MCP stdio server).
Non-interactive `-p` (≥2.1.205): `/mcp` no-arg in text summary thay vì mở dialog.

## 3. Day-one servers (sweet spot 3–6, đừng quá ~10 tools visible)

| Server | Để làm gì | Khi thêm |
|---|---|---|
| GitHub | PRs, issues, code search, branches cross-repo | Gần như luôn — impact cao nhất |
| Playwright | Browser automation — Claude **nhìn** UI | Web app cần test UI |
| Postgres/MySQL/MongoDB | Đọc schema, chạy query | App có DB thật |
| Fetch / Brave Search | Web grounding live | Cross-stack, tra docs |
| Linear / Notion / Jira / Slack | Tickets, docs, messages | Team sống trong đó |

> Quá ~10 MCP tools visible → accuracy chọn tool giảm (gọi sai/bỏ sót). Thêm cái dùng thật, prune cái không.

## 4. MCP prompts → slash commands động

Server có thể expose prompts → hiện dạng `/mcp__<server>__<prompt>`. Gõ `/` để thấy.

## 5. MCP tool hooks (nâng cao)

Hooks type `mcp_tool`: gọi tool của server đã connect ngay trong hook (vd: PostToolUse → log sang ticketing).
Xem Hooks reference cho schema.

## 6. Checklist MCP khỏe

- [ ] `claude mcp list` all connected; OAuth xong (`/mcp`).
- [ ] `.mcp.json` commit được, secrets chỉ qua env.
- [ ] Mỗi server có 1 skill hướng dẫn dùng (schema, conventions) nếu team dùng sâu.
- [ ] Định kỳ prune: server nào 2 tuần không gọi → remove.
- [ ] Cloud sessions: cấu hình lại MCP trong cloud environment (local config không theo lên cloud).
