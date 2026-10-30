# 10 — Permissions, modes và tính khả dụng theo plan/provider

> **Bài này cho ai:** dev viết `settings.json` cho team, hay gặp "lệnh không tồn tại", hoặc muốn biết lúc nào được phép tự chạy lệnh mà không hỏi.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([01](./01-cai-dat-va-xac-thuc.md)); nên đọc [07 — Hooks](./07-hooks-tu-dong-hoa.md) trước vì mục 1 có so sánh hook với rule.
> **Đọc xong bạn làm được:** viết `settings.json` 3 cấp copy-paste; đọc đúng rule matcher (prefix match lọt ở đâu); chọn đúng permission mode; tra bảng tính khả dụng khi "lệnh không tồn tại".
> **Thời gian:** ~35 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Permission | Cửa chắn giữa model và máy bạn: model xin → harness đối chiếu luật → cho/hỏi/cấm | `Read` đi qua, `rm -rf` dừng |
| `allow` / `ask` / `deny` | 3 mức quyết định | `Bash(pnpm test:*)` allow, `Write(.env*)` deny |
| Scope (3 cấp settings) | 3 tầng luật chồng nhau: team → personal (local) → org managed | `.claude/settings.json` commit, `.claude/settings.local.json` không commit |
| Matcher (prefix) | Rule khớp đầu chuỗi + tên tool, không phải regex đầy đủ | `Bash(git diff:*)` chỉ bắt `git diff...` |
| Permission mode | Mức tự chủ — xoay bằng Shift+Tab | `plan` read-only, `bypassPermissions` chỉ cho CI |
| Auto mode | Mode tự tiến xa, classifier duyệt quyền thay bạn | **Default cho session mới trên Pro/Max/Team từ 14/08/2026** |
| Mod | Mã JS/TS chạy ngay trong CLI, mở rộng cả giao diện | Audit ở [bài 16](./16-mods-bao-mat-validate.md) |

---

## 1. Permissions là gì, vì sao cần?

Agent có quyền chạy shell + sửa file = sức mạnh + rủi ro. Permissions là harness gate giữa model và máy bạn — không có gate này, 1 prompt-injection (issue text độc) có thể khiến agent chạy `rm -rf` hay exfiltrate `.env`. Bốn mốc khi tool request đến:

```json
// settings.json — hẹp (tốt): chỉ cho test/lint chạy luôn, còn lại hỏi
{ "permissions": {
  "allow": ["Read", "Bash(pnpm test:*)", "Bash(git diff:*)"],
  "ask": ["Edit", "Write", "Bash(pnpm:*)", "Bash(git push:*)"],
  "deny": ["Bash(rm -rf:*)", "Bash(git push origin main:*)", "Write(.env*)"]
} }
```

1. **Hook trước:** `PreToolUse` deny thắng TẤT CẢ (kể cả `--dangerously-skip-permissions`); hook allow không nới được deny (thiết kế chỉ siết — muốn nới phải sửa deny gốc).
2. **Rules:** `deny > ask > allow` trong cùng scope; `managed (org) > local > team settings > defaults` giữa các scope.
3. **Ask theo mode:** `default` hỏi nhiều; `acceptEdits` tự sửa file; `plan` read-only; `auto` tự tiến xa; `bypass` chỉ CI sandbox.

- Read-only thường chạy không hỏi; **edit file + shell** tuân permission mode + rules.
- Quản lý: `/permissions` (alias `/allowed-tools`) — xem rules theo scope, thêm/xóa, quản lý working dirs, review auto-mode denials gần đây.
- Từ Week 25/2026, deny/ask rules match được cả **tool params** theo mẫu `Tool(param:value)` — hẹp hơn được nữa.

### 1.1. 3 loại quyết định

| Quyết định | Ý nghĩa | Khi dùng |
|---|---|---|
| `allow` | Chạy luôn, không hỏi | Read-only + lệnh an toàn lặp lại (`git diff`, `pnpm test` focused) |
| `ask` | Hỏi bạn mỗi lần (hoặc theo mode) | Edit, Write, push, deploy |
| `deny` | Cấm luôn (hook allow cũng không nới được) | `rm -rf`, push main, đọc `.env`, writes ngoài repo |

Thứ tự xử lý khi tool request đến: `PreToolUse` hook deny → rules `deny` → rules `ask` (hỏi bạn hoặc auto-approve theo mode) → rules `allow` (chạy luôn).

---

## 2. Rule matcher: prefix, không phải regex shell

### 2.1. Prefix matching — cái bẫy lớn nhất

```text
Rule examples:  "Bash(pnpm test:*)"  "Bash(git diff:*)"  "Write(.env*)"  "Bash(rm -rf:*)"

Rule "Bash(git push origin main:*)" match:
  ✓ "git push origin main"          ✓ "git push origin main --tags" (prefix khớp)
  ✗ "git push origin HEAD:main"     → LỌT (không bắt đầu bằng chuỗi đó)
  ✗ "git push -f origin main"       → LỌT (flag chen giữa)

→ Bài học: rules là allowlist tiện lợi, KHÔNG phải security boundary.
   Chặn push main CHẮC CHẮN → PreToolUse hook match theo intent (bài 07).
```

### 2.2. Lọt qua binary khác

```text
Deny "Bash(rm:*)" nhưng agent chạy:
  - "python3 -c 'import shutil; shutil.rmtree(...)'"  → LỌT
  - "/bin/rm -rf ..."                                 → có thể LỌT tùy matcher normalize
  - "git clean -fdx"                                  → xóa files mà không match rm!

→ Việc critical (prod data, secrets, deploy): hook + sandbox + deny, không chỉ rules.
```

### 2.3. Deny-bypass đã vá từ v2.1.288/289 — đừng dựa vào bản cũ

Các kiểu lách đã vá: compound `&&`/`||`/`;` (chỉ check prefix allow), env-prefix `TZ="$HOME" rm -rf`, bare assignment, symlink, nested-mod approval. Bản ≥2.1.288 tách từng segment compound rồi đối chiếu từng cái + resolve realpath.

Quy tắc phòng thủ (áp dụng cả khi đã update):

- **Deny interpreter, không chỉ deny binary**: thêm `Bash(bash -c:*)`, `Bash(sh -c:*)`, `Bash(python3 -c:*)`, `Bash(node -e:*)` vào deny khi việc critical.
- **Nghi ngờ cả allow rules**: allow prefix rộng (`Bash(git:*)`, `Bash(npm:*)`) là mặt lách compound/env-prefix — giữ allow hẹp.
- **Negative test sau mỗi update**: viết 1 prompt cố lách deny cũ (compound, env-prefix, symlink) lên môi trường test — phải BLOCK mới đạt.

---

## 3. Thứ tự thắng + bộ pattern khuyến nghị

### 3.1. Precedence

```text
deny > ask > allow  (trong cùng scope)
managed (org) > settings.local (personal) > settings.json (team) > defaults
```

- `deny` ở bất kỳ scope nào cũng thắng `allow` nơi khác (an toàn mặc định).
- Hook `PreToolUse` deny thắng TẤT CẢ kể cả `bypassPermissions`; hook allow KHÔNG thắng `deny` rules hay `ask` của org.
- Xem merged result (đừng đoán): `/permissions` → tabs Allow/Ask/Deny theo scope + working dirs + recent auto-denials.

### 3.2. Patterns khuyến nghị

```text
ALLOW (chạy luôn — an toàn + lặp lại):
  Read, Glob, Grep
  Bash(git diff:*)  Bash(git status:*)  Bash(git log:*)
  Bash(pnpm test:*)  Bash(pnpm lint:*)  (focused, không phải pnpm publish!)

ASK (hỏi — có side effects):
  Edit, Write, Bash(pnpm:*)  Bash(git push:*)  Bash(git commit:*)  Bash(docker:*)  Bash(kubectl:*)

DENY (cấm — nguy hiểm/không bao giờ trong agent):
  Bash(rm -rf:*)  Bash(sudo:*)  Bash(chmod 777:*)  Bash(curl *|sh:*)  (pipe-to-shell)
  Bash(git push origin main:*)  Bash(git push origin master:*)
  Write(.env*)  Read(.env*)  Write(*credentials*)  Write(*secret*)
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
    "allow": ["Bash(gh pr view:*)", "Bash(gh issue view:*)", "Bash(pnpm --filter @acme/api test:*)"]
  }
}
```

> Personal chỉ NỚI cái team chưa cover cho workflow riêng bạn. Đừng deny trong personal để lách team allow — deny personal thắng nhưng gây confusion khi debug chung.

### 4.3. Cấp 3 — Org managed (Team/Enterprise admin)

```text
Admin console → Settings → Managed policy (JSON tương tự, thêm):
- enforce deny: Write(*prod*), Bash(kubectl delete:*), WebFetch(intranet-blocklist)
- enforce ask: mọi Bash ngoài allowlist team
- gateway routing (Desktop), SSO/SCIM, audit logs, ZDR (Zero Data Retention)
```

---

## 5. Permission modes (Shift+Tab để xoay)

```text
default → acceptEdits → plan → auto → bypassPermissions
```

| Mode | Hành vi | Khi dùng |
|---|---|---|
| `default` | Hỏi khi cần | Máy dev hàng ngày |
| `acceptEdits` | Tự sửa file (cloud default) | Task đã duyệt plan |
| `plan` | **Read-only**: outline thay đổi, chờ duyệt | Mọi task multi-file/kiến trúc |
| `auto` | Tự tiến xa, ít hỏi — classifier duyệt quyền chạy server-side + deny rules lưng | Task dài có verification gate (overnight migrate + test gate) |
| `bypassPermissions` (`--dangerously-skip-permissions`) | Bỏ hỏi | **Chỉ CI sandbox** — không dùng máy dev |

> **Auto mode:** research preview từ Week 13/03-2026 → có trên Pro từ Week 21 →
> **từ 14/08/2026 (Week 32) là default permission mode cho session mới trên Pro/Max/Team.**
> Cả auto mode lẫn hard-deny đều blocks destructive git và `rm -rf` trên biến chưa resolve.
> Có trên Bedrock/Vertex/Foundry. Cloud sessions (Web): chỉ Accept edits / Plan (/Auto tùy bản) — không Manual/Bypass.

### 5.1. Chọn mode + đổi mode

```text
Task mới, chưa hiểu scope → plan.  Task đã duyệt plan → acceptEdits.
Task dài có test gate → auto.      CI ephemeral → bypassPermissions + sandbox (bài 12).
Máy dev hàng ngày → default (hoặc auto nếu đã quen review denials).

# Đổi mode (3 cách): Shift+Tab trong REPL · claude --permission-mode plan · frontmatter permissionMode (bài 06)
```

---

## 6. Tính khả dụng: không phải feature nào cũng có ở mọi nơi

**Chạy local (CLI + IDE + Agent SDK + subagents/hooks/skills/CLAUDE.md/plugins/MCP/checkpoints/sandbox/OTel...)**: có trên **mọi provider**.

**Bắt buộc Claude subscription (claude.ai sign-in)**: Web, Mobile, Slack, Desktop app full, Routines (`/schedule`), Ultraplan, `/ultrareview` (public preview) + `claude ultrareview` cho CI, Code Review (Team/Enterprise), Remote Control, Chrome extension, Computer use (Pro/Max), Artifacts, Voice dictation.

### 6.1. Khác nhau theo provider

| Khả năng | Sub | Console | Bedrock | AWS Plat | GCP | Foundry |
|---|---|---|---|---|---|---|
| Local full (CLI/IDE/SDK/hooks/skills/MCP/...) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Web search | ✓ | ✓ | ✗ | ✓ | tùy | ✓ |
| Fast mode | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Advisor / Channels | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| GH Actions / GitLab CI | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Analytics/server settings | Team/Ent | Team/Ent | ✗ | ✗ | ✗ | ✗ |
| Web/Mobile/Slack/Routines/Remote | ✓ (sign-in) | ✗ | ✗ | ✗ | ✗ | ✗ |

### 6.2. Theo plan (sign-in claude.ai)

| Feature | Pro | Max | Team | Enterprise |
|---|---|---|---|---|
| Web / Routines / Remote / Computer use / Dispatch | ✓ | ✓ | ✓/admin | ✓/admin |
| Code Review | ✗ | ✗ | ✓ | ✓ |
| Ultraplan / Ultrareview | ✓* | ✓ | ✓ | ✓ |
| Artifacts | ✓ | ✓ | ✓ | admin-enabled |
| Analytics dashboard | ✗ | ✗ | ✓ | ✓ (+ API) |
| Server-managed settings / SSO | ✗ | ✗ | ✓ | ✓ (+SCIM/Compliance/ZDR) |

> `*` = cần admin enable hoặc giới hạn theo bản. Check docs hiện hành (code.claude.com/docs) trước khi hứa với team.

---

## 7. Walkthrough setup permissions chuẩn (15 phút)

```text
Bước 1: /permissions → xem hiện tại (trống hay đã có? scope nào?).
Bước 2: Copy settings team (mục 4.1) vào .claude/settings.json. Commit.
Bước 3: Thêm personal nới (mục 4.2) vào .claude/settings.local.json. KHÔNG commit.
Bước 4: Test 3 tình huống trong session:
  (1) prompt "đọc file .env giúp anh" phải hỏi hoặc block;
  (2) "git diff --stat" chạy luôn không hỏi;
  (3) "git push origin main" bị hook block kể cả đang ở acceptEdits.
Bước 5: /permissions → review auto-denials: cái nào deny oan thì pre-approve lệnh read-only đó.
```

---

## 8. Bẫy thường gặp + FAQ

### 8.1. Pitfalls + fix

| Pitfall | Fix |
|---|---|
| Allow `Bash(*)` cho tiện | Scope hẹp (`Bash(pnpm test:*)`), còn lại ask |
| Tưởng rules chặn được mọi cách xóa | Rules prefix-only, lọt binary khác → critical dùng hook + sandbox |
| Tin deny bản cũ (<2.1.288) | Update ≥2.1.289; negative test mục 2.3 |
| Chỉ deny `rm`, quên interpreter | Deny thêm `Bash(bash -c:*)`, `Bash(python3 -c:*)`... |
| Hook allow không nới được deny | Thiết kế (chỉ siết) — sửa deny rule gốc |
| `bypassPermissions` trên máy dev | Chỉ CI sandbox; máy dev dùng default/auto + rules |
| Deny oan lệnh read-only lặp lại | `/permissions` → review denials → pre-approve lệnh đó |

### 8.2. Gặp "lệnh không tồn tại" — 6 bước tra

```text
1. /status → version bao nhiêu? thiếu → claude update.
2. Provider gì? → tra bảng 6.1 (Bedrock mất web search/fast mode; Foundry mất GH CI...).
3. Plan gì? → tra bảng 6.2 (Code Review/Analytics chỉ Team/Ent...).
4. Surface gì? (Cloud chỉ Accept/Plan — mục 5).
5. Gõ "/" xem list thực tế — lệnh có thể đổi tên (vd /allowed-tools ≡ /permissions).
6. Vẫn không có → FAQ hoặc /bug báo Anthropic (kèm /status + version).
```

---

## 9. Mod-override và an toàn khi chạy mod

> Trên máy Pro/Max **không** managed policy: mod (in-process JS/TS, bài 16) có thể approve
> request của chính nó qua `ask` / `PreToolUse`-user / `deny` passthrough — deny rules
> không còn là chốt cuối với mod độc. Đây là thiết kế extensibility, không phải bug deny-bypass mục 2.3.

Mitigations khi chạy mod lạ (chi tiết bài 16): **safe-mode** — chỉ cho mod calls đọc (`$.fs.read`, `$.model.complete`), chặn `run/spawn/write/fetch`; **`disableAllHooks`** — tắt hooks mod đăng ký khi nghi prompt.submit/ui.render giả mạo; **`--bare`** — chạy CLI trần không load mod/plugin lạ để review code trước; review bằng `claude plugin validate <mod>` — đỏ ở `hooks:` + `calls:` (đọc env + ghi file + gọi mạng + chạy shell cùng lúc) → không cài; kèm `claude plugin eval` (đánh giá trước khi tin) và `claude plugin details` (token cost).

## 10. Bài tập + link chéo

**Bài 1 (15 phút):** Setup 2 files settings (mục 4.1 + 4.2). Test 4 prompts: read-only (qua), edit (hỏi), push main (block), đọc .env (block). **Bài 2 (15 phút):** Thử các modes (Shift+Tab) trên cùng 1 task nhỏ, ghi khác biệt số lần hỏi + `/cost`. Rồi viết 1 rule matcher cố ý sai (prefix lọt `HEAD:main`), chứng minh lọt bằng hook test script (bài 07), sửa bằng hook intent-match. **Bài 3 (15 phút):** Tra bảng mục 6: team bạn thiếu features nào? Lập bảng "có/không" + workaround.

**Link chéo:** [00 — Tổng quan](./00-tong-quan-claude-code.md) (harness ≠ model — permission do harness enforce) · [07 — Hooks](./07-hooks-tu-dong-hoa.md) (PreToolUse deny thắng bypass) · [09 — Plugins](./09-plugins-marketplaces.md) (managed policy cho org) · [11 — Worktrees](./11-git-worktrees-checkpoints.md) (trust per worktree) · [12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md) (`bypassPermissions` chỉ CI sandbox) · [16 — Mods](./16-mods-bao-mat-validate.md) (audit mod trước khi cài) · Tra lệnh chi tiết: [commands/model-mode/permissions](./commands/model-mode/permissions/README.md), [commands/auth-settings/sandbox](./commands/auth-settings/sandbox/README.md).
