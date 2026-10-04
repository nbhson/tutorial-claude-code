# 09 — Plugins & Marketplaces (Đóng Gói Cho Team)

> Bài 09 của series. Đọc xong bạn dùng được plugin manager, và viết được plugin từ zero
> (plugin.json + cấu trúc folder + publish). Thời gian: ~35 phút.

## Mục lục

1. [Plugin là gì — why](#1-plugin-là-gì)
2. [Dùng plugin manager](#2-dùng-plugin-manager)
3. [Khi nào build plugin vs dotfiles?](#3-khi-nào-build-plugin-vs-chỉ-share-dotfiles)
4. [Viết plugin từ zero](#4-viết-plugin-từ-zero-pluginjson--cấu-trúc-folder)
5. [Publish + marketplace](#5-publish--marketplace-share-cho-teamorgcông-khai)
6. [Walkthrough + quyền/trust + pitfalls + bài tập](#6-lưu-ý-quyền--trust)
7. [Link chéo](#7-link-chéo)

---

## 1. Plugin là gì

1 unit cài được, bundle: **skills + hooks + subagents + MCP servers (+ LSP/code-intelligence servers)**
→ thay vì mỗi teammate setup tay 4 thứ, cài 1 phát đồng bộ.

- Skills của plugin **namespaced**: `/my-plugin:review` → nhiều plugin cùng tồn tại.
- Thêm `.claude-plugin/plugin.json` vào folder skill → nó load như plugin tên `@skills-dir`
  (trong project `.claude/skills/` cần accept workspace trust dialog trước).

### 1.1. Vì sao plugin? (why)

`.claude/` commit theo repo giải quyết 1 repo. Team 10 repos + onboarding người mới mỗi tháng →
mỗi repo setup lại skills/hooks/agents/MCP = drift. Plugin giải quyết cross-repo:

```text
Không plugin:  teammate mới → clone 5 repos → mỗi repo /mcp setup tay + copy hooks + hỏi "skill deploy ở đâu?"
Có plugin:     teammate mới → /plugin install acme-standard → 5 repos đều có /acme:deploy, /acme:review, hooks guard, agents.
Update:        bump plugin version 1 nơi → cả team sync (thay vì sửa 5 repos).
```

---

## 2. Dùng plugin manager

```
/plugin   → Discover / Browse / Manage
```

Màn hình Browse/Discover hiện trước: commands, agents, skills, hooks, MCP/LSP servers của plugin —
đọc kỹ trước khi cài (nhất là hooks: nó sẽ chạy code trên máy bạn).

### 2.1. Walkthrough dùng plugin (10 phút)

```text
Bước 1: Trong session gõ /plugin → tab Discover (marketplaces đã add) / Browse (installed).
Bước 2: Chọn plugin (vd security-review) → đọc: skills nào? hooks nào? MCP nào? agents nào?
        → ĐẶC BIỆT đọc hooks (nó chạy shell trên máy bạn) + MCP (nó gọi ra ngoài).
Bước 3: Install → mở session MỚI (plugin load lúc start).
Bước 4: Gõ "/" → thấy /security-review:xxx namespaced. Test 1 skill.
Bước 5: /hooks + /mcp → xác nhận hooks/MCP của plugin đã load.
Bước 6: Không hợp → /plugin → Manage → Disable (test 1 tuần) → Uninstall.
```

```bash
# Aliases (tùy bản):
/plugin    # manager chính
/plugins   # alias
# Trong manager: Discover (tìm mới) / Browse (duyệt installed) / Manage (enable/disable/remove).
```

---

## 3. Khi nào build plugin vs chỉ share dotfiles?

| Tình huống | Chọn | Ví dụ |
|---|---|---|
| 1–2 skills nội bộ, 1 repo | `.claude/skills/` commit thẳng | Skill deploy của 1 project |
| Bộ setup chuẩn (skills+hooks+agents+MCP) dùng nhiều repo | Plugin | `acme-standard` cho 10 repos |
| Share công khai / cross-org | Plugin + marketplace | Plugin open-source review chuẩn |
| Chỉ personal, không share | `~/.claude/skills/` | Preferences cá nhân |

Ví dụ plugin hay gặp: `security-review` (skill review + subagent + hook guard), code-intelligence
plugins cho typed languages (symbol navigation + error detection sau edit), frontend-polish
(vd Impeccable: `/audit /polish /distill /critique...` chống "AI slop").

---

## 4. Viết plugin từ zero (plugin.json + cấu trúc folder)

### 4.1. Cấu trúc folder chuẩn

```text
acme-standard/                  # repo plugin (git riêng, version riêng)
  .claude-plugin/
    plugin.json                 # BẮT BUỘC: manifest
    marketplace.json            # (optional) nếu publish marketplace
  skills/
    deploy/SKILL.md             # → /acme-standard:deploy (namespaced)
    review-pr/SKILL.md
  agents/
    explorer.md                 # subagents kèm
    security-reviewer.md
  hooks/
    block-main-push.sh          # scripts hooks
    lint-on-write.sh
  .mcp.json                     # MCP servers kèm (dùng env placeholders!)
  README.md                     #install + usage + trust notes
```

### 4.2. `plugin.json` mẫu hoàn chỉnh (copy-paste)

```json
{
  "name": "acme-standard",
  "version": "1.0.0",
  "description": "Standard workflow cho team Acme: deploy, review-pr, guards, agents.",
  "author": "Acme Platform Team <platform@acme.example>",
  "license": "MIT",
  "skills": ["skills/deploy", "skills/review-pr"],
  "agents": ["agents/explorer.md", "agents/security-reviewer.md"],
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "type": "command", "command": "${CLAUDE_PLUGIN_DIR}/hooks/block-main-push.sh" }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "type": "command", "command": "${CLAUDE_PLUGIN_DIR}/hooks/lint-on-write.sh" }
    ]
  },
  "mcpServers": {
    "github": { "command": "npx", "args": ["@anthropic/mcp-github@latest"] },
    "fetch": { "command": "npx", "args": ["@modelcontextprotocol/server-fetch@latest"] }
  },
  "lspServers": {
    "typescript": { "command": "typescript-language-server", "args": ["--stdio"] }
  }
}
```

> `${CLAUDE_PLUGIN_DIR}` = folder plugin (tương tự `${CLAUDE_SKILL_DIR}` cho skill).
> Đừng hardcode path tuyệt đối — plugin cài ở máy khác path khác.

### 4.3. Từng thành phần (viết thế nào cho đúng)

```markdown
# skills/deploy/SKILL.md — như skill thường (bài 05), nhưng nhớ namespaced:
# Gọi: /acme-standard:deploy (không phải /deploy).
# description vẫn quyết định auto-trigger — viết đầy đủ từ khóa.

# agents/explorer.md — như agent thường (bài 06), nhưng BỊ BỎ QUA:
# hooks/mcpServers/permissionMode trong frontmatter (copy ra .claude/agents/ nếu cần).

# hooks/*.sh — như hook thường (bài 07), dùng ${CLAUDE_PLUGIN_DIR} cho path.
# .mcp.json — env placeholders ${VAR}, KHÔNG secrets (bài 08).
```

```bash
# Khung khởi tạo plugin từ zero (copy-paste):
mkdir -p acme-standard/{.claude-plugin,skills/{deploy,review-pr},agents,hooks}
cat > acme-standard/.claude-plugin/plugin.json <<'EOF'
{
  "name": "acme-standard",
  "version": "0.1.0",
  "description": "Standard workflow team Acme.",
  "skills": ["skills/deploy", "skills/review-pr"]
}
EOF
# Rồi copy SKILL.md từ bài 05 vào skills/*/, hooks từ bài 07 vào hooks/.
# Test local: /plugin → Manage → Install from path ./acme-standard
```

---

## 5. Publish + marketplace (share cho team/org/công khai)

### 5.1. 3 cấp share (chọn theo nhu cầu)

| Cấp | Cách | Khi nào |
|---|---|---|
| **Path local** | `/plugin install ./acme-standard` | Dev/test plugin đang viết |
| **Git URL** | `/plugin install git@github.com:acme/claude-plugins.git` | Team nội bộ (private repo) |
| **Marketplace** | Add marketplace URL → Discover → Install | Org nhiều plugins / công khai |

```bash
# Team nội bộ (phổ biến nhất) — 1 repo plugins, mỗi folder 1 plugin:
# github.com/acme/claude-plugins/
#   acme-standard/.claude-plugin/plugin.json
#   security-review/.claude-plugin/plugin.json
# Teammate cài:
# /plugin → Add marketplace → git@github.com:acme/claude-plugins.git → Install acme-standard
```

```json
// .claude-plugin/marketplace.json (repo marketplace, liệt kê plugins):
{
  "name": "acme-marketplace",
  "plugins": [
    { "name": "acme-standard", "path": "./acme-standard", "version": "1.0.0" },
    { "name": "security-review", "path": "./security-review", "version": "2.1.0" }
  ]
}
```

### 5.2. Versioning + update flow

```text
1. Bump version trong plugin.json (semver: breaking → major).
2. CHANGELOG entry: skills nào thêm/sửa? hooks nào đổi hành vi? (hooks đổi = highlight đỏ).
3. Tag git (vd acme-standard-v1.1.0).
4. Thông báo team: /plugin → Manage → Update. Teammate mở session mới để load bản mới.
5. Breaking hooks change → pin version cũ cho repos chưa sẵn sàng (đừng force update).
```

---

## 6. Lưu ý quyền + trust

- Plugin subagents **bị bỏ qua** `hooks`/`mcpServers`/`permissionMode` → cần thì copy agent ra
  `.claude/agents/` hoặc `~/.claude/agents/`.
- Hooks của plugin chạy trên máy bạn → chỉ cài nguồn tin cậy, review `plugin.json` + scripts.
- Org có thể quản lý qua managed/server policy settings (Team/Enterprise — bài 10).

### 6.1. Checklist review plugin trước khi cài (copy-paste)

- [ ] Đọc `plugin.json`: skills/agents/hooks/MCP/LSP nào sẽ load?
- [ ] Đọc từng hook `.sh`: có `rm -rf`? có `curl | bash`? có exfiltrate (`curl` gửi file đi)?
- [ ] MCP servers: có server lạ gọi URL ngoài? Credentials qua env?
- [ ] Skills: có `allowed-tools` quá rộng? Có dặn làm việc nguy hiểm (deploy prod auto)?
- [ ] Nguồn: marketplace chính thức / org private / cá nhân lạ? (lạ → sandbox test trước)
- [ ] Version pinned? (tránh auto-update breaking giữa sprint)

### 6.2. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Cài plugin lạ, hook xóa file | Không review hooks | Checklist trên; test trong container/sandbox trước |
| 2 plugins cùng tên skill → gọi nhầm | Không namespaced rõ | Luôn gọi `/plugin:skill` đầy đủ, không gọi tắt |
| Plugin agent hooks không chạy | Bị bỏ qua theo thiết kế | Copy agent ra `.claude/agents/` |
| Update plugin giữa sprint gãy workflow | Breaking change | Pin version, update cuối sprint, đọc CHANGELOG hooks |
| `.claude/skills/` cần trust dialog | Workspace chưa trust | Accept trust dialog 1 lần; CI `-p` không trusted → test riêng |
| Plugin phình (20 skills) → context nặng | Bundle quá nhiều | Tách plugin nhỏ theo domain (frontend/backend/security) |

### 6.3. Bài tập thực hành

**Bài 1 (15 phút):** `/plugin` → Browse 3 plugins có sẵn. Điền bảng: mỗi plugin có skills/hooks/MCP/agents gì? Cái nào bạn sẽ cài?

**Bài 2 (25 phút):** Build plugin `my-standard` từ zero (mục 4): 1 skill (copy từ bài 05) + 1 hook (bài 07) + plugin.json. Install từ path local, test namespaced command.

**Bài 3 (20 phút):** Thêm agents + MCP vào plugin bài 2. Review trust checklist (mục 6.1) như thể bạn là người ngoài. Sửa chỗ nào đáng ngờ.

**Bài 4 (15 phút):** Publish lên git repo test (private). Teammate (hoặc máy thứ 2) install từ git URL. Verify version + update flow.

**Bài 5 (15 phút):** Lấy 1 plugin đã cài, tách nó thành 2 plugins nhỏ theo domain (vd frontend/backend).
So sánh context load (`/context`) trước/sau — có nhẹ hơn?

### 6.7. So sánh plugin vs alternatives (khi nào KHÔNG cần plugin?)

| Nhu cầu | Giải pháp nhẹ hơn plugin | Vì sao |
|---|---|---|
| 1 repo, 2 skills | `.claude/skills/` commit thẳng | Plugin overhead (repo riêng, version, publish) không đáng |
| Preferences cá nhân | `~/.claude/skills/` | Không share, không cần đóng gói |
| Việc chạy theo lịch | Routines `/schedule` (bài 12) | Plugin không chạy định kỳ |
| Hành động deterministic | Hooks trong repo (bài 07) | Plugin bundle hooks được, nhưng hook repo đơn giản hơn nếu chỉ 1 repo |
| Quy trình CI | `claude -p` jobs (bài 12) | Plugin sống trong session, CI cần non-interactive |

> Ngưỡng build plugin: cùng 1 bundle dùng ở ≥3 repos HOẶC onboarding ≥1 người/tháng.
> Dưới ngưỡng → `.claude/` commit thẳng rẻ hơn.

### 6.8. Walkthrough: nhờ Claude build plugin từ dotfiles có sẵn

```text
Bước 1: Chuẩn bị dotfiles trong 1 repo (skills + hooks + agents đã chạy ổn 2 tuần).
Bước 2: Prompt Claude (trong repo đó):
  "Đóng gói .claude/skills/deploy, .claude/skills/review-pr, .claude/hooks/block-main-push.sh,
   .claude/agents/explorer.md thành plugin acme-standard: viết plugin.json (dùng
   ${CLAUDE_PLUGIN_DIR}), README + trust notes, bỏ secrets khỏi .mcp.json (dùng ${VAR})."
Bước 3: Claude tạo folder acme-standard/ → bạn review plugin.json + hooks (checklist 6.1).
Bước 4: Test sandbox (mục 6.5) → publish git URL (mục 5.1) → teammate install thử.
Bước 5: Ghi CHANGELOG entry đầu tiên (version 0.1.0) + pin version cho repos production.

> Sau walkthrough này bạn có plugin chạy được + 1 teammate verify install.
> Từ đây mọi update theo flow mục 5.2 (bump → CHANGELOG → tag → team update cuối sprint).

### 6.9. Checklist plugin production-ready (trước khi announce team)

- [ ] plugin.json version + skills/agents/hooks/MCP đầy đủ, paths dùng `${CLAUDE_PLUGIN_DIR}`.
- [ ] Mọi hook `.sh` đã review (checklist 6.1) + test sandbox (mục 6.5) pass.
- [ ] `.mcp.json` không secrets (grep `sk-|password|token` trống), dùng `${VAR}`.
- [ ] README có install (path/git/marketplace) + trust notes + version pinning.
- [ ] 1 teammate cài từ git URL thành công trên máy khác.
- [ ] CHANGELOG entry + git tag (`<plugin>-vX.Y.Z`).
- [ ] Lịch update: cuối sprint, không giữa sprint (trừ security fix).
```

### 6.4. Hai plugin ví dụ chi tiết (để bắt chước cấu trúc)

**Ví dụ 1 — `security-review` (skill + subagent + hook guard):**

```text
security-review/
  .claude-plugin/plugin.json        # name, version, skills, hooks, agents
  skills/review/SKILL.md            # → /security-review:review (checklist OWASP)
  skills/review/references/owasp.md # checklist injection/authZ/secrets/crypto/SSRF
  agents/security-reviewer.md       # persona reviewer (copy mẫu bài 06 agent 3)
  hooks/guard-crypto.sh             # PreToolUse Write: block crypto tự chế (dùng lib chuẩn)
  README.md                         # install + trust notes (hooks làm gì, MCP nào)
```

**Ví dụ 2 — `frontend-polish` (chống "AI slop"):**

```text
frontend-polish/
  .claude-plugin/plugin.json
  skills/audit/SKILL.md             # → /frontend-polish:audit (quét UI smells)
  skills/polish/SKILL.md            # → /frontend-polish:polish (fix từng smell)
  skills/distill/SKILL.md           # rút design tokens từ UI mẫu
  skills/critique/SKILL.md          # adversarial review UI (như bài 06 pattern C)
  references/design-tokens.md       # spacing/type/color chuẩn team
```

### 6.5. Test plugin trong sandbox (trước khi tin)

```bash
# 1. Clone plugin vào /tmp, đọc plugin.json + từng hook .sh (checklist mục 6.1).
# 2. Cài từ path local vào repo THỬ (không phải repo thật):
cd /tmp/test-repo && git init && echo test > a.txt
# Trong session: /plugin → Install from path /path/to/plugin
# 3. Test từng skill namespaced: /<plugin>:<skill> với input vô hại.
# 4. Test hooks: prompt yêu cầu việc hook phải block → xác nhận deny.
# 5. /usage + /cost: plugin có phình context? disable skill ồn nếu cần.
# 6. Ổn mới cài vào repo thật + pin version.
```

### 6.6. FAQ plugins

| Câu hỏi | Trả lời |
|---|---|
| Plugin vs marketplace khác gì? | Plugin = 1 unit cài được; marketplace = kệ chứa nhiều plugins (repo + marketplace.json) |
| Update plugin có tự động? | Không — bạn vào Manage → Update tay, mở session mới để load. Pin version nếu sợ breaking |
| Skill plugin gọi thế nào? | Namespaced `/plugin:skill` (vd `/acme-standard:deploy`). Gõ `/` để thấy full list |
| Hooks plugin chạy khi nào? | Như hooks thường (bài 07), load lúc session start. Review trước khi cài — nó chạy shell máy bạn |
| Agent plugin sao hooks không chạy? | Thiết kế bỏ qua `hooks/mcpServers/permissionMode` — copy agent ra `.claude/agents/` nếu cần |
| `.claude/skills/` báo trust dialog? | Lần đầu cần accept workspace trust. CI `-p` không trusted → test riêng |
| Viết plugin 1 skill có đáng? | Không — 1-2 skills thì commit `.claude/skills/` thẳng. Plugin đáng khi bundle skills+hooks+agents+MCP cross-repo |
| Secrets trong plugin? | Cấm — MCP dùng `${VAR}` placeholders, secrets ở env máy/cloud (bài 08) |

---

## 7. Link chéo

- **Bài 03 — CLAUDE.md**: plugin vs committed `.claude/` 1 repo; trust dialog.
- **Bài 04 — Slash commands**: `/plugin` manager (Discover/Browse/Manage).
- **Bài 05 — Skills**: SKILL.md anatomy; namespaced `/plugin:skill`; `@skills-dir` trick.
- **Bài 06 — Subagents**: plugin agents bị bỏ qua hooks/mcpServers/permissionMode.
- **Bài 07 — Hooks**: review hooks trước khi cài; `${CLAUDE_PLUGIN_DIR}` paths.
- **Bài 08 — MCP**: bundle MCP servers (env placeholders, không secrets).
- **Bài 10 — Permissions**: managed/server policy cho org; sandbox test plugin lạ.
