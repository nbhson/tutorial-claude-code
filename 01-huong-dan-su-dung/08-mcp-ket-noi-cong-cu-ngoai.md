# 08 — MCP: kết nối Claude tới thế giới ngoài (GitHub, DB, browser...)

> **Bài này cho ai:** dev muốn Claude chạm được GitHub/DB/browser/Notion, hoặc tech lead chuẩn hóa MCP cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 05 — Skills](./05-skills-custom-commands.md) trước vì mục 5 nói vì sao skill + MCP là cặp bài trùng.
> **Đọc xong bạn làm được:**
> - Setup được server GitHub / Playwright / Postgres / Notion theo lệnh copy-paste, kèm `.mcp.json` commit an toàn.
> - Chọn đúng scope (project/local/user) và biết scope nào thắng khi trùng tên.
> - Prune MCP gọn: tools visible ≤10, servers 3–6; debug được MCP đang hỏng bằng 4 nhánh từ `/mcp`.
> **Thời gian:** ~30 phút

## Mục lục

1. [MCP là gì và vì sao cần nó](#1-mcp-là-gì-và-vì-sao-cần-nó)
2. [Thêm server: 3 transports + OAuth từ terminal](#2-thêm-server-3-transports--oauth-từ-terminal)
3. [Setup từng server chi tiết (GitHub/Playwright/Postgres/Notion)](#3-setup-từng-server-chi-tiết-githubplaywrightpostgresnotion)
4. [Scope precedence — ai thắng khi trùng tên?](#4-scope-precedence--ai-thắng-khi-trùng-tên)
5. [Skill + MCP cặp bài trùng](#5-skill--mcp-cặp-bài-trùng)
6. [Prune guide — giữ MCP khỏe](#6-prune-guide--giữ-mcp-khỏe)
7. [Hiểu nhầm thường gặp + debug](#7-hiểu-nhầm-thường-gặp--debug)
8. [Đi tiếp — link chéo](#8-đi-tiếp--link-chéo)

---

## 1. MCP là gì và vì sao cần nó

**Nôm na 1 câu:** MCP là *cổng USB chuẩn* cho AI — cắm GitHub/DB/Browser vào là Claude dùng được ngay, khỏi viết glue-code riêng cho từng tool: 1 chuẩn `tools/list` + `tools/call`, server nào cũng nói cùng thứ tiếng. **Analogie bồi bàn gọi bếp:** bạn gọi bồi bàn (Claude Code), bồi bàn ghi order theo mẫu chuẩn rồi chuyển tới bếp (MCP Server: bếp GitHub, bếp Postgres, bếp Browser). Bếp nấu xong (gọi API/DB thật) trả món ra, bồi bàn trình bày đẹp lên bàn — bạn không bao giờ vào bếp hay paste token vào chat.

```bash
# MCP = vươn tay ra ngoài. Skill = dạy cách dùng tay đó cho đúng.
claude mcp add --transport stdio github --scope project -- npx @anthropic/mcp-github@latest
# Verify: trong session gõ /mcp
```

> **Ai dùng lúc nào:** dev cần Claude *chạm* thế giới ngoài repo — đọc PR/issue GitHub, query DB dev, mở browser chụp UI, tra Notion/Linear.
> **Khi nào KHÔNG cần MCP:** dữ liệu đã nằm trong repo → Claude đọc trực tiếp, thêm MCP chỉ tốn maintenance.

### 1.0. Sequence 1 request "liệt kê 5 PRs" qua 6 bước

1. **Bạn gõ prompt** — "liệt kê 5 PRs mở gần nhất": tiếng Việt tự nhiên, chưa phải API call.
2. **Claude Code (MCP Client)** — giữ danh sách tools/resources/prompts các server chào hàng (`tools/list` lúc session start).
3. **Chọn tool + approval** — Claude match ý định với `list_prs` (không phải `create_pr`), đối chiếu [permission rules](./10-permissions-modes-availability.md): read-only thường auto-allow, write thì hỏi. Có 10 tools tên na ná → accuracy giảm (prune, mục 6).
4. **`tools/call`** — gọi `list_prs {owner, repo, state:open, limit:5}`. Arguments sai schema → server trả lỗi validation, Claude tự sửa và gọi lại.
5. **Server gọi API thật** — dùng token (gh token / OAuth) gọi GitHub API. Token nằm ở env, bạn không paste vào chat (mục 4).
6. **Trình bày** — Claude tóm tắt JSON thô thành 5 dòng tiếng Việt + link; không bao giờ dump nguyên 2000 dòng JSON vào chat.

### 1.1. Tools / Resources / Prompts — 3 khái niệm cốt lõi

| Khái niệm | Là gì (nôm na) | Ví dụ thật | Claude dùng khi nào |
|---|---|---|---|
| **Tools** | Hàm Claude gọi, có input/output schema — *tay để hành động* | `github.create_pr`, `postgres.query` | Cần *hành động*: tạo PR, chạy query, mở browser. Read-only chạy luôn; write → hỏi bạn trước (trừ khi rule allow) |
| **Resources** | Dữ liệu đọc qua URI cố định — *mắt để đọc* | `github://repos/acme/api/issues/123` | Cần *đọc* 1 thực thể cụ thể (issue/PR/file/Notion page). Bạn không gõ URI tay — "đọc issue #123" là Claude tự resolve |
| **Prompts** | Template do SERVER định nghĩa, hiện thành slash command — *công thức pha sẵn* | `/mcp__github__review_pr 45` | Server chuẩn hóa workflow nhiều bước (review PR, triage). Khác skill: prompts đổi theo server, skill do BẠN viết trong `.claude/skills/` |

```json
// github.create_pr — write tool (sẽ hỏi approval), input schema JSON:
{ "name": "github.create_pr", "inputSchema": { "type": "object",
  "required": ["owner", "repo", "title", "head", "base"] } }
```

> **Công thức nhớ:** **MCP = reach (vươn tay), Skill = cách dùng reach đó cho đúng** (skill chứa schema DB, quy ước repo...). Quản lý hàng ngày bằng `/mcp`, thêm server bằng `claude mcp add`.

---

## 2. Thêm server: 3 transports + OAuth từ terminal

**Nôm na 1 câu:** `claude mcp add` là *cắm dây* — chọn loại dây (stdio/sse/http) + chọn ổ cắm (scope) rồi cắm server vào. stdio = xe nhà trong gara (nhanh, luôn sẵn, nhưng lên cloud là mất); sse/http = taxi (đi đâu cũng gọi được, cần mạng + token).

1. **stdio:** Claude spawn 1 process trên máy bạn (`npx ...`) — nhanh nhất, không cần auth phức tạp. *Dùng cho:* github/playwright/postgres dev trên laptop.
2. **sse:** kết nối streaming giữ lâu tới server remote. *Dùng cho:* API nội bộ realtime, cần push.
3. **http:** gọi REST từng request, OAuth dễ nhất. *Dùng cho:* Notion/Linear/Slack (mỗi người token riêng, scope `user`).

```bash
# Local stdio — Claude spawn process local (postgres xem mục 3.3)
claude mcp add --transport stdio playwright -- npx @playwright/mcp@latest

# Remote SSE / HTTP
claude mcp add --transport sse private-api https://api.example/mcp \
  --header "Authorization: Bearer TOKEN"
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Env + JSON + import từ Claude Desktop
claude mcp add <name> --env KEY=VALUE -- <cmd> [args...]
claude mcp add-json <name> '{"command":"npx","args":[...]}'
claude mcp add-from-claude-desktop
```

Scopes: `--scope project` (ghi `.mcp.json`, share team) / `local` / `user` (`~/.claude.json`) — chi tiết mục 4. Credentials **qua env vars, không commit**: remote server khai `${INTERNAL_API_URL}`, `${INTERNAL_API_TOKEN}` trong `.mcp.json` (xem ví dụ mục 4.1), giá thật để ở shell/cloud env.

Quản lý: `/mcp` (list/status), `/mcp reconnect <name>`, `enable/disable [name|all]`; CLI: `claude mcp list|get <name>|remove <name>|reset-project-choices|serve` (`serve` = biến chính Claude Code thành 1 MCP stdio server). Non-interactive `-p` (≥2.1.205): `/mcp` no-arg in text summary thay vì mở dialog.

### 2.1. OAuth từ terminal: `claude mcp login` / `claude mcp logout` (mới 2026)

Trước đây OAuth với MCP remote server phải mở session interactive và authorize qua `/mcp`. Từ Week 26/2026 có 2 lệnh terminal trực tiếp:

```bash
claude mcp login notion      # mở browser OAuth, lưu credential cho server notion
claude mcp logout notion     # xóa credential đã lưu
```

- Tiện cho setup script/CI: đăng nhập trước bằng `login`, rồi session non-interactive `-p` dùng được ngay mà không vướng màn hình authorize. Kiểm tra trạng thái auth vẫn bằng `claude mcp list` (cột connected/needs-auth) hoặc `claude mcp get <name>`.

### 2.2. Protocol negotiation 2026-07-28 + mô tả tool nới rộng

(06/10/2026, Claude Code ≥2.1.292) MCP mặc định negotiate protocol `2026-07-28` — tương tác MCP mới hơn với mọi provider, áp cho **cả** connector claude.ai lẫn MCP local `stdio` và remote (`sse`/`http`). Muốn quay lại giao thức cũ: đặt biến môi trường `MCP_PROTOCOL_NEGOTIATION=legacy`.

> Mô tả tool MCP được nới: mặc định 2.048 → 4.096 ký tự, và tới 16.384 ký tự qua tool search (≥2.1.295). Tool được mô tả đầy đủ hơn → model chọn đúng tool hơn, nhất là khi có nhiều server.

---

## 3. Setup từng server chi tiết (GitHub/Playwright/Postgres/Notion)

### 3.1. GitHub (impact cao nhất — cài đầu tiên)

```bash
# Bước 1: đảm bảo gh CLI login (dùng token sẵn có):
gh auth login && gh auth status   # phải thấy Logged in

# Bước 2: thêm server (project scope để share team):
claude mcp add --transport stdio github --scope project -- npx @anthropic/mcp-github@latest

# Bước 3: verify trong session:
/mcp
# Test: "liệt kê 5 PRs mở gần nhất của repo này + tóm tắt mỗi PR 1 dòng"
```

Kết quả trong `.mcp.json`: `{ "github": { "command": "npx", "args": ["@anthropic/mcp-github@latest"] } }` — commit được, không secrets vì dùng gh token máy.

### 3.2. Playwright (browser automation — Claude NHÌN UI)

```bash
claude mcp add --transport stdio playwright --scope project -- npx @playwright/mcp@latest
npx playwright install chromium   # cài browsers, 1 lần
pnpm dev &   # boot app local rồi nhờ Claude nhìn
# Verify trong session:
# > "mở http://localhost:3000/login bằng browser, chụp màn hình, nhận xét UI có vấn đề gì"
```

> Playwright local stdio KHÔNG theo lên cloud ([bài 02](./02-cac-be-mat-terminal-ide-web-desktop.md)) — cloud cần browser MCP remote hoặc `/verify` flow khác.

### 3.3. Postgres (đọc schema + query — KHÔNG commit password)

```bash
export PGPASSWORD_DEV="..."   # đặt ngoài file, trong shell/cloud env
claude mcp add --transport stdio postgres --scope local --env PGPASSWORD="$PGPASSWORD_DEV" -- \
  npx @modelcontextprotocol/server-postgres@latest "postgresql://dev@localhost:5432/acme_dev"

# Verify:
# > "liệt kê tables trong DB + đếm rows mỗi table, chỉ đọc không viết"
```

```json
// .mcp.json dùng env placeholder (commit an toàn):
{ "mcpServers": { "postgres": { "command": "npx",
  "args": ["@modelcontextprotocol/server-postgres@latest", "${DATABASE_URL}"] } } }
```

Quy tắc an toàn DB: dev DB cho read + (cân nhắc) write qua skill add-table; prod DB read-only, PreToolUse hook block mọi query chứa DELETE/DROP/UPDATE không WHERE; không bao giờ paste connection string prod vào chat/`.mcp.json` committed.

### 3.4. Notion (docs/tickets — remote HTTP + OAuth)

```bash
claude mcp add --transport http notion --scope user https://mcp.notion.com/mcp
claude mcp login notion   # hoặc lần đầu OAuth: /mcp → notion: authorize → browser → approve
# Test: "tìm docs Notion về API conventions của team, tóm tắt 10 dòng"

# Servers team hay dùng (pattern tương tự):
# Linear/Jira/Slack: remote HTTP/SSE + OAuth, scope user (mỗi người token riêng).
# Fetch/Brave Search: web grounding (check provider có hỗ trợ web search không — bài 10).
```

---

## 4. Scope precedence — ai thắng khi trùng tên?

**Nôm na 1 câu:** scope trả lời "server này của ai, sống ở đâu, có lên cloud không?". Thứ tự thắng khi trùng tên: `project` < `local` < `user`.

| Scope | File | Commit? | Khi nào |
|---|---|---|---|
| `project` | `.mcp.json` (repo root) | Có (không secrets) | Servers team dùng chung (github, fetch) |
| `local` | project-local (machine) | Không | Credentials máy dev (postgres dev) |
| `user` | `~/.claude.json` | Không | Personal (notion, linear cá nhân) |

- Cùng tên server ở 2 scopes → scope cụ thể hơn (user > local > project) thắng. `claude mcp reset-project-choices` → reset approvals đã chọn cho project servers.
- Cloud sessions: chỉ thấy project scope committed + cloud env (local/user ở laptop không bay lên — [bài 02](./02-cac-be-mat-terminal-ide-web-desktop.md)).

```bash
claude mcp list            # all servers + scope + status
claude mcp get github      # chi tiết 1 server (scope nào đang thắng?)
grep -ri "sk-\|token\|password" .mcp.json   # phải trống!
claude mcp remove postgres && claude mcp add --transport stdio postgres --scope local -- <cmd>
```

### 4.1. Ví dụ `.mcp.json` team chuẩn (commit được)

```json
{ "mcpServers": {
  "github": { "command": "npx", "args": ["@anthropic/mcp-github@latest"] },
  "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] },
  "internal-api": { "type": "http", "url": "${INTERNAL_API_URL}/mcp",
    "headers": { "Authorization": "Bearer ${INTERNAL_API_TOKEN}" } } } }
```

---

## 5. Skill + MCP cặp bài trùng

**Nôm na 1 câu:** MCP là *cánh tay vươn ra*, Skill là *bộ quy tắc cầm nắm cho khéo*. Có xe (MCP) không bằng lái (Skill) → gây tai nạn (query prod không WHERE). MCP cho khả năng thô (query bất kỳ SQL nào), Skill siết lại (chỉ SELECT + LIMIT 100, prod bắt buộc WHERE, output ≤20 rows). Mỗi server team dùng sâu nên có 1 skill kèm:

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

Tương tự cho Slack: skill `slack-post` định nghĩa format `[TAG] tiêu đề — 3 bullets max — link`, channel map trong `references/channels.md`, dry-run preview trước khi post.

**Verify nhanh:** chưa có skill, hỏi "query users table" → Claude `SELECT *` không LIMIT (ngốn context). Thêm skill `db-query`, hỏi lại → `SELECT ... LIMIT 100`, chỉ hiện 20 rows. Hai bước ra cùng kết quả = skill chưa load (check `.claude/skills/` + description có nhắc "query DB").

---

## 6. Prune guide — giữ MCP khỏe

**Nôm na 1 câu:** prune là *dọn tủ lạnh* định kỳ — món nào 2 tuần không ai ăn thì bỏ, kẻo tools nhiễu làm Claude chọn sai.

### 6.1. Day-one servers (sweet spot 3–6, đừng quá ~10 tools visible)

| Server | Để làm gì | Khi thêm | Khi prune |
|---|---|---|---|
| GitHub | PRs, issues, code search, branches cross-repo | Gần như luôn — impact cao nhất | Không bao giờ (trừ repo không dùng GitHub) |
| Playwright | Browser automation — Claude **nhìn** UI | Web app cần test UI | App không UI / đã có E2E khác |
| Postgres/MySQL/MongoDB | Đọc schema, chạy query | App có DB thật | Project docs-only, không DB |
| Fetch / Brave Search | Web grounding live | Cross-stack, tra docs | Provider đã có web search built-in |
| Linear / Notion / Jira / Slack | Tickets, docs, messages | Team sống trong đó | Team không dùng / đã migrate tool |

> Quá ~10 MCP tools visible → accuracy chọn tool giảm (gọi sai/bỏ sót). Đây là **ngưỡng thực nghiệm cộng đồng** (servers thực dùng 3–6), không phải số chính thức của Anthropic. Xem breakdown usage per-MCP bằng `/usage` (từ Week 21/2026, breakdown theo skill/subagent/plugin/MCP).

### 6.2. Prune flow định kỳ (2 tuần/lần, 10 phút)

```bash
# Trong session:
/usage    # breakdown per-MCP-server — server nào 0 calls 2 tuần?
/mcp      # status — server nào disconnected lâu? → disable <name> ở đây
# Bước 2: 1 tuần không ai kêu → remove hẳn:
claude mcp remove <name>
# Bước 3: audit tools visible:
# > "liệt kê MCP tools mày đang thấy + server nào expose. Server nào thừa?"
```

### 6.3. MCP tool hooks (nâng cao)

Hooks type `mcp_tool`: gọi tool của server đã connect ngay trong hook (vd: PostToolUse Edit → `mcp_tool linear.create_issue` log change cần review). Xem [bài 07 — Hooks](./07-hooks-tu-dong-hoa.md) cho schema. Production: test kỹ — hook gọi MCP có latency, fail thì có retry?

### 6.4. Checklist MCP khỏe

- [ ] `claude mcp list` all connected; OAuth xong (`/mcp` hoặc `claude mcp login`).
- [ ] `.mcp.json` commit được, secrets chỉ qua env (grep không ra secrets).
- [ ] Mỗi server sâu có 1 skill hướng dẫn dùng (schema, conventions).
- [ ] Tools visible ≤10, servers 3–6; server 2 tuần không gọi → disable → remove.
- [ ] Cloud sessions: cấu hình lại MCP trong cloud environment (local config không theo lên cloud).

---

## 7. Hiểu nhầm thường gặp + debug

| Hiểu nhầm | Sự thật | Ai cần nhớ |
|---|---|---|
| "Cài càng nhiều MCP càng mạnh" | Quá ~10 tools visible → Claude chọn sai/bỏ sót. Mạnh = 3–6 servers dùng thật + skill kèm. | Mọi dev mới setup |
| "MCP thay được Skill" | MCP cho *tay*, Skill cho *cách dùng*. Không skill → query sai schema, post Slack sai format. | Team lead review setup |
| "stdio lên cloud vẫn chạy" | stdio spawn process local → lên cloud mất. Cloud phải dùng http/sse remote + set lại env. | Ai dùng Web/cloud sessions |
| "Paste token vào .mcp.json rồi commit cho tiện" | Lộ secrets cả git history. Phải `${VAR}` + env ngoài. Lỡ commit → rotate ngay. | Mọi người (security) |
| "Resources/Tools/Prompts là 1" | Tools = hành động, Resources = đọc URI, Prompts = template `/mcp__server__name`. Nhầm là gọi sai. | Người mới học MCP |
| "`/mcp` chỉ để xem" | `/mcp` còn reconnect/enable/disable. Disconnected → reconnect trước, đừng vội remove. | Người debug MCP |

```text
MCP lỗi? → /mcp xem status: disconnected → /mcp reconnect <name>; unauthorized → re-OAuth / claude mcp login <name> / check header token; 0 calls 2 tuần → disable 1 tuần rồi remove; tools quá nhiều → prune + viết skill gom.
```

Debug MCP luôn bắt đầu từ `/mcp` (nhìn status), không đoán — 4 nhánh trên cover 90% lỗi thực tế. Thêm server stdio thất bại thường do thiếu binary: chạy tay `npx ... --help` để check; remote: header sai hoặc URL thiếu hậu tố `/mcp`.

---

## 8. Đi tiếp — link chéo

- **[Bài 02 — Từng bề mặt dùng](./02-cac-be-mat-terminal-ide-web-desktop.md)**: local stdio vs cloud HTTP/SSE; cloud env MCP setup lại.
- **[Bài 04 — Slash commands toàn tập](./04-slash-commands-toan-tap.md)**: `/mcp reconnect/enable/disable`, `/mcp__*__*` prompts động.
- **[Bài 05 — Skills](./05-skills-custom-commands.md)**: skill chứa *cách dùng* MCP (schema, format, channel map).
- **[Bài 07 — Hooks](./07-hooks-tu-dong-hoa.md)**: `mcp_tool` hooks type; PreToolUse guard DB prod.
- **[Bài 09 — Plugins & marketplaces](./09-plugins-marketplaces.md)**: bundle MCP servers vào plugin share team.
- **[Bài 10 — Permissions & availability](./10-permissions-modes-availability.md)**: MCP tools tuân permission rules; provider cắt web search.
- **[Bài 12 — SDK & CI/CD](./12-agent-sdk-ci-cd-automation.md)**: MCP trong CI runners + Agent SDK custom tools.
- **[tool-use/mcp-advanced](../tool-use/mcp-advanced/README.md)** (EN): cấu hình MCP nâng cao — protocol `2026-07-28`, viết MCP server custom, resource templates, orchestration multi-server.
