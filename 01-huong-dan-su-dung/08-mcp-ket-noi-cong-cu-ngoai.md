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

Mục này trả lời câu hỏi "MCP là gì, bỏ công cài để được gì". Đọc để hiểu đúng mô hình — hiểu sai mô hình là nguyên nhân gốc của hầu hết lỗi MCP về sau.

**Nôm na 1 câu:** MCP là *cổng USB chuẩn* cho AI — cắm GitHub/DB/Browser vào là Claude dùng được ngay, khỏi viết glue-code riêng cho từng tool: 1 chuẩn `tools/list` + `tools/call`, server nào cũng nói cùng thứ tiếng. **Analogie bồi bàn gọi bếp:** bạn gọi bồi bàn (Claude Code), bồi bàn ghi order theo mẫu chuẩn rồi chuyển tới bếp (MCP Server: bếp GitHub, bếp Postgres, bếp Browser). Bếp nấu xong (gọi API/DB thật) trả món ra, bồi bàn trình bày đẹp lên bàn — bạn không bao giờ vào bếp hay paste token vào chat.

> 📄 **Code ví dụ:** [`examples/01-1-mcp-la-gi-va-vi-sao-can.sh`](examples/01-1-mcp-la-gi-va-vi-sao-can.sh)

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

> **Cách đọc bảng này:** mỗi dòng là một "giác quan" của Claude: tay (Tools) để hành động, mắt (Resources) để đọc, công thức (Prompts) để chạy workflow chuẩn — đọc cột "Là gì" trước, cột "Claude dùng khi nào" để chọn đúng thứ khi cần.

> 📄 **Code ví dụ:** [`examples/02-1-1-tools-resources-prompts-3-khai-niem.json`](examples/02-1-1-tools-resources-prompts-3-khai-niem.json)

> **Công thức nhớ:** **MCP = reach (vươn tay), Skill = cách dùng reach đó cho đúng** (skill chứa schema DB, quy ước repo...). Quản lý hàng ngày bằng `/mcp`, thêm server bằng `claude mcp add`.

> **Tóm gọn 1 câu:** MCP là cổng USB chuẩn cho AI — Tools để làm, Resources để đọc, Prompts để chạy recipe của server; và có tay rồi thì cần skill để cầm nắm khéo.

---

## 2. Thêm server: 3 transports + OAuth từ terminal

Mục này nói về cách "cắm dây" cho server: 3 loại dây (transport) và cách đăng nhập OAuth từ terminal. Đọc để chọn đúng loại dây cho từng server — chọn sai là setup xong chạy chậm hoặc lên cloud mất.

**Nôm na 1 câu:** `claude mcp add` là *cắm dây* — chọn loại dây (stdio/sse/http) + chọn ổ cắm (scope) rồi cắm server vào. stdio = xe nhà trong gara (nhanh, luôn sẵn, nhưng lên cloud là mất); sse/http = taxi (đi đâu cũng gọi được, cần mạng + token).

1. **stdio:** Claude spawn 1 process trên máy bạn (`npx ...`) — nhanh nhất, không cần auth phức tạp. *Dùng cho:* github/playwright/postgres dev trên laptop.
2. **sse:** kết nối streaming giữ lâu tới server remote. *Dùng cho:* API nội bộ realtime, cần push.
3. **http:** gọi REST từng request, OAuth dễ nhất. *Dùng cho:* Notion/Linear/Slack (mỗi người token riêng, scope `user`).

> **Tóm gọn 1 câu:** stdio cho server sống trên máy (nhanh), sse/http cho server remote (đi đâu cũng tới) — và credentials luôn qua env, không bao giờ ghi cứng vào file commit.

> 📄 **Code ví dụ:** [`examples/03-2-them-server-3-transports-oauth-tu-terminal.sh`](examples/03-2-them-server-3-transports-oauth-tu-terminal.sh)

Scopes: `--scope project` (ghi `.mcp.json`, share team) / `local` / `user` (`~/.claude.json`) — chi tiết mục 4. Credentials **qua env vars, không commit**: remote server khai `${INTERNAL_API_URL}`, `${INTERNAL_API_TOKEN}` trong `.mcp.json` (xem ví dụ mục 4.1), giá thật để ở shell/cloud env.

Quản lý: `/mcp` (list/status), `/mcp reconnect <name>`, `enable/disable [name|all]`; CLI: `claude mcp list|get <name>|remove <name>|reset-project-choices|serve` (`serve` = biến chính Claude Code thành 1 MCP stdio server). Non-interactive `-p` (≥2.1.205): `/mcp` no-arg in text summary thay vì mở dialog.

### 2.1. OAuth từ terminal: `claude mcp login` / `claude mcp logout` (mới 2026)

Trước đây OAuth với MCP remote server phải mở session interactive và authorize qua `/mcp`. Từ Week 26/2026 có 2 lệnh terminal trực tiếp:

> 📄 **Code ví dụ:** [`examples/04-2-1-oauth-tu-terminal-claude-mcp-login.sh`](examples/04-2-1-oauth-tu-terminal-claude-mcp-login.sh)

- Tiện cho setup script/CI: đăng nhập trước bằng `login`, rồi session non-interactive `-p` dùng được ngay mà không vướng màn hình authorize. Kiểm tra trạng thái auth vẫn bằng `claude mcp list` (cột connected/needs-auth) hoặc `claude mcp get <name>`.

> **Tóm gọn 1 câu:** `claude mcp login/logout` đưa OAuth ra terminal — đăng nhập một phát cho CI và session `-p` chạy tiếp không dừng chờ bấm authorize.

### 2.2. Protocol negotiation 2026-07-28 + mô tả tool nới rộng

(06/10/2026, Claude Code ≥2.1.292) MCP mặc định negotiate protocol `2026-07-28` — tương tác MCP mới hơn với mọi provider, áp cho **cả** connector claude.ai lẫn MCP local `stdio` và remote (`sse`/`http`). Muốn quay lại giao thức cũ: đặt biến môi trường `MCP_PROTOCOL_NEGOTIATION=legacy`.

> Mô tả tool MCP được nới: mặc định 2.048 → 4.096 ký tự, và tới 16.384 ký tự qua tool search (≥2.1.295). Tool được mô tả đầy đủ hơn → model chọn đúng tool hơn, nhất là khi có nhiều server.

---

## 3. Setup từng server chi tiết (GitHub/Playwright/Postgres/Notion)

Mục này là "cẩm nang 4 bếp": lệnh cài đặt cụ thể cho 4 server dùng nhiều nhất, kèm quy tắc an toàn cho DB. Đọc đúng phần server bạn cần, cài GitHub trước nếu chưa chọn được gì.

### 3.1. GitHub (impact cao nhất — cài đầu tiên)

> 📄 **Code ví dụ:** [`examples/05-3-1-github-impact-cao-nhat-cai-au.sh`](examples/05-3-1-github-impact-cao-nhat-cai-au.sh)

Kết quả trong `.mcp.json`: `{ "github": { "command": "npx", "args": ["@anthropic/mcp-github@latest"] } }` — commit được, không secrets vì dùng gh token máy.

### 3.2. Playwright (browser automation — Claude NHÌN UI)

> 📄 **Code ví dụ:** [`examples/06-3-2-playwright-browser-automation-claude-nhin-ui.sh`](examples/06-3-2-playwright-browser-automation-claude-nhin-ui.sh)

> Playwright local stdio KHÔNG theo lên cloud ([bài 02](./02-cac-be-mat-terminal-ide-web-desktop.md)) — cloud cần browser MCP remote hoặc `/verify` flow khác.

### 3.3. Postgres (đọc schema + query — KHÔNG commit password)

> 📄 **Code ví dụ:** [`examples/07-3-3-postgres-oc-schema-query-khong-commit.sh`](examples/07-3-3-postgres-oc-schema-query-khong-commit.sh)

> 📄 **Code ví dụ:** [`examples/08-3-3-postgres-oc-schema-query-khong-commit.json`](examples/08-3-3-postgres-oc-schema-query-khong-commit.json)

Quy tắc an toàn DB: dev DB cho read + (cân nhắc) write qua skill add-table; prod DB read-only, PreToolUse hook block mọi query chứa DELETE/DROP/UPDATE không WHERE; không bao giờ paste connection string prod vào chat/`.mcp.json` committed.

### 3.4. Notion (docs/tickets — remote HTTP + OAuth)

> 📄 **Code ví dụ:** [`examples/09-3-4-notion-docs-tickets-remote-http-oauth.sh`](examples/09-3-4-notion-docs-tickets-remote-http-oauth.sh)

> **Tóm gọn 1 câu:** Cài GitHub trước vì impact cao nhất, Playwright để Claude "có mắt", Postgres nhớ quy tắc prod read-only + hook chặn DELETE/DROP — 4 server này phủ ~90% nhu cầu.

---

## 4. Scope precedence — ai thắng khi trùng tên?

Mục này nói về "quyền sở hữu" của từng server: sống ở file nào, commit được không, và ai thắng khi 2 scope đặt cùng tên. Đọc để đặt server đúng tầng ngay từ đầu, khỏi đổ về sau.

**Nôm na 1 câu:** scope trả lời "server này của ai, sống ở đâu, có lên cloud không?". Thứ tự thắng khi trùng tên: `project` < `local` < `user`.

| Scope | File | Commit? | Khi nào |
|---|---|---|---|
| `project` | `.mcp.json` (repo root) | Có (không secrets) | Servers team dùng chung (github, fetch) |
| `local` | project-local (machine) | Không | Credentials máy dev (postgres dev) |
| `user` | `~/.claude.json` | Không | Personal (notion, linear cá nhân) |

> **Cách đọc bảng này:** mỗi dòng là một tầng lưu trữ; cột "Commit?" quyết định thứ theo team hay ở lại máy — server dùng chung cả team thì `project`, credentials cá nhân thì `local`/`user`.

- Cùng tên server ở 2 scopes → scope cụ thể hơn (user > local > project) thắng. `claude mcp reset-project-choices` → reset approvals đã chọn cho project servers.
- Cloud sessions: chỉ thấy project scope committed + cloud env (local/user ở laptop không bay lên — [bài 02](./02-cac-be-mat-terminal-ide-web-desktop.md)).

> 📄 **Code ví dụ:** [`examples/10-4-scope-precedence-ai-thang-khi-trung-ten.sh`](examples/10-4-scope-precedence-ai-thang-khi-trung-ten.sh)

### 4.1. Ví dụ `.mcp.json` team chuẩn (commit được)

> 📄 **Code ví dụ:** [`examples/11-4-1-vi-du-mcp-json-team-chuan.json`](examples/11-4-1-vi-du-mcp-json-team-chuan.json)

> **Tóm gọn 1 câu:** Ba tầng scope như ba ngăn tủ: `project` là ngăn chung cả nhà (commit), `local` là ngăn riêng của máy, `user` là ngăn túi áo cá nhân — cùng tên thì ngăn cao hơn thắng.

---

## 5. Skill + MCP cặp bài trùng

Mục này nói về cặp đôi hoàn hảo của MCP: server cho "tay", skill cho "cách cầm nắm". Đọc để hiểu vì sao mỗi server team dùng sâu nên kèm 1 skill.

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

> **Tóm gọn 1 câu:** MCP cho khả năng, skill cho kỷ luật — không skill kèm thì Claude có tay nhưng cầm nắm theo cảm tính.

---

## 6. Prune guide — giữ MCP khỏe

Mục này nói về vệ sinh định kỳ: giữ bao nhiêu server, dọn cái gì, mỗi bao lâu. Đọc khi MCP list phình ra và Claude bắt đầu chọn nhầm tool.

**Nôm na 1 câu:** prune là *dọn tủ lạnh* định kỳ — món nào 2 tuần không ai ăn thì bỏ, kẻo tools nhiễu làm Claude chọn sai.

### 6.1. Day-one servers (sweet spot 3–6, đừng quá ~10 tools visible)

| Server | Để làm gì | Khi thêm | Khi prune |
|---|---|---|---|
| GitHub | PRs, issues, code search, branches cross-repo | Gần như luôn — impact cao nhất | Không bao giờ (trừ repo không dùng GitHub) |
| Playwright | Browser automation — Claude **nhìn** UI | Web app cần test UI | App không UI / đã có E2E khác |
| Postgres/MySQL/MongoDB | Đọc schema, chạy query | App có DB thật | Project docs-only, không DB |
| Fetch / Brave Search | Web grounding live | Cross-stack, tra docs | Provider đã có web search built-in |
| Linear / Notion / Jira / Slack | Tickets, docs, messages | Team sống trong đó | Team không dùng / đã migrate tool |

> **Cách đọc bảng này:** mỗi dòng là một server ứng viên "day-one"; cột "Khi thêm" là điều kiện nên cài, cột "Khi prune" là điều kiện nên bỏ — dùng như checklist nhập hàng và xuất hàng của tủ lạnh.

> Quá ~10 MCP tools visible → accuracy chọn tool giảm (gọi sai/bỏ sót). Đây là **ngưỡng thực nghiệm cộng đồng** (servers thực dùng 3–6), không phải số chính thức của Anthropic. Xem breakdown usage per-MCP bằng `/usage` (từ Week 21/2026, breakdown theo skill/subagent/plugin/MCP).

### 6.2. Prune flow định kỳ (2 tuần/lần, 10 phút)

> 📄 **Code ví dụ:** [`examples/12-6-2-prune-flow-inh-ky-2-tuan.sh`](examples/12-6-2-prune-flow-inh-ky-2-tuan.sh)

### 6.3. MCP tool hooks (nâng cao)

Hooks type `mcp_tool`: gọi tool của server đã connect ngay trong hook (vd: PostToolUse Edit → `mcp_tool linear.create_issue` log change cần review). Xem [bài 07 — Hooks](./07-hooks-tu-dong-hoa.md) cho schema. Production: test kỹ — hook gọi MCP có latency, fail thì có retry?

### 6.4. Checklist MCP khỏe

Trước khi coi hệ thống MCP là "khỏe", tick đủ 5 ô:

- [ ] `claude mcp list` all connected; OAuth xong (`/mcp` hoặc `claude mcp login`).
- [ ] `.mcp.json` commit được, secrets chỉ qua env (grep không ra secrets).
- [ ] Mỗi server sâu có 1 skill hướng dẫn dùng (schema, conventions).
- [ ] Tools visible ≤10, servers 3–6; server 2 tuần không gọi → disable → remove.
- [ ] Cloud sessions: cấu hình lại MCP trong cloud environment (local config không theo lên cloud).

> **Tóm gọn 1 câu:** MCP khỏe = servers ít mà dùng thật (3–6), secrets ở env, mỗi server sâu có skill kèm — như tủ lạnh: ít món nhưng món nào cũng ăn.

---

## 7. Hiểu nhầm thường gặp + debug

Mục này gom 6 tin sai về MCP và quy trình debug 4 nhánh. Đọc khi MCP hành xử khác tưởng tượng — 90% lỗi nằm trong bảng này.

| Hiểu nhầm | Sự thật | Ai cần nhớ |
|---|---|---|
| "Cài càng nhiều MCP càng mạnh" | Quá ~10 tools visible → Claude chọn sai/bỏ sót. Mạnh = 3–6 servers dùng thật + skill kèm. | Mọi dev mới setup |
| "MCP thay được Skill" | MCP cho *tay*, Skill cho *cách dùng*. Không skill → query sai schema, post Slack sai format. | Team lead review setup |
| "stdio lên cloud vẫn chạy" | stdio spawn process local → lên cloud mất. Cloud phải dùng http/sse remote + set lại env. | Ai dùng Web/cloud sessions |
| "Paste token vào .mcp.json rồi commit cho tiện" | Lộ secrets cả git history. Phải `${VAR}` + env ngoài. Lỡ commit → rotate ngay. | Mọi người (security) |
| "Resources/Tools/Prompts là 1" | Tools = hành động, Resources = đọc URI, Prompts = template `/mcp__server__name`. Nhầm là gọi sai. | Người mới học MCP |
| "`/mcp` chỉ để xem" | `/mcp` còn reconnect/enable/disable. Disconnected → reconnect trước, đừng vội remove. | Người debug MCP |

> **Cách đọc bảng này:** cột "Ai cần nhớ" là phím tắt chọn dòng — dev mới đọc dòng 1, debug MCP đọc dòng cuối; cột "Sự thật" là phần đúng duy nhất, đừng dừng ở cột "Hiểu nhầm".

```text
MCP lỗi? → /mcp xem status: disconnected → /mcp reconnect <name>; unauthorized → re-OAuth / claude mcp login <name> / check header token; 0 calls 2 tuần → disable 1 tuần rồi remove; tools quá nhiều → prune + viết skill gom.
```

Debug MCP luôn bắt đầu từ `/mcp` (nhìn status), không đoán — 4 nhánh trên cover 90% lỗi thực tế. Thêm server stdio thất bại thường do thiếu binary: chạy tay `npx ... --help` để check; remote: header sai hoặc URL thiếu hậu tố `/mcp`.

> **Tóm gọn 1 câu:** Lỗi MCP đừng đoán — mở `/mcp` nhìn status rồi đi theo 4 nhánh: reconnect, re-OAuth, disable, prune.

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
