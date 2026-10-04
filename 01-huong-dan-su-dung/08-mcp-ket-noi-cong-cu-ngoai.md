# 08 — MCP: Kết Nối Claude Tới Thế Giới Ngoài (GitHub, DB, Browser...)

> Bài 08 của series. Đọc xong bạn setup được từng server GitHub/Playwright/Postgres/Notion,
> hiểu scope precedence, và prune MCP gọn ≤10 tools. Thời gian: ~40 phút.

## Mục lục

1. [MCP là gì — why](#1-mcp-là-gì)
2. [Thêm server: 3 transports](#2-thêm-server-3-transports)
3. [Setup từng server chi tiết](#3-setup-từng-server-chi-tiết-githubplaywrightpostgresnotion)
4. [Scope precedence deep-dive](#4-scope-precedence-deep-dive)
5. [Skill + MCP cặp bài trùng](#5-skill--mcp-cặp-bài-trùng)
6. [Prune guide + walkthrough + pitfalls + bài tập](#6-prune-guide--giữ-mcp-khỏe)
7. [Link chéo](#7-link-chéo)

---

## 1. MCP là gì

**Model Context Protocol** — chuẩn mở để AI tools gọi ra hệ ngoài theo cấu trúc
(files, APIs, DBs, docs, browser actions, internal tools...). MCP server expose **tools/resources/prompts**;
Claude Code discover và gọi như tools built-in.

Công thức: **MCP = reach (vươn ra ngoài), Skill = cách dùng reach đó cho đúng**
(skill chứa schema DB, message-format rules, quy ước repo...).

Khi nào KHÔNG cần MCP: dữ liệu đã nằm trong repo → Claude đọc trực tiếp, thêm MCP chỉ tốn maintenance.

### 1.1. Cơ chế sâu (3 khái niệm)

| Khái niệm | Là gì | Ví dụ |
|---|---|---|
| **Tools** | Hàm Claude gọi (có input/output schema) | `github.create_pr`, `postgres.query` |
| **Resources** | Dữ liệu đọc (URI-addressable) | `github://repos/acme/api/issues/123` |
| **Prompts** | Templates hiện thành `/mcp__<server>__<prompt>` | `/mcp__github__review_pr` |

Transports: **stdio** (Claude spawn process local — nhanh, cần binary local),
**SSE/HTTP** (remote server — dùng được trên cloud, cần auth headers).

---

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

---

## 3. Setup từng server chi tiết (GitHub/Playwright/Postgres/Notion)

### 3.1. GitHub (impact cao nhất — cài đầu tiên)

```bash
# Bước 1: đảm bảo gh CLI login (dùng token sẵn có):
gh auth login
gh auth status   # phải thấy Logged in

# Bước 2: thêm server (project scope để share team):
claude mcp add --transport stdio github --scope project -- npx @anthropic/mcp-github@latest

# Bước 3: verify trong session:
/mcp
# → github: connected. Test:
# > "liệt kê 5 PRs mở gần nhất của repo này + tóm tắt mỗi PR 1 dòng"
```

```json
// .mcp.json sau khi thêm (commit được — không secrets nếu dùng gh token máy):
{
  "mcpServers": {
    "github": { "command": "npx", "args": ["@anthropic/mcp-github@latest"] }
  }
}
```

### 3.2. Playwright (browser automation — Claude NHÌN UI)

```bash
# Bước 1: thêm server:
claude mcp add --transport stdio playwright --scope project -- npx @playwright/mcp@latest

# Bước 2: cài browsers (1 lần):
npx playwright install chromium

# Bước 3: verify — boot app local rồi nhờ Claude nhìn:
pnpm dev &
# Trong session:
# > "mở http://localhost:3000/login bằng browser, chụp màn hình, nhận xét UI có vấn đề gì"
```

> Playwright local stdio KHÔNG theo lên cloud (bài 02) — cloud cần browser MCP remote hoặc `/verify` flow khác.

### 3.3. Postgres (đọc schema + query — KHÔNG commit password)

```bash
# Bước 1: thêm server với env (password qua env, KHÔNG paste vào .mcp.json):
export PGPASSWORD_DEV="..."   # đặt ngoài file, trong shell/cloud env
claude mcp add --transport stdio postgres --scope local --env PGPASSWORD="$PGPASSWORD_DEV" -- \
  npx @modelcontextprotocol/server-postgres@latest "postgresql://dev@localhost:5432/acme_dev"

# Bước 2: verify:
# > "liệt kê tables trong DB + đếm rows mỗi table, chỉ đọc không viết"
```

```json
// .mcp.json dùng env placeholder (commit an toàn):
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres@latest", "${DATABASE_URL}"],
      "env": {}
    }
  }
}
```

```text
Quy tắc an toàn DB:
- Dev DB: cho read + (cân nhắc) write qua skill add-table.
- Prod DB: read-only tools, PreToolUse hook block mọi query chứa DELETE/DROP/UPDATE không WHERE.
- Không bao giờ paste connection string prod vào chat/.mcp.json committed.
```

### 3.4. Notion (docs/tickets — remote HTTP + OAuth)

```bash
# Thêm server remote:
claude mcp add --transport http notion --scope user https://mcp.notion.com/mcp

# Trong session (lần đầu OAuth):
/mcp
# → notion: authorize → browser OAuth → approve → connected.
# Test:
# > "tìm docs Notion về API conventions của team, tóm tắt 10 dòng"
```

```bash
# Các servers team hay dùng (pattern tương tự):
# Linear/Jira/Slack: remote HTTP/SSE + OAuth, scope user (mỗi người token riêng).
# Fetch/Brave Search: web grounding (check provider có hỗ trợ web search không — bài 10).
claude mcp add --transport stdio fetch -- npx @modelcontextprotocol/server-fetch@latest
```

---

## 4. Scope precedence deep-dive

### 4.1. 3 scopes + thứ tự thắng

```
project (.mcp.json, commit cho team) < local (project + machine, không commit) < user (~/.claude.json, mọi project)
```

| Scope | File | Commit? | Khi nào |
|---|---|---|---|
| `project` | `.mcp.json` (repo root) | Có (không secrets) | Servers team dùng chung (github, fetch) |
| `local` | project-local (machine) | Không | Credentials máy dev (postgres dev) |
| `user` | `~/.claude.json` | Không | Personal (notion, linear cá nhân) |

- Cùng tên server ở 2 scopes → scope cụ thể hơn (user > local > project) thắng.
- `claude mcp reset-project-choices` → reset approvals đã chọn cho project servers.
- Cloud sessions: chỉ thấy project scope committed + cloud env (local/user không theo — bài 02).

```bash
# Xem + debug scopes (copy-paste):
claude mcp list            # all servers + scope + status
claude mcp get github     # chi tiết 1 server (scope nào thắng?)
cat .mcp.json             # project scope committed — có secrets lọt không?
# → grep secrets: grep -ri "sk-\|token\|password" .mcp.json (phải trống!)

# Đổi scope khi đặt nhầm:
claude mcp remove postgres
claude mcp add --transport stdio postgres --scope local -- <cmd>  # chuyển sang local
```

### 4.2. Ví dụ `.mcp.json` team chuẩn (commit được)

```json
{
  "mcpServers": {
    "github": { "command": "npx", "args": ["@anthropic/mcp-github@latest"] },
    "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] },
    "fetch": { "command": "npx", "args": ["@modelcontextprotocol/server-fetch@latest"] },
    "internal-api": {
      "type": "http",
      "url": "${INTERNAL_API_URL}/mcp",
      "headers": { "Authorization": "Bearer ${INTERNAL_API_TOKEN}" }
    },
    "postgres": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres@latest", "${DATABASE_URL}"],
      "env": {}
    }
  }
}
```

---

## 5. Skill + MCP cặp bài trùng

MCP cho reach, skill dạy cách dùng reach. Mỗi server team dùng sâu nên có 1 skill kèm:

```markdown
# Ví dụ: .claude/skills/db-query/SKILL.md (kèm postgres MCP)
---
name: db-query
description: Query DB an toàn qua postgres MCP. Dùng khi user nói query DB, xem data, check schema.
allowed-tools: Read
---

# DB Query
- Dev DB (`$DATABASE_URL` trỏ dev): SELECT thoải mái, limit 100 rows.
- Prod: CHỈ SELECT, bắt buộc WHERE + LIMIT, KHÔNG DELETE/DROP/UPDATE.
- Schema tham khảo: `docs/schema.md` (update mỗi sprint).
- Output: tối đa 20 rows trong chat, full export ra file nếu nhiều.
- Dynamic: tables gần đổi: !`ls -t db/migrations/ | head -5`
```

```markdown
# Ví dụ: .claude/skills/slack-post/SKILL.md (kèm slack MCP)
---
name: slack-post
description: Post message Slack đúng format team. Dùng khi user nói post/notify Slack.
---
# Format: [TAG] tiêu đề — 3 bullets max — link PR/issue. Không @channel trừ incident.
# Channel map: xem references/channels.md. Dry-run: hiện preview trước khi post.
```

---

## 6. Prune guide — giữ MCP khỏe

### 6.1. Day-one servers (sweet spot 3–6, đừng quá ~10 tools visible)

| Server | Để làm gì | Khi thêm | Khi prune |
|---|---|---|---|
| GitHub | PRs, issues, code search, branches cross-repo | Gần như luôn — impact cao nhất | Không bao giờ (trừ repo không dùng GitHub) |
| Playwright | Browser automation — Claude **nhìn** UI | Web app cần test UI | App không UI / đã có E2E khác |
| Postgres/MySQL/MongoDB | Đọc schema, chạy query | App có DB thật | Project docs-only, không DB |
| Fetch / Brave Search | Web grounding live | Cross-stack, tra docs | Provider đã có web search built-in |
| Linear / Notion / Jira / Slack | Tickets, docs, messages | Team sống trong đó | Team không dùng / đã migrate tool |

> Quá ~10 MCP tools visible → accuracy chọn tool giảm (gọi sai/bỏ sót). Thêm cái dùng thật, prune cái không.

### 6.2. Prune flow định kỳ (2 tuần/lần, 10 phút)

```bash
# Bước 1: xem ai ngốn (trong session):
/usage    # breakdown per-MCP-server — server nào 0 calls 2 tuần?
/mcp      # status — server nào disconnected lâu?

# Bước 2: disable trước, remove sau:
# Trong session: /mcp → disable <name> (1 tuần không ai kêu → remove hẳn)
claude mcp remove <name>

# Bước 3: audit tools visible:
# > "liệt kê MCP tools mày đang thấy + server nào expose. Server nào thừa?"
```

### 6.3. MCP prompts → slash commands động

Server có thể expose prompts → hiện dạng `/mcp__<server>__<prompt>`. Gõ `/` để thấy.

```text
# Ví dụ: github server expose review_pr prompt:
# Gõ "/" → thấy /mcp__github__review_pr → gọi như slash command.
# Khác skill: prompts do SERVER định nghĩa (đổi server là đổi list).
```

### 6.4. MCP tool hooks (nâng cao)

Hooks type `mcp_tool`: gọi tool của server đã connect ngay trong hook (vd: PostToolUse → log sang ticketing).
Xem Hooks reference cho schema.

```json
// Ví dụ ý tưởng (schema chi tiết xem docs Hooks reference):
// PostToolUse Edit → mcp_tool linear.create_issue (log change cần review).
// Production: test kỹ — hook gọi MCP có latency, fail thì có retry?
```

### 6.5. Checklist MCP khỏe

- [ ] `claude mcp list` all connected; OAuth xong (`/mcp`).
- [ ] `.mcp.json` commit được, secrets chỉ qua env (grep không ra secrets).
- [ ] Mỗi server sâu có 1 skill hướng dẫn dùng (schema, conventions).
- [ ] Tools visible ≤10, servers 3–6.
- [ ] Định kỳ prune: server nào 2 tuần không gọi → disable → remove.
- [ ] Cloud sessions: cấu hình lại MCP trong cloud environment (local config không theo lên cloud).

### 6.6. Pitfalls + bài tập

| Pitfall | Vì sao | Fix |
|---|---|---|
| Paste password vào `.mcp.json` rồi commit | Tiện tay | Env placeholder `${VAR}` + secrets ở shell/cloud env; `git rm` + rotate creds đã lọt |
| Cài 15 servers "cho chắc" | Sợ thiếu | 3–6, prune định kỳ; check `/usage` |
| Local stdio lên cloud mất | Cloud không có binary local | Cloud dùng HTTP/SSE remotes (bài 02) |
| Token hết hạn → disconnected | OAuth ngắn hạn | `/mcp reconnect <name>`; cron nhắc re-auth |
| Không skill kèm → Claude query sai schema | MCP không biết conventions | Viết skill db-query/slack-post (mục 5) |

**Bài tập:**

**Bài 1 (15 phút):** Cài GitHub server (mục 3.1). Test 3 prompts: list PRs, đọc issue, search code cross-repo.

**Bài 2 (15 phút):** Cài Postgres dev (mục 3.3, env placeholder). Viết skill `db-query` kèm. Test SELECT + verify prod guard.

**Bài 3 (15 phút):** Cài Playwright (mục 3.2). Boot app local, nhờ Claude mở + screenshot + nhận xét UI.

**Bài 4 (10 phút):** Chạy prune flow (mục 6.2): `/usage` → tìm server 0 calls → disable. Audit `.mcp.json` secrets.

---

## 7. Link chéo

- **Bài 02 — Surfaces**: local stdio vs cloud HTTP/SSE; cloud env MCP setup lại.
- **Bài 04 — Slash commands**: `/mcp reconnect/enable/disable`, `/mcp__*__*` prompts động.
- **Bài 05 — Skills**: skill chứa *cách dùng* MCP (schema, format, channel map).
- **Bài 07 — Hooks**: `mcp_tool` hooks type; PreToolUse guard DB prod.
- **Bài 09 — Plugins**: bundle MCP servers vào plugin share team.
- **Bài 10 — Permissions**: MCP tools tuân permission rules; provider cắt web search.
- **Bài 12 — SDK/CI**: MCP trong CI runners + Agent SDK custom tools.
