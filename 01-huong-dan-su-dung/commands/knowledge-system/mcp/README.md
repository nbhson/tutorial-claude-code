# /mcp — Kết nối công cụ ngoài: cho Claude dùng database, API, browser, GitHub

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có nếu cấu hình ẩu (OAuth/token lọt vào file commit git; server độc hại đọc file local; auto-allow MCP tools nguy hiểm)

`/mcp` mở trung tâm quản lý MCP (Model Context Protocol): kết nối Claude Code với thế giới ngoài — database, GitHub, Slack, browser, Figma... MCP server phơi ra `tools` (hàm Claude gọi được), `resources` (dữ liệu đọc) và `prompts` (mẫu việc). Hiểu `/mcp` là hiểu cách "cắm thêm tay" cho Claude.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/mcp` | _(không có)_ | Mở UI: danh sách server + trạng thái + enable/disable |
| `/mcp add <tên> <lệnh>` | tên + command/URL | Thêm server mới (stdio hoặc SSE/HTTP) |
| `/mcp remove <tên>` | tên | Xoá server |
| `/mcp show <tên>` | tên | Xem chi tiết tools/resources của server |
| `/mcp reconnect <tên>` | tên | Ngắt + nối lại (khi treo) |
| `/mcp logs <tên>` | tên | Xem log server (debug) |
| File config | `.mcp.json` / `~/.claude.json` | Khai báo server bằng JSON (commit hoặc local) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI quản lý
/mcp
```

```bash
# Dạng 2: thêm server local (stdio) — Postgres
/mcp add db -- npx -y @bytebase/dbhub --dsn "postgresql://user:pass@localhost:5432/mydb"
```

```bash
# Dạng 3: thêm server remote (SSE/HTTP) — GitHub
/mcp add github --url https://api.githubcopilot.com/mcp -H "Authorization: Bearer TOKEN"
```

```bash
# Dạng 4: khai báo bằng file .mcp.json (copy-paste, commit cho team)
```

```json
{
  "mcpServers": {
    "db": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub"],
      "env": { "DSN": "${DB_DSN}" }
    },
    "github": {
      "url": "https://api.githubcopilot.com/mcp",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

```bash
# Dạng 5: reconnect khi treo
/mcp reconnect db
```

```bash
# Dạng 6: xem tools của 1 server
/mcp show db
# → tools: query, list_tables, describe_table...
```

---

## Cách nó hoạt động

### Cơ chế sâu: transports / scopes / reconnect

1. **2 transports (cách Claude nói chuyện với server):**
   - `stdio` (local): Claude spawn 1 process trên máy bạn (`npx ...`, `uvx ...`, binary). Nói qua stdin/stdout JSON-RPC. Nhanh, không cần mạng, nhưng tốn RAM/CPU máy bạn và chạy code trên máy bạn (rủi ro nếu package độc).
   - `SSE / Streamable HTTP` (remote): Claude gọi HTTPS tới server xa (GitHub, Linear...). Không tốn máy bạn, nhưng cần mạng + token, và dữ liệu của bạn đi ra ngoài.
2. **3 scopes config (server khai báo ở đâu):**
   - `Project` (`.mcp.json` ở root, commit git): team cùng dùng. KHÔNG ghi secret trực tiếp — dùng `${ENV_VAR}`.
   - `User` (`~/.claude.json` hoặc `~/.claude/.mcp.json`): riêng bạn, mọi repo. Token cá nhân để đây.
   - `Local` (`.claude/.mcp.local.json`, gitignored): riêng repo + riêng máy. Hợp cho DSN dev local.
   - Thứ tự: Local đè User đè Project khi trùng tên server.
3. **Server phơi ra 3 thứ:**
   - `tools`: hàm gọi được — VD `query(sql)`, `create_issue(title, body)`. Hiện trong danh sách tools của model như `mcp__db__query`. Muốn cấm 1 tool thì deny `mcp__db__*` trong permissions.
   - `resources`: dữ liệu đọc — VD `schema://tables`. Model tự kéo khi cần.
   - `prompts`: template — VD `/db:analyze` (nếu server định nghĩa). Gõ `/` sẽ thấy thêm slash command từ MCP.
4. **Vòng đời kết nối:**
   - Session start → đọc config 3 scopes → spawn/connect từng server → handshake (đổi tên tools) → `connected` (xanh).
   - Server sập giữa chừng → tool call báo `MCP error` → `/mcp reconnect <tên>` (ngắt + nối lại, không cần restart session).
   - Thêm server mới giữa session → `/mcp` add xong dùng ngay, không cần restart (từ v2.x).
5. **Permissions với MCP tools:**
   - Tool MCP đi qua gate permissions như tool thường. Tên dạng `mcp__<server>__<tool>` — VD `mcp__db__query`.
   - Pattern chuẩn: `allow: ["mcp__db__describe_table", "mcp__github__get_*"]` (đọc), `ask: ["mcp__db__query"]` (ghi DB phải hỏi).
   - KHÔNG `allow: ["mcp__*"]` — 1 server độc là mở toang.
6. **OAuth flow (server remote xịn):**
   - Server hỗ trợ OAuth (GitHub, Google...): `/mcp add` → mở browser → bạn login → token lưu local (không vào file commit).
   - Token hết hạn → status vàng `auth expired` → `/mcp reconnect` để login lại.
7. **Reconnect và log:**
   - `/mcp reconnect <tên>`: kill process cũ (stdio) hoặc mở connection mới (HTTP), handshake lại.
   - `/mcp logs <tên>`: xem stderr của server — chỗ đầu tiên nhìn khi tool MCP báo lỗi lạ.

### Sơ đồ kết nối

```text
Session start
  ├─ đọc .mcp.json (project) + ~/.claude.json (user) + .local (máy)
  ├─ stdio: spawn [npx dbhub] ──→ handshake ──→ tools mcp__db__*
  ├─ HTTP:  connect github.com/mcp (Bearer TOKEN) ──→ tools mcp__github__*
  └─ stdio: spawn [playwright] ──→ tools mcp__browser__*
       ↓
Model thấy thêm ~20 tools mới (ghi rõ server nào trong tên)
       ↓
Tool call mcp__db__query đi qua permissions gate (allow/ask/deny như thường)
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Chạy ở đâu? | Dữ liệu đi đâu? | Dùng khi nào? |
|---|---|---|---|
| MCP stdio | Máy bạn (process) | Ở local | DB local, file, browser tự động |
| MCP HTTP | Server xa (cloud) | Ra ngoài (cần token) | GitHub, Slack, Linear, Figma |
| Skill | Trong Claude (prompt) | Không thêm tool mới | Quy trình nhiều bước bằng tools sẵn có |
| Hook | Máy bạn (script) | Ở local | Việc máy làm được, không cần AI |
| Plugin | Bundle (skill+agent+hook+MCP) | Tùy thành phần | Cài 1 lần được cả bộ |

> Quy tắc ngón tay cái:
>
> - **Cần TOOL mới (query DB, tạo issue) → MCP. Cần QUY TRÌNH mới → skill. Cần cả bộ → plugin.**

---

## Ví dụ thực tế

### Kịch bản 1: Cắm Postgres local, hỏi DB bằng tiếng Việt (stdio)

```bash
# Bước 1: thêm server (DSN qua env, không hardcode pass)
/mcp add db -- npx -y @bytebase/dbhub --dsn "${DB_DSN}"

# Bước 2: kiểm tra tools
/mcp show db
# → query, list_tables, describe_table

# Bước 3: dùng ngay trong chat
# "Liệt kê 10 bảng lớn nhất và số dòng mỗi bảng"
# → model gọi mcp__db__list_tables rồi mcp__db__query, trả về bảng gọn

# Bước 4: khóa phanh (chỉ đọc, ghi phải hỏi) — .claude/settings.json:
```

```json
{
  "permissions": {
    "allow": ["mcp__db__list_tables", "mcp__db__describe_table"],
    "ask": ["mcp__db__query"]
  }
}
```

> Kết quả: hỏi DB không cần mở psql. `SELECT` hỏi 1 lần rồi chạy; `DROP` hiện picker cho bạn chặn.

### Kịch bản 2: Cắm GitHub remote, tạo issue từ chat (HTTP + OAuth)

```bash
# Bước 1: thêm (mở browser login OAuth, token lưu local)
/mcp add github --url https://api.githubcopilot.com/mcp

# Bước 2: dùng
# "Tạo issue 'Login vỡ khi email có dấu +' với labels bug, gán cho tôi"
# → model gọi mcp__github__create_issue

# File .mcp.json commit cho team (không chứa token):
```

```json
{
  "mcpServers": {
    "github": { "url": "https://api.githubcopilot.com/mcp" }
  }
}
```

> Kết quả: team clone về là thấy server github, mỗi người login OAuth riêng. Token không lọt vào git.

### Kịch bản 3: Cứu server treo giữa session (reconnect + logs)

Triệu chứng: `mcp__db__query` báo `MCP error: connection closed` sau khi laptop sleep.

```bash
# Bước 1: xem log (biết bệnh gì)
/mcp logs db
# → "process exited (SIGTERM)" — do sleep kill process stdio

# Bước 2: nối lại (không cần restart session)
/mcp reconnect db
# → status xanh, tools lại gọi được

# Mẹo: laptop hay sleep thì dùng server HTTP thay vì stdio cho đỡ rớt,
# hoặc viết hook SessionStart tự reconnect.
```

### Kịch bản 4: Playwright — cho Claude tự mở browser test UI

```bash
/mcp add playwright -- npx -y @playwright/mcp@latest

# Trong chat:
# "Mở http://localhost:3000/login, nhập sai pass, chụp màn hình lỗi"
# → model gọi mcp__browser__navigate, mcp__browser__fill, mcp__browser__screenshot
```

> Kết quả: test UI bằng lời nói, có ảnh chụp làm bằng chứng. Nhớ deny domain lạ để nó không lượn ra internet.

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (OAuth / token / server độc)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Hardcode token vào `.mcp.json` rồi commit | CỰC NGUY HIỂM: token public, ai cũng dùng được | Dùng `${ENV_VAR}`; token thật chỉ ở env/user config local |
| Cài MCP server lạ (package ít star) | Server đọc `~/.ssh`, `.env` rồi gửi ra ngoài | Chỉ cài nguồn uy tín; đọc README + permissions nó xin; deny file nhạy cảm |
| `allow: ["mcp__*"]` | Mọi tool MCP chạy không hỏi, gồm cả ghi DB/xoá issue | Allow từng tool đọc; `ask` cho tool ghi |
| MCP browser mở URL lạ | Lộ session/cookie, SSRF vào mạng nội bộ | Giới hạn domain trong config playwright; không login tài khoản thật khi test |
| Query DB prod qua MCP | `DELETE` không WHERE bay màu dữ liệu thật | Chỉ cắm DB dev/staging; prod thì `ask` + review SQL trước khi Yes |

### Tốn token?

- Mỗi server thêm ~200-500 token mô tả tools vào context (cố định mỗi session). 5 server ≈ 1-2k token.
- Server nhiều tools (30+) thì tốn hơn — disable server không dùng trong `/mcp` UI thay vì để đó.
- Tool result (VD 1000 dòng DB) mới là tốn thật — dặn model `LIMIT 10` trước.

### Version / provider

- `/mcp` UI + stdio: mọi bản v1.x+. SSE/HTTP remote: v1.0.50+.
- OAuth tự mở browser: v2.x. Bản cũ phải paste token tay.
- Bedrock/Vertex: MCP stdio vẫn chạy local bình thường; MCP HTTP ra ngoài chịu thêm policy mạng của cloud.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/mcp` + `/permissions` | Phanh cho tools mới | Allow đọc, ask ghi, deny server lạ |
| `/mcp` + `/agents` | Subagent dùng MCP tools | Con query DB, mẹ gộp kết quả |
| `/mcp` + `/hooks` | Tự reconnect khi sleep | Hook SessionStart chạy reconnect |
| `/mcp` + `/plugin` | Plugin bundle sẵn MCP config | Cài plugin là có server + skill kèm |
| `/mcp` + `/verify` | Verify đọc DB/API thật | Test gọi DB staging qua MCP |

Workflow chuẩn "thêm server mới cho team":

```bash
# 1. Thử local trước
/mcp add db -- npx -y @bytebase/dbhub --dsn "${DB_DSN}"

# 2. Chạy ngon → ghi vào .mcp.json (dùng ${ENV}, không hardcode)
/mcp show db   # copy tên tools để viết permissions

# 3. Thêm permissions baseline (allow đọc, ask ghi)

# 4. Commit .mcp.json + settings.json, báo team export env tương ứng
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `MCP error: connection closed` sau sleep | Process stdio bị kill | `/mcp reconnect <tên>`; hoặc chuyển sang server HTTP |
| `auth expired` (vàng) | OAuth token hết hạn | `/mcp reconnect` để login lại |
| Thêm server mà model không thấy tools | Sai tên/caấu trúc `.mcp.json`, hoặc chưa handshake | `/mcp` xem status đỏ → `/mcp logs` đọc lỗi; validate JSON; thử lệnh `npx ...` tay ngoài terminal |
| `npx` treo khi cài lần đầu | Mạng chậm, package lớn | Chạy `npx -y <package>` tay 1 lần cho cache, rồi add lại |
| Tool MCP bị `permission denied` | Chưa allow `mcp__<server>__*` | Thêm vào allow (đọc) / ask (ghi) trong settings |
| Server đọc được file nhạy cảm | Server xin quyền rộng + không deny | Deny `Read(.env)`, `Read(~/.ssh/*)` trong permissions; gỡ server lạ |
| Hai config trùng tên server | Local đè Project gây nhầm (dev trỏ nhầm prod) | Đặt tên rõ (`db-dev`, `db-staging`); `/mcp` kiểm tra DSN đang dùng |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../permissions/README.md](../../model-mode/permissions/README.md) — phanh allow/ask/deny cho `mcp__*`
  - [../plugin/README.md](../../knowledge-system/plugin/README.md) — plugin bundle MCP + skill + agent
  - [../hooks/README.md](../../knowledge-system/hooks/README.md) — auto-reconnect bằng hook
  - [../agents/README.md](../../knowledge-system/agents/README.md) — subagent gọi MCP tools
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — doctor có audit MCP config không
  - [../verify/README.md](../../code-repo/verify/README.md) — verify qua DB/API thật
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — MCP tools có tuân rules không (có)
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — skill gọi MCP tools
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — chia việc MCP cho đàn con
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — hook SessionStart cho MCP
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — bài gốc: danh sách server nên cài
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — marketplace có MCP kèm

> Mẹo 1 dòng: _secret vào env không vào git, đọc thì allow — ghi thì ask, server lạ thì đừng cài._
