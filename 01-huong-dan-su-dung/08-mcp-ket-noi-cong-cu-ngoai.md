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

## Mục lục

1. [MCP là gì — why](#1-mcp-là-gì)
   - [1.0. Sơ đồ tổng quan](#10-sơ-đồ-tổng-quan-claude-code--mcp)
   - [1.1. Sequence 1 request "liệt kê 5 PRs"](#11-sequence-1-request-liệt-kê-5-prs-qua-6-bước)
   - [1.2. Tools — tay để hành động](#12-tools--tay-để-hành-động)
   - [1.3. Resources — mắt để đọc](#13-resources--mắt-để-đọc)
   - [1.4. Prompts — công thức pha sẵn](#14-prompts--công-thức-pha-sẵn)
2. [Thêm server: 3 transports](#2-thêm-server-3-transports)
3. [Setup từng server chi tiết](#3-setup-từng-server-chi-tiết-githubplaywrightpostgresnotion)
4. [Scope precedence deep-dive](#4-scope-precedence-deep-dive)
5. [Skill + MCP cặp bài trùng](#5-skill--mcp-cặp-bài-trùng)
6. [Prune guide + walkthrough + pitfalls + bài tập](#6-prune-guide--giữ-mcp-khỏe)
7. [Hiểu nhầm thường gặp](#7-hiểu-nhầm-thường-gặp)
8. [Link chéo](#8-link-chéo)

---

## 1. MCP là gì

**Nôm na 1 câu:** MCP là *cổng USB chuẩn* cho AI — cắm GitHub/DB/Browser vào là Claude dùng được ngay, khỏi viết glue-code riêng cho từng tool.

**Analogie đời thường (2 lớp):**
- *Ổ USB:* trước đây mỗi thiết bị cần driver riêng (chuột, máy in, ổ cứng mỗi kiểu cắm khác nhau). USB ra đời → 1 chuẩn cắm cho tất cả. MCP cũng vậy: trước đây mỗi AI phải viết integration riêng cho GitHub, Postgres...; có MCP → 1 chuẩn `tools/list` + `tools/call`, server nào cũng nói cùng thứ tiếng.
- *Bồi bàn gọi bếp:* bạn (user) gọi bồi bàn (Claude Code). Bồi bàn không tự nấu, mà ghi order theo mẫu chuẩn rồi hét vào bếp (MCP Server: bếp GitHub, bếp Postgres, bếp Browser). Bếp nấu xong (gọi API/DB/Browser thật) trả món ra, bồi bàn trình bày đẹp lên bàn. Bạn không bao giờ vào bếp — chỉ nói với bồi bàn.

**Ví dụ kỹ thuật copy-paste (nhìn là hiểu quan hệ):**

```bash
# MCP = vươn tay ra ngoài. Skill = dạy cách dùng tay đó cho đúng.
claude mcp add --transport stdio github --scope project -- npx @anthropic/mcp-github@latest
# Verify: trong session gõ
# /mcp
# Kỳ vọng: dòng `github: connected`. Chưa connected → xem mục 6 debug + bài tập 4.
```

> **Ai dùng lúc nào:** dev cần Claude *chạm* thế giới ngoài repo — đọc PR/issue GitHub, query DB dev, mở browser chụp UI, tra Notion/Linear. Nếu dữ liệu đã nằm trong repo → đừng thêm MCP (đọc file trực tiếp rẻ hơn).

**Công thức nhớ:** **MCP = reach (vươn tay), Skill = cách dùng reach đó cho đúng**
(skill chứa schema DB, message-format rules, quy ước repo...). Quản lý hàng ngày bằng `/mcp`, thêm server bằng `claude mcp add --transport stdio|sse|http --scope project|local|user`.

Khi nào KHÔNG cần MCP: dữ liệu đã nằm trong repo → Claude đọc trực tiếp, thêm MCP chỉ tốn maintenance.

### 1.0. Sơ đồ tổng quan Claude Code → MCP

```mermaid
flowchart LR
  U[Bạn gõ prompt] --> C[Claude Code<br/>MCP Client]
  C --> G[MCP Server github<br/>stdio]
  C --> P[MCP Server postgres<br/>stdio]
  C --> W[MCP Server playwright<br/>stdio]
  C --> N[MCP Server notion<br/>http remote]
  G --> GH[(GitHub API<br/>PRs/issues/code)]
  P --> DB[(Postgres DB<br/>schema + rows)]
  W --> BR[(Browser Chromium<br/>mở trang + screenshot)]
  N --> NO[(Notion workspace<br/>docs + tickets)]
```

**Giải thích từng bước (đọc sơ đồ từ trái sang phải):**
1. **Bạn gõ prompt** — vd "liệt kê 5 PRs mở gần nhất". Đây là tiếng Việt tự nhiên, chưa phải API call.
2. **Claude Code (MCP Client)** — bộ não + điều phối. Nó giữ danh sách tools/resources/prompts mà các server đã chào hàng (`tools/list` lúc session start).
3. **MCP Servers (github/postgres/playwright/notion)** — 4 "bếp" chuyên món riêng. Mỗi server là 1 process (stdio, Claude spawn local) hoặc 1 URL remote (sse/http). Server dịch lệnh chuẩn MCP thành API thật.
4. **Hệ ngoài (GitHub API / DB / Browser / Notion)** — nơi dữ liệu thật sống. Server gọi tới đây, lấy kết quả thô về.
5. **Đường về:** kết quả thô → server bọc thành JSON MCP → client (Claude) trình bày thành tiếng Việt gọn + gợi ý bước tiếp.

```bash
# Verify sơ đồ trên máy bạn (copy-paste):
claude mcp list
# Kỳ vọng: thấy 4 dòng github/postgres/playwright/notion + scope + connected.
# Chỉ thấy 1-2 dòng là bình thường (cài tới đâu hiện tới đó) — làm tiếp mục 3.
```

### 1.1. Sequence 1 request "liệt kê 5 PRs" qua 6 bước

```mermaid
sequenceDiagram
  participant U as Bạn
  participant C as Claude Code (Client)
  participant S as MCP Server github
  participant A as GitHub API
  U->>C: "liệt kê 5 PRs mở gần nhất"
  C->>S: 1. tools/list — mày có tools gì?
  S-->>C: 2. trả catalog: list_prs, get_pr, create_pr...
  C->>C: 3. chọn tool + xin approval (hỏi bạn nếu rule ask)
  C->>S: 4. tools/call list_prs {owner, repo, state:open, limit:5}
  S->>A: 5. GET /repos/{owner}/{repo}/pulls?state=open&per_page=5
  A-->>S: JSON 5 PRs thô
  S-->>C: trả kết quả MCP
  C-->>U: 6. trình bày: mỗi PR 1 dòng + link + gợi ý review
```

**Giải thích từng bước:**
1. **`tools/list` (chào hàng):** lúc session start (và khi `/mcp reconnect`), Claude hỏi mỗi server "mày biết làm gì?". Server trả catalog kèm JSON schema đầu vào.
2. **Chọn tool:** Claude match ý định "liệt kê PRs" với `list_prs` (không phải `create_pr`). Nếu có 10 tools tên na ná → đây là chỗ accuracy giảm khi cài quá nhiều server (xem prune mục 6).
3. **Approval:** harness đối chiếu permission rules (bài 10) + `ask` — read-only thường auto-allow, write (create_pr/merge) thì hỏi. Bạn thấy dòng `Allow?` chính là bước này.
4. **`tools/call`:** Claude gọi tool với arguments đã điền (owner/repo/limit). Arguments sai schema → server trả lỗi validation, Claude sửa và gọi lại.
5. **Server gọi API thật:** server dùng token (gh token / OAuth) gọi GitHub API. Bạn không bao giờ paste token vào chat — token nằm ở env (mục 4).
6. **Trình bày:** Claude tóm tắt JSON thô thành 5 dòng tiếng Việt + link. JSON 2000 dòng không bao giờ dump nguyên vào chat.

```text
# Verify sequence này (copy-paste trong session đã cài github):
# > "liệt kê 5 PRs mở gần nhất của repo này + tóm tắt mỗi PR 1 dòng"
# Kỳ vọng: Claude gọi list_prs (bạn thấy tool call), trả 5 dòng + link PR.
# Nếu Claude hỏi "owner/repo là gì?" → nó thiếu context repo, trả lời tên repo rồi hỏi lại.
```

### 1.2. Tools — tay để hành động

**Nôm na 1 câu:** Tools là *hàm Claude bấm được* — có tên, có schema đầu vào/ra rõ ràng.

**Analogie:** như nút bấm trên máy bán hàng: nút "Cà phê đen" (tên tool) + options "đá/đường" (schema). Bồi bàn chỉ cần bấm đúng nút, bếp tự biết pha.

**Ví dụ kỹ thuật thật (2 tools hay dùng nhất):**

```json
// github.create_pr — tạo PR (write, sẽ hỏi approval)
{
  "name": "github.create_pr",
  "inputSchema": {
    "type": "object",
    "required": ["owner", "repo", "title", "head", "base"],
    "properties": {
      "owner": { "type": "string", "description": "org/user, vd acme" },
      "repo": { "type": "string", "description": "vd api" },
      "title": { "type": "string" },
      "head": { "type": "string", "description": "branch nguồn feat/x" },
      "base": { "type": "string", "description": "branch đích, thường main" },
      "body": { "type": "string" }
    }
  }
}
```

```json
// postgres.query — chạy SQL (read/write tùy câu lệnh!)
{
  "name": "postgres.query",
  "inputSchema": {
    "type": "object",
    "required": ["sql"],
    "properties": {
      "sql": { "type": "string", "description": "vd SELECT id,title FROM issues LIMIT 5" }
    }
  }
}
```

> **Claude dùng khi nào:** khi cần *hành động* ra ngoài — tạo PR, post comment, chạy query, mở browser, tạo ticket. Read-only (list_prs, SELECT) chạy luôn; write (create_pr, DELETE) → hỏi bạn trước (trừ khi rule allow).
> **Ai dùng lúc nào:** dev dùng `github.*` hàng ngày; ai đụng DB dùng `postgres.query` qua skill `db-query` (mục 5) để khỏi viết SQL nguy hiểm.

```text
# Verify Tools (trong session):
# > "liệt kê MCP tools mày đang thấy + server nào expose. Server nào thừa?"
# Kỳ vọng: Claude liệt kê tên tools theo server (github: list_prs...; postgres: query...).
# Quá ~10 tools visible → accuracy giảm, prune theo mục 6.
```

### 1.3. Resources — mắt để đọc

**Nôm na 1 câu:** Resources là *dữ liệu đọc qua địa chỉ URI* — không phải hàm, mà là file/issue/doc có địa chỉ cố định.

**Analogie:** như số phòng khách sạn `tầng-3-phòng-12`: bạn không cần gọi bếp, chỉ cần biết địa chỉ là tìm tới đọc được.

**Ví dụ kỹ thuật thật:**

```text
# URI pattern của github server:
github://repos/acme/api/issues/123
github://repos/acme/api/pulls/45/diff
github://repos/acme/api/files/main/src/auth.ts

# Claude đọc resource thế nào (bạn không gõ URI tay, Claude tự resolve):
# > "đọc issue #123 xem bug gì"
# → Claude resolve thành github://repos/acme/api/issues/123 → fetch nội dung → tóm tắt.
```

> **Claude dùng khi nào:** khi cần *đọc* 1 thực thể cụ thể (issue/PR/file/Notion page) mà không cần tính toán. Nhẹ hơn tools/call vì không cần arguments phức tạp.
> **Ai dùng lúc nào:** reviewer cần đọc issue/PR kèm diff; dev tra docs Notion ("đọc page API conventions").

```text
# Verify Resources:
# > "đọc issue #123 của repo này"
# Kỳ vọng: Claude fetch resource URI tương ứng, tóm tắt title + labels + comments mới nhất.
# Nếu báo "không tìm thấy resource" → server github chưa connected (/mcp kiểm tra).
```

### 1.4. Prompts — công thức pha sẵn

**Nôm na 1 câu:** Prompts là *template do server định nghĩa*, hiện lên như slash command `/mcp__<server>__<prompt>`.

**Analogie:** như món "combo ăn sáng" in sẵn trên menu: 1 tên gọi (`/mcp__github__review_pr`) là bếp tự biết gồm trứng + bánh mì + cà phê (template nhiều bước), khỏi gọi từng món.

**Ví dụ kỹ thuật thật:**

```text
# Gõ "/" trong session đã cài github → thấy:
/mcp__github__review_pr
# Gọi:
/mcp__github__review_pr 45
# Kỳ vọng: server nhét PR #45 vào template review chuẩn của nó
# (diff + checklist + format report), Claude chạy theo template đó.

# Khác skill ở chỗ: prompts do SERVER định nghĩa (đổi server là đổi list).
# Skill do BẠN viết (.claude/skills/), prompts do SERVER expose.
```

> **Claude dùng khi nào:** khi server muốn chuẩn hóa 1 workflow nhiều bước (review PR, triage issue) — gọi 1 prompt thay vì chain 5 tools tay.
> **Ai dùng lúc nào:** team dùng github server → dùng `/mcp__github__review_pr` thay vì viết skill review riêng; team Postgres → prompt query mẫu có sẵn.

```text
# Verify Prompts:
# Gõ "/" → tìm dòng bắt đầu /mcp__ → có là server expose prompts thành công.
# Không thấy → server đó không expose prompts (bình thường, không phải lỗi).
```

### 1.5. Cơ chế sâu tóm lại (3 khái niệm)

| Khái niệm | Là gì (nôm na) | Ví dụ thật | Claude dùng khi nào |
|---|---|---|---|
| **Tools** | Hàm Claude gọi (có input/output schema) | `github.create_pr`, `postgres.query` | Cần *hành động*: tạo PR, chạy query, mở browser |
| **Resources** | Dữ liệu đọc (URI-addressable) | `github://repos/acme/api/issues/123` | Cần *đọc* 1 thực thể cụ thể |
| **Prompts** | Templates hiện thành `/mcp__<server>__<prompt>` | `/mcp__github__review_pr` | Cần *workflow chuẩn* server đóng gói sẵn |

Transports: **stdio** (Claude spawn process local — nhanh, cần binary local),
**SSE/HTTP** (remote server — dùng được trên cloud, cần auth headers). Chi tiết + lệnh ở mục 2.

---

## 2. Thêm server (3 transports)

**Nôm na 1 câu:** `claude mcp add` là *cắm dây* — chọn loại dây (stdio/sse/http) + chọn ổ cắm (scope project/local/user) rồi cắm server vào.

**Analogie:** như gọi xe: stdio = xe nhà trong gara (nhanh, luôn sẵn, nhưng lên cloud là mất); sse/http = taxi công nghệ (đi đâu cũng gọi được, nhưng cần mạng + token trả tiền).

```mermaid
flowchart TD
  A[Chọn transport] --> S[stdio: spawn local<br/>npx ...]
  A --> E[sse: remote streaming<br/>https://.../mcp]
  A --> H[http: remote request/response<br/>https://.../mcp]
  S --> L1[Nhanh, 0 auth phức tạp<br/>Mất trên cloud]
  E --> L2[Realtime, cần header token<br/>Dùng được cloud]
  H --> L3[OAuth tiện, Notion/Linear<br/>Dùng được cloud]
```

**Giải thích từng nhánh:**
1. **stdio:** Claude `fork` 1 process trên máy bạn (`npx ...`). Không mạng, nhanh nhất. *Ai dùng lúc nào:* github/playwright/postgres dev trên laptop.
2. **sse:** kết nối streaming giữ lâu tới server remote. *Ai dùng lúc nào:* API nội bộ realtime, cần push.
3. **http:** gọi REST từng request, OAuth dễ nhất. *Ai dùng lúc nào:* Notion/Linear/Slack (mỗi người token riêng, scope `user`).

```bash
# Local stdio — Claude spawn process local
claude mcp add --transport stdio playwright -- npx @playwright/mcp@latest
claude mcp add --transport stdio github -- npx @anthropic/mcp-github@latest
claude mcp add --transport stdio postgres -- npx @modelcontextprotocol/server-postgres@latest \
  postgresql://user:pass@host/db
# Verify: claude mcp list → thấy 3 dòng trên status connected (hoặc needs-auth).
# Kỳ vọng: stdio fail thường do thiếu binary (npx/node) — chạy tay `npx ... --help` để check.

# Remote SSE / HTTP
claude mcp add --transport sse private-api https://api.example/mcp \
  --header "Authorization: Bearer TOKEN"
claude mcp add --transport http notion https://mcp.notion.com/mcp
# Verify: /mcp → notion: authorize → OAuth browser → connected.
# Kỳ vọng: sse/http fail thường do header sai hoặc URL thiếu /mcp suffix.

# Env + JSON + import từ Claude Desktop
claude mcp add <name> --env KEY=VALUE -- <cmd> [args...]
claude mcp add-json <name> '{"command":"npx","args":[...]}'
claude mcp add-from-claude-desktop
# Verify: claude mcp get <name> → thấy env + command đúng.
# Kỳ vọng: --env để secrets ở env, không hardcode vào .mcp.json (xem mục 4).
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

**Nôm na 1 câu:** scope trả lời "server này của *ai*, sống ở *đâu*, đi theo *lên cloud không*?".

**Analogie:** như chỗ để đồ: project = tủ lạnh chung của team (ai cũng mở được, đồ phải dán nhãn không độc); local = ngăn kéo bàn bạn ở văn phòng (riêng máy đó); user = balo bạn đeo đi đâu cũng mang (mọi repo trên máy bạn).

```mermaid
flowchart LR
  P[project<br/>.mcp.json<br/>commit] --> L[local<br/>project+machine<br/>không commit]
  L --> U[user<br/>~/.claude.json<br/>mọi project]
  U --> WIN[Thắng khi trùng tên]
  P -.->|không theo lên cloud nếu có secrets| C[Cloud chỉ thấy project committed + cloud env]
```

**Giải thích:** mũi tên càng phải càng riêng tư càng thắng. Trùng tên `postgres` ở cả project + user → user thắng. Cloud chỉ thấy `project` đã commit + env bạn set riêng trong cloud (local/user ở laptop không bay lên).

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

**Nôm na 1 câu:** MCP là *cánh tay vươn ra*, Skill là *bộ quy tắc cầm nắm cho khéo* — thiếu 1 trong 2 là hoặc không với tới, hoặc với tới mà làm đổ vỡ.

**Analogie:** MCP như xe máy phân khối lớn (mạnh, đi xa); Skill như bằng lái + luật giao thông team (chạy lane nào, tốc độ bao nhiêu, cấm bóp còi ở đâu). Có xe không bằng → gây tai nạn (query prod không WHERE). Có bằng không xe → chỉ lý thuyết.

```mermaid
flowchart LR
  M[MCP Server<br/>reach thô] --> S[Skill db-query/slack-post<br/>rules + schema + format]
  S --> C[Claude hành động chuẩn team]
```

**Giải thích:** MCP cho khả năng thô (query bất kỳ SQL nào). Skill siết lại (chỉ SELECT + LIMIT 100, prod bắt buộc WHERE, output ≤20 rows). Mỗi server team dùng sâu nên có 1 skill kèm:

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

```bash
# Verify cặp Skill+MCP (copy-paste):
# 1. Có MCP nhưng không skill → hỏi Claude "query users table" → nó SELECT * không LIMIT (ngốn context).
# 2. Thêm skill db-query (mục 5) → hỏi lại → nó SELECT ... LIMIT 100 + chỉ hiện 20 rows.
# Kỳ vọng: có skill output gọn + an toàn hơn hẳn. Đây là lý do "cặp bài trùng".
```

---

## 6. Prune guide — giữ MCP khỏe

**Nôm na 1 câu:** prune là *dọn tủ lạnh* định kỳ — món nào 2 tuần không ai ăn thì bỏ, kẻo chật tủ + đồ thiu lây đồ tươi (tools nhiễu làm Claude chọn sai).

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

## 7. Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật | Ai cần nhớ |
|---|---|---|
| "Cài càng nhiều MCP càng mạnh" | Quá ~10 tools visible → Claude chọn sai/bỏ sót. Mạnh = 3–6 servers dùng thật + skill kèm. | Mọi dev mới setup |
| "MCP thay được Skill" | MCP cho *tay*, Skill cho *cách dùng*. Không skill → query sai schema, post Slack sai format. | Team lead review setup |
| "stdio lên cloud vẫn chạy" | stdio spawn process local → lên cloud mất. Cloud phải dùng http/sse remote + set lại env. | Ai dùng Web/cloud sessions |
| "Paste token vào .mcp.json rồi commit cho tiện" | Lộ secrets cả git history. Phải `${VAR}` + env ngoài. Lỡ commit → rotate ngay. | Mọi người (security) |
| "Resources/Tools/Prompts là 1" | Tools = hành động (`create_pr`), Resources = đọc (`github://.../issues/123`), Prompts = template (`/mcp__github__review_pr`). Nhầm là gọi sai. | Người mới học MCP |
| "`/mcp` chỉ để xem" | `/mcp` còn reconnect/enable/disable. Disconnected → reconnect trước, đừng vội remove. | Người debug MCP |

```mermaid
flowchart TD
  Q[MCP lỗi?] --> A1[/mcp status gì?]
  A1 -->|disconnected| R1[/mcp reconnect tên]
  A1 -->|unauthorized| R2[Re-OAuth / check header token]
  A1 -->|0 calls 2 tuần| R3[disable 1 tuần rồi remove]
  A1 -->|tools quá nhiều| R4[prune + viết skill gom]
```

**Giải thích:** debug MCP luôn bắt đầu từ `/mcp` (nhìn status), không đoán. 4 nhánh trên cover 90% lỗi thực tế.

---

## 8. Link chéo

- **Bài 02 — Surfaces**: local stdio vs cloud HTTP/SSE; cloud env MCP setup lại.
- **Bài 04 — Slash commands**: `/mcp reconnect/enable/disable`, `/mcp__*__*` prompts động.
- **Bài 05 — Skills**: skill chứa *cách dùng* MCP (schema, format, channel map).
- **Bài 07 — Hooks**: `mcp_tool` hooks type; PreToolUse guard DB prod.
- **Bài 09 — Plugins**: bundle MCP servers vào plugin share team.
- **Bài 10 — Permissions**: MCP tools tuân permission rules; provider cắt web search.
- **Bài 12 — SDK/CI**: MCP trong CI runners + Agent SDK custom tools.
