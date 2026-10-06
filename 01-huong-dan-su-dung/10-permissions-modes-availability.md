# 10 — Permissions, Modes & Tính Khả Dụng Theo Plan/Provider

> Bài 10 của series. Đọc xong bạn viết được settings.json 3 cấp, hiểu rule matcher sâu,
> và tra được availability tables khi "lệnh không tồn tại". Thời gian: ~35 phút.

## Mục lục

1. [Vì sao permissions? (why)](#1-permission-rules-allow--ask--deny-why)
2. [Permission rules deep-dive](#1-permission-rules-allow--ask--deny-why)
3. [Rule matcher deep-dive](#3-rule-matcher-deep-dive-prefix--regex--thứ-tự-thắng)
4. [Settings.json 3 cấp mẫu](#4-settingsjson-mẫu-3-cấp-copy-paste)
5. [Permission modes](#5-permission-modes-shifttab-để-xoay)
6. [Full availability tables](#6-tính-khả-dụng-không-phải-feature-nào-cũng-có-ở-mọi-nơi)
7. [Walkthrough + pitfalls + bài tập](#7-walkthrough--pitfalls--bài-tập)
8. [Link chéo](#8-link-chéo)

---

## 1. Permission rules: allow / ask / deny (why)

**Nôm na 1 câu:** Permissions là *bảo vệ cổng chung cư* — chủ (bạn) dặn trước: shipper quen (Read, git diff) cho lên thẳng; khách lạ (Edit, push) phải gọi hỏi; trộm (rm -rf, push main) cấm cửa luôn.

**Analogie đời thường:** như dạy con cầm dao: dao nhựa (Read/Glob/Grep) chơi tự do; dao bếp (Edit/Write/docker) phải hỏi mẹ; dao chặt xương + ổ điện (sudo, rm -rf, đọc .env) cấm tuyệt đối. Modes (Shift+Tab) là mức "mẹ đang bận hay đang rảnh để hỏi".

**Ví dụ kỹ thuật copy-paste (rule hẹp tốt vs rộng xấu):**

```json
// settings.json — hẹp (tốt): chỉ cho test/lint chạy luôn, còn lại hỏi
{ "permissions": {
  "allow": ["Read", "Bash(pnpm test:*)", "Bash(git diff:*)"],
  "ask": ["Edit", "Write", "Bash(pnpm:*)", "Bash(git push:*)"],
  "deny": ["Bash(rm -rf:*)", "Bash(git push origin main:*)", "Write(.env*)"]
} }
# Verify: trong session /permissions → thấy 3 tabs Allow/Ask/Deny đã merge.
# Kỳ vọng: "git diff --stat" chạy luôn; "sửa file" hỏi; "đọc .env" block.
```

> **Ai dùng lúc nào:** mọi dev từ ngày 1 (kể cả solo) — vì prompt-injection từ issue text độc có thể dụ agent chạy lệnh xóa/exfiltrate nếu không có gate.

```mermaid
flowchart TD
  R[Claude xin chạy tool<br/>vd Bash git push origin main] --> H{PreToolUse hook?}
  H -->|deny| B1[BLOCK ngay<br/>thắng cả bypass]
  H -->|qua| G{Rules: deny ask allow?}
  G -->|deny| B2[Cấm luôn]
  G -->|ask| Q{Hỏi bạn / theo mode?}
  G -->|allow| A[Chạy luôn]
  Q -->|đồng ý| A
  Q -->|từ chối| B2
```

**Giải thích từng bước:**
1. **Hook trước:** `PreToolUse` deny thắng TẤT CẢ (kể cả `--dangerously-skip-permissions`). Đây là chốt chặn cuối cho việc critical.
2. **Rules:** `deny > ask > allow` trong cùng scope; `managed (org) > local > team settings > defaults` giữa các scope.
3. **Ask theo mode:** `default` hỏi nhiều; `acceptEdits` tự sửa file; `plan` read-only; `auto` tự tiến xa; `bypass` chỉ CI sandbox. Cloud chỉ Accept/Plan(/Auto).
4. **Hook allow không nới:** thiết kế chỉ siết — muốn nới phải sửa deny gốc, đừng thêm hook allow.

Agent có quyền chạy shell + sửa file = sức mạnh + rủi ro. Permissions là harness gate giữa
model và máy bạn: model xin → harness đối chiếu rules → cho/hỏi/cấm. Không có gate này,
1 prompt-injection (issue text độc) có thể khiến agent chạy `rm -rf` hay exfiltrate `.env`.

- Read-only thường chạy không hỏi; **edit file + shell** tuân permission mode + rules.
- Quản lý: `/permissions` (alias `/allowed-tools`) — xem rules theo scope, thêm/xóa, quản lý working dirs,
  review auto-mode denials gần đây.
- File: `.claude/settings.json` (team, commit) vs `.claude/settings.local.json` (personal, không commit),
  cộng managed policy (org) — xem merged result ở `/permissions`, đừng đoán.
- Rules **không phải shell security parser**: command tương đương qua binary khác có thể lọt —
  việc thật sự critical thì dùng **hook + OS sandbox**, đừng chỉ trông vào rules.
- Hooks `PreToolUse` deny thắng cả `bypassPermissions`; hook allow không nới được deny/`ask` của org.

### 1.1. 3 loại quyết định

| Quyết định | Ý nghĩa | Khi dùng |
|---|---|---|
| `allow` | Chạy luôn, không hỏi | Read-only + lệnh an toàn lặp lại (`git diff`, `pnpm test` focused) |
| `ask` | Hỏi bạn mỗi lần (hoặc theo mode) | Edit, Write, push, deploy — muốn mắt người |
| `deny` | Cấm luôn (hook allow cũng không nới được) | `rm -rf`, push main, đọc `.env`, writes ngoài repo |

---

## 2. Rule matcher deep-dive (đọc kỹ — sai ở đây là lọt/xịt)

Rules match theo **prefix + tool name**, KHÔNG phải regex shell đầy đủ (trừ hooks tự viết).

```text
Rule examples (trong settings.json permissions):
  "Read"                    → mọi Read (rộng)
  "Bash(pnpm test:*)"       → Bash command bắt đầu bằng "pnpm test" (hẹp, tốt)
  "Bash(git diff:*)"        → chỉ git diff*
  "Write(.env*)"            → Write path bắt đầu .env (deny đọc secrets)
  "Bash(rm -rf:*)"          → deny prefix nguy hiểm
```

### 2.1. Prefix matching — cái bẫy lớn nhất

```text
Rule "Bash(git push origin main:*)" match:
  ✓ "git push origin main"
  ✓ "git push origin main --tags" (prefix khớp)
  ✗ "git push origin HEAD:main" (không bắt đầu bằng chuỗi đó → LỌT!)
  ✗ "git push -f origin main" (flag chen giữa → LỌT!)

→ Bài học: rules là allowlist tiện lợi, KHÔNG phải security boundary.
   Chặn push main CHẮC CHẮN → PreToolUse hook match theo intent (bài 07 hook 2).
```

### 2.2. Lọt qua binary khác (why rules không đủ cho critical)

```text
Deny "Bash(rm:*)" nhưng agent chạy:
  - "python3 -c 'import shutil; shutil.rmtree(...)'" → LỌT (không phải Bash rm)
  - "/bin/rm -rf ..." → có thể LỌT tùy matcher normalize
  - "git clean -fdx" → xóa files mà không match rm!

→ Việc critical (prod data, secrets, deploy): hook + sandbox + deny, không chỉ rules.
```

### 2.3. Deny-bypass đã fix ở v2.1.288/289 (đừng dựa vào bản cũ)

> Nếu bạn ở bản <2.1.288: update trước khi tin deny rules. Kiểm tra:
> `claude --version` + `npm view @anthropic-ai/claude-code dist-tags`
> (stable ~2.1.285, latest ~2.1.289 thời điểm viết — `latest` chứa fix, `stable` có thể chưa).

Các kiểu lách đã vá (compound/env-prefix/bare-assign/symlink/nested-mod):

```text
1. Compound &&/||/|/; — chỉ check prefix allow:
   allow "Bash(git status:*)" + deny "Bash(rm:*)" nhưng chạy
   "git status && rm -rf /tmp/x" → bản cũ chỉ check prefix "git status" → LỌT.
   Fix 2.1.288/289: tách từng segment compound rồi đối chiếu từng cái.
2. Env-prefix: 'TZ="$HOME" rm -rf ...' / 'FOO=bar rm ...' → matcher cũ thấy "TZ=..." không phải "rm" → LỌT.
3. Bare assignment: 'FOO=bar' đứng riêng / đầu lệnh để đánh lừa parser.
4. Symlink: '/tmp/link-to-rm' (symlink → /bin/rm) → resolve realpath trước khi match.
5. Nested mod approval: mod con xin approve lồng trong mod cha → chỉ giữ trên managed machines.
```

Quy tắc phòng thủ (áp dụng cả khi đã update):

- **Deny interpreter, không chỉ deny binary**: thêm `Bash(bash -c:*)`, `Bash(sh -c:*)`,
  `Bash(python3 -c:*)`, `Bash(node -e:*)` vào deny khi việc critical — kẻ lách đổi interpreter chứ không đổi lệnh.
- **Nghi ngờ cả allow rules**: allow prefix rộng (`Bash(git:*)`, `Bash(npm:*)`) là mặt lách compound/env-prefix.
  Giữ allow hẹp (`Bash(git diff:*)`), còn lại `ask`.
- **Negative test từ changelog**: sau mỗi update đọc changelog, viết 1 prompt cố lách deny cũ
  (compound, env-prefix, symlink) lên môi trường test + hook `bash-guard.sh` (templates) — phải BLOCK mới đạt.

---

## 3. Rule matcher deep-dive (prefix + regex + thứ tự thắng)

### 3.1. Thứ tự thắng (precedence)

```
deny > ask > allow  (trong cùng scope)
managed (org) > settings.local (personal) > settings.json (team) > defaults
```

- `deny` ở bất kỳ scope nào cũng thắng `allow` nơi khác (an toàn mặc định).
- Hook `PreToolUse` deny thắng TẤT CẢ kể cả `bypassPermissions`.
- Hook allow KHÔNG thắng được `deny` rules hay `ask` của org (hooks chỉ siết, không nới).

```bash
# Xem merged result (đừng đoán — xem thật):
# Trong session:
/permissions
# → tabs: Allow / Ask / Deny theo scope (team/local/managed) + working dirs + recent auto-denials.
```

### 3.2. Patterns allow/ask/deny khuyến nghị

```text
ALLOW (chạy luôn — an toàn + lặp lại):
  Read, Glob, Grep
  Bash(git diff:*)  Bash(git status:*)  Bash(git log:*)
  Bash(pnpm test:*)  Bash(pnpm lint:*)  (focused, không phải pnpm publish!)

ASK (hỏi — có side effects):
  Edit, Write
  Bash(pnpm:*)  (rộng hơn test/lint — hỏi vì có install/publish)
  Bash(git push:*)  Bash(git commit:*)
  Bash(docker:*)  Bash(kubectl:*)

DENY (cấm — nguy hiểm/không bao giờ trong agent):
  Bash(rm -rf:*)  Bash(sudo:*)  Bash(chmod 777:*)
  Bash(git push origin main:*)  Bash(git push origin master:*)
  Write(.env*)  Read(.env*)  Write(*credentials*)  Write(*secret*)
  Bash(curl *|sh:*)  (pipe-to-shell)
```

---

## 4. Settings.json mẫu 3 cấp (copy-paste)

### 4.1. Cấp 1 — Team (`.claude/settings.json`, COMMIT)

```json
{
  "$schema": "https://claude.ai/code/settings-schema.json",
  "permissions": {
    "allow": [
      "Read", "Glob", "Grep",
      "Bash(git diff:*)", "Bash(git status:*)", "Bash(git log:*)",
      "Bash(pnpm test:*)", "Bash(pnpm lint:*)"
    ],
    "ask": ["Edit", "Write", "Bash(pnpm:*)", "Bash(git push:*)", "Bash(git commit:*)", "Bash(docker:*)"],
    "deny": [
      "Bash(rm -rf:*)", "Bash(sudo:*)",
      "Bash(git push origin main:*)", "Bash(git push origin master:*)",
      "Write(.env*)", "Read(.env*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-main-push.sh" }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-on-write.sh" }
    ]
  }
}
```

### 4.2. Cấp 2 — Personal (`.claude/settings.local.json`, KHÔNG commit)

```json
{
  "permissions": {
    "allow": [
      "Bash(gh pr view:*)",
      "Bash(gh issue view:*)",
      "Bash(pnpm --filter @acme/api test:*)"
    ],
    "ask": [],
    "deny": []
  }
}
```

> Personal chỉ NỚI cái team chưa cover cho workflow riêng bạn. Đừng deny trong personal
> để lách team allow — deny personal thắng nhưng gây confusion khi debug chung.

### 4.3. Cấp 3 — Org managed (Team/Enterprise admin)

```text
Admin console → Settings → Managed policy (JSON tương tự, thêm):
- enforce deny: Write(*prod*), Bash(kubectl delete:*), WebFetch(intranet-blocklist)
- enforce ask: mọi Bash ngoài allowlist team
- gateway routing (Desktop), SSO/SCIM, audit logs, ZDR (Zero Data Retention)
Chi tiết: docs org admin + bảng mục 6 (Analytics/server settings chỉ Team/Ent).
```

```bash
# Verify 3 cấp (copy-paste):
# Trong session:
/permissions
# → kiểm tra: team rules hiện? personal rules merge? managed có deny nào đè?
# Đổi working dirs: /add-dir ../shared (cần trust), /cd ~/code/other (giữ cache).
```

---

## 5. Permission modes (Shift+Tab để xoay)

```
default → acceptEdits → plan → auto → bypassPermissions
```

| Mode | Hành vi | Khi dùng | Ví dụ |
|---|---|---|---|
| `default` | Hỏi khi cần | Mặc định hàng ngày | Code thường |
| `acceptEdits` | Tự sửa file, push branch (cloud default) | Tin task, muốn nhanh | Refactor đã duyệt plan |
| `plan` | **Read-only**: outline thay đổi, chờ duyệt mới được code | Mọi task multi-file/kiến trúc (phản xạ) | Task mới, chưa rõ scope |
| `auto` | Tự tiến xa, ít hỏi (có classifier + deny rules lưng) | Task dài có verification gate | Overnight migrate + test gate |
| `bypassPermissions` (`--dangerously-skip-permissions`) | Bỏ hỏi | **Chỉ CI sandbox** — không dùng máy dev | CI runner ephemeral (bài 12) |

Cloud sessions (Web): chỉ Accept edits / Plan (/Auto tùy bản) — không Manual/Bypass.

### 5.1. Chọn mode theo task (cheat)

```text
Task mới, chưa hiểu scope → plan (đọc + outline, không sửa).
Task đã duyệt plan, implement → acceptEdits (đỡ bị hỏi mỗi file).
Task dài 1 giờ, có test gate → auto (tự chạy, deny lưng bảo vệ).
CI ephemeral → bypassPermissions + sandbox + allowlist hẹp (bài 12).
Máy dev hàng ngày → default (cân bằng).
```

```bash
# Đổi mode (3 cách):
# 1. Shift+Tab trong REPL (xoay vòng).
# 2. Lệnh khởi động: claude --permission-mode plan
# 3. Per-agent frontmatter: permissionMode: plan (bài 06).
```

---

## 6. Tính khả dụng: không phải feature nào cũng có ở mọi nơi

**Chạy local (CLI + IDE + Agent SDK + subagents/hooks/skills/CLAUDE.md/plugins/MCP/checkpoints/sandbox/workflows/OTel...)**: có trên **mọi provider**.

**Bắt buộc Claude subscription (claude.ai sign-in)**: Web, Mobile, Slack, Desktop app full,
Routines (`/schedule`), Ultraplan/Ultrareview, Code Review (Team/Enterprise), Remote Control,
Chrome extension, Computer use (Pro/Max), Artifacts (Pro/Max/Team/Enterprise tùy admin), Voice dictation.

### 6.1. Khác nhau theo provider (full table)

| Khả năng | Sub | Console | Bedrock | AWS Plat | GCP | Foundry |
|---|---|---|---|---|---|---|
| Local full (CLI/IDE/SDK/hooks/skills/MCP/...) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Web search | ✓ | ✓ | ✗ | ✓ | tùy | ✓ (hosted on Anthropic) |
| Fast mode | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Auto mode | ✓ | ✓ | tùy note | ✓ | tùy | tùy |
| Advisor / Channels | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| `/loop` scheduled | ✓ | ✓ | tùy | tùy | tùy | tùy |
| GH Actions / GitLab CI | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Analytics/server settings | Team/Ent | Team/Ent | ✗ | ✗ | ✗ | ✗ |
| `/design-sync`, `/radio` | ✓ | ✓ | ✗ | ✗ | ✗ | ✓* |
| Web/Mobile/Slack/Routines/Remote | ✓ (sign-in) | ✗ | ✗ | ✗ | ✗ | ✗ |

Vắng trên Bedrock/AWS/GCP thêm: `/design-sync`, `/radio`. Trên Foundry: CI/CD GitHub thiếu.
Chi tiết: docs `feature-availability`. Gặp "lệnh không tồn tại" → check provider + version trước khi kết luận bug.

### 6.2. Theo plan (sign-in claude.ai)

| Feature | Pro | Max | Team | Enterprise |
|---|---|---|---|---|
| Web / Routines / Remote / Computer use / Dispatch | ✓ | ✓ | ✓/admin | ✓/admin |
| Code Review | ✗ | ✗ | ✓ | ✓ |
| Ultraplan/Ultrareview | ✓* | ✓ | ✓ | ✓ |
| Artifacts | ✓ | ✓ | ✓ | admin-enabled |
| Analytics dashboard | ✗ | ✗ | ✓ | ✓ (+ API) |
| Server-managed settings / SSO | ✗ | ✗ | ✓ | ✓ (+SCIM/Compliance/ZDR) |
| Slack integration | ✓* | ✓* | admin-enabled | admin-enabled |

> `*` = cần admin enable hoặc giới hạn theo bản. Check docs plan hiện hành trước khi hứa với team.

---

## 7. Walkthrough + pitfalls + bài tập

### 7.1. Walkthrough: setup permissions chuẩn (15 phút)

```text
Bước 1: /permissions → xem hiện tại (trống hay đã có? scope nào?).
Bước 2: Copy settings team (mục 4.1) vào .claude/settings.json. Commit.
Bước 3: Thêm personal nới (mục 4.2) vào .claude/settings.local.json. KHÔNG commit.
Bước 4: Test deny: prompt "đọc file .env giúp anh" → phải hỏi/block.
        Test allow: "git diff --stat" → chạy luôn không hỏi.
Bước 5: Test hook đè: "git push origin main" → hook block kể cả acceptEdits mode.
Bước 6: /permissions → review auto-denials (cái nào deny oan? pre-approve read-only đó).
```

### 7.2. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Allow `Bash(*)` cho tiện | Đưa chìa khóa nhà | Scope hẹp (`Bash(pnpm test:*)`), còn lại ask |
| Tưởng rules chặn được mọi cách xóa | Rules prefix-only, lọt binary khác | Critical → hook + sandbox (bài 07) |
| Tin deny bản cũ (<2.1.288) | Compound/env-prefix/symlink lọt | Update ≥2.1.289 (`npm view dist-tags` + `claude --version`); negative test mục 2.3 |
| Chỉ deny `rm`, quên interpreter | Lách qua `bash -c`/`python3 -c` | Deny thêm `Bash(bash -c:*)`, `Bash(python3 -c:*)`... |
| Tin mod Pro/Max không managed là an toàn | Mod có thể tự approve qua ask/PreToolUse-user/deny | Mitigations: safe-mode, `disableAllHooks`, `--bare` (mục 7.6) |
| Hook allow không nới được deny | Thiết kế (chỉ siết) | Sửa deny rule gốc, đừng thêm hook allow |
| `bypassPermissions` trên máy dev | Copy từ CI example | Chỉ CI sandbox; máy dev dùng auto + rules |
| Cloud thiếu Manual/Bypass mà ngạc nhiên | Cloud policy | Cloud chỉ Accept/Plan(/Auto) — thiết kế an toàn |
| "Lệnh không tồn tại" → kết luận bug | Quên check provider/plan | Tra bảng mục 6 + `/status` trước |
| Deny oan lệnh read-only lặp lại | Chưa pre-approve | `/permissions` → review denials → allow read-only đó |

### 7.2b. Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật | Ai cần nhớ |
|---|---|---|
| "Deny trong settings là chặn tuyệt đối" | Vẫn lọt qua interpreter khác (`python3 -c`), symlink, compound `&&` ở bản cũ. Việc critical cần hook + sandbox, không chỉ rules. | Mọi dev |
| "`bypassPermissions` cho nhanh trên máy dev" | Chỉ CI ephemeral sandbox. Máy dev dùng `default/auto` + rules hẹp, không là 1 prompt độc xóa sạch. | Người thích tốc độ |
| "Hook allow mở được deny của org" | Không — hooks chỉ siết. Org `ask`/deny luôn thắng hook allow. | Người debug org policy |
| "Cloud modes giống local" | Cloud (Web) chỉ Accept edits / Plan (/Auto tùy bản) — không Manual/Bypass. Ngạc nhiên là do chưa đọc mục 5. | Người dùng Web/cloud |
| "Provider nào features cũng như nhau" | Bedrock mất web search/fast mode/`/design-sync`; Foundry mất GH CI; Code Review chỉ Team/Ent. "Lệnh không tồn tại" → tra bảng mục 6 trước. | Team multi-provider |

### 7.3. Bài tập thực hành

**Bài 1 (15 phút):** Setup 2 files settings (mục 4.1 + 4.2). Test 4 prompts: read-only (cho qua),
edit (hỏi), push main (block), đọc .env (block). Ghi kết quả.

**Bài 2 (15 phút):** Thử 5 modes (Shift+Tab) trên cùng 1 task nhỏ. Ghi khác biệt số lần hỏi + `/cost`.

**Bài 3 (15 phút):** Viết 1 rule matcher cố ý sai (prefix lọt `HEAD:main`). Chứng minh lọt bằng
hook test script (bài 07 mục 6.2). Sửa bằng hook intent-match.

**Bài 4 (15 phút):** Tra bảng mục 6: team bạn (plan + provider gì) thiếu features nào? Lập bảng
"có/không" cho 10 features team quan tâm. Ghi workaround cho cái thiếu.

### 7.4. Troubleshooting matrix ("lệnh không tồn tại" → tra đâu?)

```text
"Lệnh X không tồn tại / không chạy?"
├─ 1. /status → version bao nhiêu? (đối chiếu version floor bài 01: /cd ≥.169, /goal ≥.139...)
│     → thiếu → claude update.
├─ 2. Provider gì? (Subscription / Console / Bedrock / AWS / GCP / Foundry)
│     → tra bảng mục 6.1: Bedrock mất web search/fast mode//design-sync//radio; Foundry mất GH CI...
├─ 3. Plan gì? (Pro/Max/Team/Ent — mục 6.2: Code Review chỉ Team/Ent, Analytics chỉ Team/Ent...)
├─ 4. Surface gì? (Cloud chỉ Accept/Plan, không Manual/Bypass — mục 5)
├─ 5. Gõ "/" xem list thực tế — có thể lệnh đổi tên theo bản (vd /allowed-tools ≡ /permissions).
└─ 6. Vẫn không có → 03-FAQ/ hoặc /bug báo Anthropic (kèm /status + version).
```

### 7.5. FAQ permissions

| Câu hỏi | Trả lời |
|---|---|
| Rules có chặn được mọi lệnh nguy hiểm? | Không — prefix-match, lọt binary khác (mục 2). Critical → hook + sandbox |
| Hook allow có nới deny được? | Không — hooks chỉ siết. Sửa deny rule gốc |
| `bypassPermissions` bao giờ dùng? | Chỉ CI sandbox ephemeral. Máy dev → `default/auto` + rules hẹp |
| Cloud sao không có Bypass? | Thiết kế an toàn — cloud chỉ Accept/Plan(/Auto tùy bản) |
| Deny oan lệnh read-only? | `/permissions` → recent auto-denials → pre-approve lệnh đó |
| Personal vs team settings xung đột? | Deny thắng allow; managed đè cả 2. Xem merged ở `/permissions`, đừng đoán |

### 7.6. Mod-override (Pro/Max không managed — mod có thể tự approve)

> Trên máy Pro/Max **không** managed policy: mod (in-process JS/TS, bài 16) có thể approve
> request của chính nó qua `ask` / `PreToolUse`-user / `deny` passthrough — tức deny rules
> không còn là chốt cuối với mod độc. Đây là thiết kế extensibility, không phải bug deny-bypass mục 2.3.

Mitigations (chọn 1+ khi chạy mod lạ — chi tiết bài 16):

- **safe-mode**: chỉ cho mod calls đọc (`$.fs.read`, `$.model.complete`), chặn `run/spawn/write/fetch`.
- **`disableAllHooks`**: tắt hooks mod đăng ký khi nghi prompt.submit/ui.render giả mạo.
- **`--bare`**: chạy CLI trần không load mod/plugin lạ để review code mod trước (`plugin-validate`).
- Review bằng `claude plugin validate <mod>` trước khi cài: đỏ ở `hooks:` + `calls:` (đọc env + ghi file + gọi mạng + chạy shell cùng lúc) → không cài.

---

## 8. Link chéo

- **Bài 01 — Cài đặt**: providers login (`claude login`, API key, Bedrock/GCP/Foundry).
- **Bài 02 — Surfaces**: modes theo surface; cloud không Manual/Bypass.
- **Bài 04 — Slash commands**: `/permissions`, Shift+Tab modes, `/sandbox`.
- **Bài 06 — Subagents**: permissionMode per-agent, tools allowlist.
- **Bài 07 — Hooks**: PreToolUse deny thắng bypass; allow không nới deny/org.
- **Bài 09 — Plugins**: managed policy cho org; review plugin permissions.
- **Bài 11 — Worktrees**: worktrees + permissions (mỗi worktree trust riêng?).
- **Bài 12 — SDK/CI**: `bypassPermissions` chỉ CI sandbox + allowlist hẹp.
