# FAQ 04 — MCP: Kết Nối & Sự Cố

> Nhóm MCP & Tích hợp · 10 câu hỏi deep-dive · Đọc xong tự add server, giấu secrets, reconnect không hoảng, giữ đúng 3–6 servers

Mỗi câu có giải thích + lệnh/config copy-paste + ví dụ + khi nào áp dụng.

---

## Bảng tổng hợp: vòng đời 1 MCP server

| Bước | Lệnh | Ghi chú |
|---|---|---|
| Add (stdio/sse/http) | `claude mcp add --transport <t> <name> ...` | Chọn scope project/local/user |
| List / xem | `/mcp` | Xem tools count + trạng thái |
| Reconnect | `/mcp reconnect <name>` | Token hết hạn, sleep dậy, OAuth |
| Enable / disable | `/mcp enable\|disable [name\|all]` | Server ít dùng thì disable |
| CLI quản lý | `claude mcp list\|get\|remove\|reset-project-choices` | Dọn approvals cũ |
| Secrets | env vars `${TOKEN}`, không commit | Đỏ nếu hardcode token |
| Prompts | `/mcp__<server>__<prompt>` | Gõ `/` để discover |
| Cloud | Cấu hình lại servers/vars/setup trong environment | Local không tự lên cloud |

---

## 1. Thêm server thế nào? (`add --transport stdio|sse|http`)

**Giải thích.** 3 transports:

- **stdio:** server chạy local (npx/uvx/binary). Nhanh, hợp DB local, CLI tools, browser.
- **sse (legacy) / http (streamable):** server remote (URL + token). Hợp GitHub, tickets, docs SaaS.

**Lệnh copy-paste:**

```bash
# stdio (chạy local):
claude mcp add --transport stdio github -- npx -y @modelcontextprotocol/server-github

# http remote (SaaS):
claude mcp add --transport http linear --url https://mcp.linear.app/mcp --headers "Authorization: Bearer ${LINEAR_TOKEN}"

# sse legacy (nếu vendor chỉ cho sse):
claude mcp add --transport sse docs --url https://docs.internal/sse
```

**Ví dụ:** team dùng Linear + Postgres local → add Linear bằng http (token env), Postgres bằng stdio (socket local). 2 transports khác nhau trong 1 project là bình thường.

**Khi nào áp dụng:** setup repo mới (bước `/mcp`) + mỗi khi cần data ngoài repo.

---

## 2. Scope project / local / user — chọn sao cho đúng?

**Giải thích.** Scope quyết định server lưu ở đâu và ai thấy:

| Scope | Lưu ở | Ai thấy | Dùng khi nào |
|---|---|---|---|
| `--scope project` | `.mcp.json` (commit) | Cả team | Server team dùng chung (tickets, docs) |
| `--scope local` | máy bạn | Chỉ bạn | Token cá nhân, thử nghiệm |
| `--scope user` | `~/.claude/` | Mọi project của bạn | Server cá nhân đa project (search, browser) |

**Lệnh copy-paste:**

```bash
claude mcp add --scope project --transport stdio db -- npx -y @db/mcp
claude mcp add --scope local --transport http staging --url https://staging.internal/mcp
claude mcp add --scope user --transport stdio fetch -- npx -y @fetch/mcp
```

**Ví dụ:** add server test với token cá nhân mà quên `--scope local` → token vào `.mcp.json` commit lên git → lộ. Quy tắc: có secret cá nhân → local/user; share team → project + secrets qua env.

**Khi nào áp dụng:** mỗi lần add — dừng 5 giây hỏi "cái này team thấy được không".

---

## 3. Secrets trong MCP: env vars, không commit token

**Giải thích.** `.mcp.json` commit git → hardcode token trong đó là lộ cho cả thế giới (doctor báo đỏ). Chuẩn: dùng `${VAR}` + export từ shell/env manager.

**Config copy-paste:**

```json
{
  "mcpServers": {
    "github": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"], "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" } },
    "linear": { "transport": "http", "url": "https://mcp.linear.app/mcp", "headers": { "Authorization": "Bearer ${LINEAR_TOKEN}" } }
  }
}
```

```bash
export GITHUB_TOKEN="ghp_xxx"
export LINEAR_TOKEN="lin_xxx"
claude mcp list   # check connected
```

**Ví dụ:** onboard member mới → họ chỉ cần `export 2 VAR` là chạy, không cần xin token của bạn. Đổi token → đổi env, không sửa file.

**Khi nào áp dụng:** luôn. Thêm check CI: `git grep -E 'ghp_|sk-ant_|lin_' -- .mcp.json` phải rỗng.

---

## 4. Xem / sửa connections (`/mcp`, `reconnect`, `enable/disable`, CLI)

**Giải thích.** Bộ lệnh quản lý hàng ngày:

```bash
/mcp                        # list + trạng thái + tools count
/mcp reconnect github       # nối lại 1 server
/mcp disable playwright     # tắt server nặng khi không cần
/mcp enable playwright      # bật lại
/mcp enable all
```

```bash
# CLI (ngoài session):
claude mcp list
claude mcp get github
claude mcp remove old-server
claude mcp reset-project-choices   # xóa approvals project cũ khi đổi policy
```

Lưu ý version: `-p` ≥2.1.205 mới có `/mcp` no-arg in text (headless). Cũ hơn thì dùng CLI `claude mcp list`.

**Ví dụ:** sáng mở máy thấy 2 servers vàng → `/mcp reconnect github` + `/mcp reconnect linear` → xanh lại trong 30s.

**Khi nào áp dụng:** đầu tuần `/mcp` 1 lần; sau sleep/reconnect mạng thì reconnect ngay.

---

## 5. Server disconnected — check gì? (token / URL / OAuth)

**Giải thích.** 3 nguyên nhân theo thứ tự hay gặp:

1. **Token hết hạn / sai env:** `echo ${GITHUB_TOKEN:+set}` — rỗng là mất env (mở terminal mới quên export).
2. **URL sai / server chết:** curl thử URL remote; stdio thì check binary còn không (`npx -y ... --help`).
3. **OAuth chưa xong:** 1 số servers (Google, Notion...) cần hoàn OAuth trong browser — `/mcp` hiện `auth required` → bấm hoàn tất rồi reconnect.

**Lệnh copy-paste:**

```bash
echo ${GITHUB_TOKEN:+token-set}
curl -sI https://mcp.linear.app/mcp | head -3
/mcp reconnect linear
claude mcp get linear   # soi config sai chỗ nào
```

**Ví dụ:** laptop sleep dậy → stdio servers chết (process bị kill) → `/mcp reconnect all` hoặc restart session. Đây là bệnh kinh niên của stdio, không phải config sai.

**Khi nào áp dụng:** disconnected → token → URL → OAuth → reconnect, đừng xóa server vội.

---

## 6. MCP prompts là gì? (`/mcp__<server>__<prompt>`)

**Giải thích.** 1 số servers expose **prompts** (template tác vụ) bên cạnh tools. Chúng hiện thành slash commands động: `/mcp__<server>__<prompt>`. Gõ `/` trong session để discover — không cần nhớ tên.

```bash
# Gõ / rồi tìm:
# /mcp__github__pr-review
# /mcp__linear__create-issue
# /mcp__db__query-template
```

**Ví dụ:** server DB expose prompt `query-template` → gõ `/mcp__db__query-template` ra form query chuẩn team (đúng schema, đúng limit), khỏi viết SQL từ đầu.

**Khi nào áp dụng:** onboard server mới → gõ `/` xem nó có prompts gì, thử từng cái 1 lần.

---

## 7. Khi nào cần MCP vs đọc repo trực tiếp?

**Giải thích.** Quy tắc vàng:

- **Data NGOÀI repo → MCP:** DB, tickets, docs SaaS, browser, API internal, CI logs. Không có MCP là mù.
- **Data ĐÃ TRONG repo → đọc trực tiếp:** code, README, migrations. Thêm MCP vào chỉ tốn maintenance + context.

```text
Cần biết ticket LIN-123 đang nói gì? → MCP Linear (ngoài repo)
Cần biết hàm login viết sao? → Read trực tiếp (trong repo)
```

**Ví dụ sai:** gắn MCP GitHub chỉ để đọc file trong repo đã clone → tốn 2k tokens/session vô ích. Đúng: dùng MCP GitHub để xem PR comments, CI status (ngoài repo).

**Khi nào áp dụng:** trước khi add server mới, hỏi "data này có trong repo không". Có → đừng add.

---

## 8. Bao nhiêu server là đủ? (3–6 thực dùng, >10 tools visible thì loãng)

**Giải thích.** Mỗi server thêm tools vào context. Quá ~10 tools visible → model chọn sai/bỏ sót (xem số liệu FAQ 02). Sweet spot team thực tế:

```text
3–6 servers: GitHub + Playwright + DB + search + tickets (+ docs)
```

Server 30+ tools mà tuần dùng 1 lần → disable平时, enable khi cần.

**Lệnh copy-paste:**

```bash
/mcp                    # đếm servers + tools
/mcp disable heavy-one  # tắt cái ít dùng
/usage                  # xem MCP nào ngốn nhất tuần
```

**Ví dụ:** 12 servers (120 tools) → `/usage` thấy 5 cái chiếm 90% calls → disable 7 cái còn lại → accuracy lên, bill xuống.

**Khi nào áp dụng:** mỗi tháng rà 1 lần. Quy tắc: server 3 tháng không gọi → remove.

---

## 9. Lên cloud mất MCP local — xử lý sao? (`/web-setup` + environment)

**Giải thích.** Đúng: cloud session chỉ thấy repo + cloud environment, KHÔNG thấy MCP local của laptop (stdio chết, env local mất). Phải cấu hình lại servers/vars/setup script trong environment.

**Lệnh copy-paste:**

```bash
# Trong terminal đã login Sub:
/web-setup    # sync token, tạo cloud environment từ repo
# → khai báo lại: MCP servers cần, env vars, setup script (npm ci, migrate...)
claude --cloud "task"   # chạy thử trên cloud
```

**Ví dụ:** local có Postgres stdio → cloud không có → trong environment khai DB URL cloud/staging + add MCP http tương ứng. Đừng mong "teleport lên là chạy y chang".

**Khi nào áp dụng:** trước lần `--cloud` đầu tiên của repo. Checklist: servers → vars → setup script → chạy thử.

---

## 10. Skill vs MCP — khi nào viết skill kèm? (MCP = kết nối, skill = cách dùng đúng)

**Giải thích.** MCP cho bạn *kết nối* (gọi được API). Skill dạy model *dùng đúng* (schema nào, format nào, limit nào, lỗi nào bỏ qua). Team dùng sâu 1 MCP → viết skill kèm, không thì mỗi người gọi 1 kiểu, sai schema liên tục.

**Ví dụ skill `linear-triage` (kèm MCP Linear):**

```markdown
---
name: linear-triage
description: Lấy ticket Linear về tóm tắt + tạo branch đúng chuẩn. Dùng khi bắt đầu task từ ticket.
---
1. Gọi MCP linear lấy issue (chỉ fields: title, desc, labels, priority).
2. Đặt branch `feat/LIN-<id>-<slug>`.
3. Không tự đổi priority khi chưa hỏi.
```

**Khi nào áp dụng:** MCP nào team gọi >5 lần/tuần + hay sai schema → viết skill. MCP dùng 1 lần/tháng → khỏi.

---

## Vẫn lỗi thì sao? (MCP)

1. `/mcp` — xem trạng thái + tools count (dead? auth expired?).
2. `/mcp reconnect <name>` — nối lại (nhất là sau sleep).
3. `claude mcp get <name>` — soi config (URL? env? transport?).
4. `claude doctor` — quét `.mcp.json` hardcode secret, tools thừa.
5. `/debug` — session vẫn lạ → chẩn đoán; `/bug` nếu nghi lỗi core.

```bash
/mcp
/mcp reconnect github
claude mcp get github
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/mcp/README.md](../01-huong-dan-su-dung/commands/mcp/README.md) — add/list/reconnect/enable chi tiết
  - [../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md](../01-huong-dan-su-dung/02-cac-be-mat-terminal-ide-web-desktop.md) — dựng cloud environment
  - [../01-huong-dan-su-dung/commands/doctor/README.md](../01-huong-dan-su-dung/commands/doctor/README.md) — quét secret + tools thừa
  - [../01-huong-dan-su-dung/commands/usage/README.md](../01-huong-dan-su-dung/commands/usage/README.md) — MCP nào ngốn nhất
  - [../01-huong-dan-su-dung/commands/debug/README.md](../01-huong-dan-su-dung/commands/debug/README.md) — chẩn đoán khi reconnect hoài không được
- Bài tổng quan:
  - [../01-huong-dan-su-dung/08-mcp-ket-noi-cong-cu-ngoai.md](../01-huong-dan-su-dung/08-mcp-ket-noi-cong-cu-ngoai.md) — transports + scopes + secrets
  - [../01-huong-dan-su-dung/05-skills-custom-commands.md](../01-huong-dan-su-dung/05-skills-custom-commands.md) — viết skill kèm MCP
  - [../02-tips-thuc-chien/07-thiet-ke-skills.md](../02-tips-thuc-chien/07-thiet-ke-skills.md) — skill cho MCP dùng sâu
- FAQ liên quan: [FAQ 02](02-model-context-token.md) (tools visible), [FAQ 06](06-skills-commands-claude-md.md) (skill kèm), [FAQ 10](10-ci-sdk-routines-web.md) (cloud environment).

> Mẹo 1 dòng: _secrets qua env, server ít dùng thì disable, và lên cloud là cấu hình lại từ đầu._
