# 07 — Hooks: Tự Động Hóa Deterministic (Luật, Không Phải Gợi Ý)

> Bài 07 của series. Đọc xong bạn có full settings.json mẫu, 5 hooks hoàn chỉnh copy-paste,
> và debug flowchart khi hook không chạy. Thời gian: ~45 phút.

## Mục lục

1. [Hook là gì — why law > advisory](#1-hook-là-gì)
2. [Bảng events đầy đủ](#2-bảng-events-thuộc-lòng-nhóm-chính)
3. [Cấu hình settings.json + cơ chế stdin/stdout](#3-cấu-hình-settingsjson--cơ-chế-sâu)
4. [Full settings.json mẫu (team-ready)](#4-full-settingsjson-mẫu-team-ready-copy-paste)
5. [5 hooks hoàn chỉnh](#5-5-hooks-hoàn-chỉnh-copy-paste)
6. [Walkthrough + debug flowchart](#6-walkthrough--debug-flowchart)
7. [Pitfalls + bài tập](#7-pitfalls--bài-tập)
8. [Link chéo](#8-link-chéo)

---

## 1. Hook là gì

Shell command (hoặc http/mcp_tool/prompt/agent) Claude Code **tự chạy khi tới lifecycle event** —
không qua LLM quyết định → **deterministic, 0 model tokens, Claude không override được**.
Dùng để: format sau edit, block lệnh nguy hiểm, gửi notification, inject context đầu session, enforce rules.

> Triết lý: CLAUDE.md/skills = advisory (Claude có thể quên). Hooks = law.
> Rule nào bị miss 2 lần → nâng thành hook.

### 1.1. Vì sao hooks "miễn phí + chắc chắn"? (why)

Hooks chạy **ngoài model** (harness chạy shell, không gọi LLM — trừ type `prompt`/`agent`).
Vì vậy: không tốn model tokens, không bị prompt-injection thuyết phục, chạy trước cả
`bypassPermissions`. Đó là lý do duy nhất trong hệ sinh thái có tính chất này (bài 00).

```text
So sánh enforce:
- CLAUDE.md "NEVER push main" → Claude đọc, gật gù, đôi khi vẫn push (quên/misread).
- PreToolUse hook match `git push.*main` → block 100%, kể cả --dangerously-skip-permissions.
→ Cái nào cần chắc chắn? Hook. Cái nào cần linh hoạt? CLAUDE.md/skill.
```

---

## 2. Bảng events (thuộc lòng nhóm chính)

| Event | Khi lửa | Dùng cho |
|---|---|---|
| `SessionStart` | Session bắt đầu/resume | Inject context (branch, ticket, env check) |
| `Setup` | `claude --init-only`, hoặc `--init`/`--maintenance` trong `-p` (chuẩn bị CI/scripts) | CI warmup (bài 12) |
| `UserPromptSubmit` | User submit prompt, trước khi Claude xử lý | Block/redirect prompt nguy hiểm, log |
| `UserPromptExpansion` | Command user gõ expand thành prompt (có thể block) | Validate slash command args |
| `PreToolUse` | Trước tool call (**block được**) — chạy trước mọi permission check, kể cả `dontAsk`/`bypass` | Guard rails (branch-protect, migration-guard) |
| `PermissionRequest` | Tool call cần quyết định permission (trong `-p` plain: dùng `PreToolUse` thay vì event này) | Custom permission UI (interactive) |
| `PermissionDenied` | Auto mode deny (có thể `retry: true` để model thử lại) | Gợi ý lệnh đúng khi bị deny |
| `PostToolUse` / `PostToolUseFailure` | Sau tool call thành công/thất bại | Lint-on-write, format, log |
| `PostToolBatch` | Sau cả batch parallel tool calls, trước model call kế | Tổng hợp batch (vd check tổng files đổi) |
| `Notification` | Khi Claude gửi notification | Ping Slack/osascript khi cần bạn |
| `MessageDisplay` | Khi assistant text hiển thị | Filter/redact output (hiếm) |
| `SubagentStart`/`SubagentStop` | Subagent spawn/finish (matcher = tên agent type) | Log cost, inject context cho agent |
| `TaskCreated`/`TaskCompleted` | Task lifecycle (`TaskCreate`) | Tracking, ledger |
| `Stop` / `StopFailure` | Claude xong response / turn kết thúc do API error (Stop **không** lửa khi user interrupt) | Cost ledger, gate (block turn-end tới khi pass, tối đa 8 blocks) |
| `TeammateIdle` | Agent-team teammate sắp idle | Giao việc tiếp cho teammate (teams) |
| `InstructionsLoaded` | 1 file CLAUDE.md/rules vừa load (đầu session + lazy-load) | Validate/audit memory load |
| `PreCompact`/`PostCompact`, `ConfigChange`, `PreToolUse`... | Compaction/config (matcher: `manual/auto`, source settings...) | Backup context trước compact |

Types: `command` (shell, phổ biến), `http` (POST event JSON tới URL), `mcp_tool` (gọi tool của MCS server đã connect),
`prompt` (LLM 1-turn, default Haiku, quyết định cần judgment), `agent` (experimental: subagent verify multi-turn, ~60s/50 turns).

### 2.1. Chọn type nào? (bảng)

| Type | Khi nào | Ví dụ |
|---|---|---|
| `command` | 95% cases — deterministic, nhanh, 0 token | Lint, block push, guard migrations |
| `prompt` | Cần judgment ngôn ngữ (không regex được) | "Commit message có leak secret không?" |
| `agent` | Verify cần đọc code multi-turn (experimental) | Review diff trước khi cho push |
| `http` | Đẩy event ra hệ ngoài | Log sang ticketing/monitoring |
| `mcp_tool` | Hành động qua MCP đã connect | PostToolUse → tạo ticket Linear |

---

## 3. Cấu hình settings.json + cơ chế sâu

### 3.1. Files settings (precedence)

```
managed policy (org) > .claude/settings.local.json (personal, không commit)
> .claude/settings.json (team, commit) > ~/.claude/settings.json (personal global)
```

- Xem merged result ở `/permissions`, đừng đoán (bài 10).
- Frontmatter hooks của project subagents cần trust workspace dialog; `-p` session không tính trusted.

### 3.2. Cơ chế stdin/stdout (hook contract)

```text
1. Harness gửi event JSON qua STDIN của hook command.
   Vd PreToolUse: {"tool":"Bash","input":{"command":"git push origin main"},"cwd":"..."}
2. Hook đọc stdin (jq/python), quyết định.
3. Hook trả về:
   - Exit 0 + (optional) JSON {"permissionDecision":"allow"} → cho qua.
   - Exit 2 / JSON {"permissionDecision":"deny","reason":"..."} → block, reason hiện cho Claude + user.
   - JSON {"updatedInput":{...}} → rewrite input (vd thêm flags). 2 hook cùng rewrite → finish cuối thắng (tránh overlap).
   - Stop gate: JSON {"decision":"block","reason":"tests fail"} → Claude phải fix tiếp (tối đa 8 blocks liên tiếp).
```

```bash
# Khung hook bash chuẩn (mọi hook command đều từ đây mà ra):
#!/bin/bash
set -euo pipefail
INPUT="$(cat)"  # đọc JSON stdin
CMD="$(echo "$INPUT" | jq -r '.input.command // empty')"
# ... logic ...
# Cho qua:
exit 0
# Block:
# echo '{"permissionDecision":"deny","reason":"..."}'
# exit 2
```

- Hook nhận JSON qua **stdin**, trả về pass/block (exit code / JSON `permissionDecision: allow|deny`, `updatedInput`...).
- Matcher **case-sensitive**, match tên tool (`Edit`, `Write`, `Bash`...). Nhiều hooks cùng event chạy **song song**;
  2 hook cùng rewrite `updatedInput` → thằng finish cuối thắng (non-deterministic — tránh overlap).
- Xem: `/hooks`. Debug: check event đúng chưa (Pre vs Post), matcher đúng case chưa, folder đã trust chưa
  (frontmatter hooks project-level cần trust dialog; `-p` session không tính là trusted).
- Bảo mật: hook deny thắng cả `bypassPermissions`/`--dangerously-skip-permissions`; ngược lại hook allow
  KHÔNG nới được deny rules hay `ask` của org — hooks chỉ siết, không nới.

---

## 4. Full settings.json mẫu (team-ready, copy-paste)

```json
{
  "$schema": "https://claude.ai/code/settings-schema.json",
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(pnpm test:*)", "Bash(git diff:*)", "Bash(git status:*)"],
    "ask": ["Edit", "Write", "Bash(pnpm:*)", "Bash(git push:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(git push origin main:*)", "Write(.env*)"]
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-context.sh"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-main-push.sh"
      },
      {
        "matcher": "Write",
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard-migrations.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-on-write.sh"
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/cost-ledger.sh"
      }
    ],
    "Notification": [
      {
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/notify.sh"
      }
    ],
    "SubagentStop": [
      {
        "matcher": "explorer|tester",
        "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/log-subagent.sh"
      }
    ]
  }
}
```

```json
// Ví dụ PreToolUse conditional (chỉ cho test-runner Bash qua, block Bash nguy hiểm):
// Đặt trong agent frontmatter hoặc settings hooks với command script kiểm tra prefix.
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/allow-test-only.sh" }
    ]
  }
}
```

---

## 5. 5 hooks hoàn chỉnh (copy-paste)

> Đặt vào `.claude/hooks/`, `chmod +x`, cấu hình trong settings.json mục 4.

**Hook 1 — lint-on-write (PostToolUse Edit|Write)** — format/lint file vừa sửa, lỗi trả lại cho agent fix ngay:

```bash
#!/bin/bash
# .claude/hooks/lint-on-write.sh
set -euo pipefail
INPUT="$(cat)"
# Lấy file paths từ event (CLAUDE_FILE_PATHS hoặc parse JSON):
FILES="$(echo "$INPUT" | jq -r '.input.file_path // .input.path // empty')"
[ -z "$FILES" ] && exit 0
# Chỉ lint files JS/TS (thu hẹp scope cho nhanh — đừng lint cả repo):
echo "$FILES" | tr ' ' '\n' | grep -E '\.(ts|tsx|js|jsx)$' | while read -r f; do
  [ -f "$f" ] || continue
  npx prettier --write "$f" >/dev/null 2>&1 || true
  npx eslint "$f" --max-warnings 0
done
# eslint fail → exit nonzero → PostToolUseFailure → Claude thấy lỗi, fix ngay.
```

**Hook 2 — branch-protect (PreToolUse Bash)** — block `push main`, force-push, xóa branch:

```bash
#!/bin/bash
# .claude/hooks/block-main-push.sh — match theo INTENT, không substring "main"
set -euo pipefail
INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.input.command // empty')"
# Block push tới main/master (mọi remote, mọi cú pháp):
if echo "$CMD" | grep -Eq 'git[[:space:]]+push([^&|;]*[[:space:]]|^)(origin[[:space:]]+)?(HEAD:)?(main|master)([[:space:]]|$)'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: không push trực tiếp main/master. Mở PR từ branch feat/*."}'
  exit 2
fi
# Block force-push mọi dạng:
if echo "$CMD" | grep -Eq '\-\-force($|[[:space:]])|-f([[:space:]]|$)|--force-with-lease'; then
  # Cho phép force-push lên branch feat/* của mình? Team quyết — mẫu này block hết cho an toàn:
  echo '{"permissionDecision":"deny","reason":"BLOCKED: force-push bị cấm. Dùng rebase thường hoặc hỏi lead."}'
  exit 2
fi
# Block xóa branch remote:
if echo "$CMD" | grep -Eq 'git[[:space:]]+push[[:space:]]+[^ ]*[[:space:]]+--delete|git[[:space:]]+push[[:space:]]+[^ ]*[[:space:]]+:heads/'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: xóa branch remote cần xác nhận tay."}'
  exit 2
fi
exit 0
# Test với: git push -f, git push --force, git push --force-with-lease, git push origin HEAD:main.
```

**Hook 3 — guard-migrations (PreToolUse Write)** — block sửa migration đã merge:

```bash
#!/bin/bash
# .claude/hooks/guard-migrations.sh
set -euo pipefail
INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.input.file_path // .input.path // empty')"
# Chỉ guard folder migrations:
case "$FILE" in
  *db/migrations/*|*prisma/migrations/*) ;;
  *) exit 0 ;;
esac
# File đã commit (đã merge) → deny, bắt viết migration mới:
if git ls-files --error-unmatch "$FILE" >/dev/null 2>&1; then
  COMMITTED="$(git log --oneline -1 -- "$FILE" 2>/dev/null || true)"
  if [ -n "$COMMITTED" ]; then
    echo "{\"permissionDecision\":\"deny\",\"reason\":\"BLOCKED: $FILE đã merge ($COMMITTED). Viết migration MỚI, không sửa file này.\"}"
    exit 2
  fi
fi
exit 0
```

**Hook 4 — cost-ledger (Stop)** — đọc token usage từ logs, quy ra $, append daily ledger:

```bash
#!/bin/bash
# .claude/hooks/cost-ledger.sh
set -euo pipefail
INPUT="$(cat)"
DATE="$(date +%F)"
LEDGER="${CLAUDE_PROJECT_DIR:-.}/.claude/cost-ledger.csv"
mkdir -p "$(dirname "$LEDGER")"
[ -f "$LEDGER" ] || echo "date,tokens_in,tokens_out,note" > "$LEDGER"
# Lấy usage từ event (keys tùy version — fallback unknown):
IN="$(echo "$INPUT" | jq -r '.usage.input_tokens // "?"')"
OUT="$(echo "$INPUT" | jq -r '.usage.output_tokens // "?"')"
echo "$DATE,$IN,$OUT,stop-event" >> "$LEDGER"
# Quá cap (vd 1M tokens/ngày) → ping Slack (nếu có webhook):
# [ "$SLACK_WEBHOOK" ] && curl -fsS -X POST "$SLACK_WEBHOOK" -d "{\"text\":\"Cost alert $DATE: in=$IN out=$OUT\"}" >/dev/null
exit 0
```

**Hook 5 — session-context inject (SessionStart)** — in branch, ticket, env check vào context:

```bash
#!/bin/bash
# .claude/hooks/session-context.sh
set -euo pipefail
BRANCH="$(git branch --show-current 2>/dev/null || echo '?')"
STATUS="$(git status --short 2>/dev/null | head -5 || true)"
# Output JSON additionalContext (harness nhét vào session):
jq -n --arg branch "$BRANCH" --arg status "$STATUS" \
  '{additionalContext: ("Branch: \($branch)\nGit status (top5):\n\($status)\nNhắc: chạy focused test sau sửa, không push main.")}'
exit 0
```

```bash
# Cài + test (copy-paste):
chmod +x .claude/hooks/*.sh
# Trong session:
/hooks   # phải thấy 6 events trên với đúng matcher
# Test branch-protect:
# > "chạy git push origin main giúp anh"
# → hook deny, Claude báo BLOCKED. Nếu vẫn push được → xem mục 6 debug.
```

Thêm: prompt-hook kiểm tra câu chữ cần judgment (vd "commit message có leak secret?"),
agent-hook verify cần đọc code (experimental, production ưu tiên command hooks),
`SessionStart` inject context (branch hiện tại, ticket liên quan), `Stop` gate (script check, block turn-end
tới khi pass — tối đa 8 blocks liên tiếp rồi Claude override để thoát).

---

## 6. Walkthrough + debug flowchart

### 6.1. Walkthrough: thêm hook đầu tiên (10 phút)

```text
Bước 1: mkdir -p .claude/hooks, copy hook 2 (block-main-push.sh) vào.
Bước 2: chmod +x .claude/hooks/block-main-push.sh
Bước 3: Thêm vào .claude/settings.json (mục 4, phần PreToolUse Bash).
Bước 4: /hooks → xác nhận hiện. Mở session MỚI (hooks load lúc start).
Bước 5: Test: prompt "chạy git push origin main" → phải bị BLOCKED.
Bước 6: Test lọt: "git push -f", "git push --force-with-lease", "git push origin HEAD:main"
        → cả 4 phải block. Cái nào lọt → sửa regex.
```

### 6.2. Debug flowchart (hook không chạy → đi từng bước)

```text
Hook không chạy?
├─ 1. /hooks có hiện hook? ── Không → settings.json sai path/JSON parse lỗi
│                              → claude doctor (chỉ file lỗi), sửa JSON, mở session mới.
├─ 2. Event đúng? (Pre vs Post) ── Sai → vd muốn block phải PreToolUse, không phải Post.
├─ 3. Matcher đúng case? ── "edit" ≠ "Edit", "write" ≠ "Write", "bash" ≠ "Bash".
├─ 4. Folder đã trust? ── frontmatter hooks project-level cần trust dialog.
│                         -p session không trusted → bị skip (log ghi rõ).
├─ 5. Script +x + shebang? ── chmod +x, test chạy tay: echo '<json>' | ./hook.sh
├─ 6. Nhiều hooks overlap? ── 2 hook cùng rewrite updatedInput → finish cuối thắng.
│                              Tách matcher, đừng overlap.
└─ 7. Muốn nới (allow) nhưng vẫn deny? ── hook allow KHÔNG nới được deny/org ask.
                                          Hooks chỉ siết, không nới (bài 10).
```

```bash
# Debug tay (copy-paste):
echo '{"tool":"Bash","input":{"command":"git push origin main"}}' | .claude/hooks/block-main-push.sh; echo "exit=$?"
# Kỳ vọng: JSON deny + exit=2. Nếu exit=0 → regex sai, sửa.

echo '{"tool":"Bash","input":{"command":"git push origin feat/x"}}' | .claude/hooks/block-main-push.sh; echo "exit=$?"
# Kỳ vọng: exit=0 (cho qua). Nếu deny → regex quá tay (block cả feat).
```

### 6.3. Nhờ Claude viết hook

```
"Viết hook chạy eslint sau mỗi lần edit file .ts" / "Viết hook block writes vào thư mục migrations"
```

Claude sửa `.claude/settings.json` trực tiếp; bạn `/hooks` duyệt lại. Đối xử hooks như production code
(chạy với quyền của bạn, đọc FS + network + ghi disk).

---

## 7. Pitfalls + bài tập

| Pitfall | Vì sao | Fix |
|---|---|---|
| Hook `.sh` báo permission denied | Quên `chmod +x`, file từ Windows mất +x | `chmod +x .claude/hooks/*.sh` |
| Hook chạy local nhưng không chạy cloud | Hook file chưa commit / path khác | Commit `.claude/hooks/` + dùng `${CLAUDE_PROJECT_DIR}` |
| Lint hook chậm 8s mỗi edit | Lint cả repo thay vì file vừa sửa | Scope hẹp: chỉ file từ stdin, chỉ ext liên quan |
| 2 hooks cùng rewrite → non-deterministic | Overlap matcher | Mỗi rewrite 1 owner; còn lại chỉ read/block |
| Stop gate block mãi không thoát | Script luôn fail | Tối đa 8 blocks rồi override — nhưng fix script gốc, đừng trông vào override |
| Prompt-hook tốn token bất ngờ | `prompt` type gọi Haiku mỗi lần | Chỉ dùng prompt khi regex không làm được |
| Tin hook thay OS sandbox cho việc critical | Hook là shell, vẫn bypass được qua binary lạ | Việc critical → hook + sandbox + deny rules (bài 10) |

**Bài tập:**

**Bài 1 (15 phút):** Cài hook 2 (branch-protect). Test 4 lệnh push (mục 5). Ghi lại cái nào lọt.

**Bài 2 (15 phút):** Cài hook 1 (lint-on-write). Sửa 1 file `.ts` cố ý sai lint, xem Claude tự fix.
Đo thời gian hook chạy — >2s thì thu hẹp scope.

**Bài 3 (15 phút):** Cài hook 5 (session-context). Mở session mới, kiểm tra context có branch không.

**Bài 4 (20 phút):** Viết 1 prompt-hook ("commit message có leak secret?"). So sánh token cost
vs command-hook tương đương. Khi nào đáng dùng prompt?

**Bài 5 (15 phút):** Chạy debug flowchart mục 6.2 cho 1 hook cố ý cấu hình sai (sai matcher case).
Ghi lại bước nào bắt được lỗi.

---

## 8. Link chéo

- **Bài 00 — Tổng quan**: hooks 0 token + deterministic; rule miss 2 lần → nâng thành hook.
- **Bài 03 — CLAUDE.md**: advisory vs law; migrate rules hay miss sang hooks.
- **Bài 04 — Slash commands**: `/hooks` xem hooks, `/doctor` audit hooks chậm.
- **Bài 05 — Skills**: skill dạy "làm thế nào", hook bắt "phải làm".
- **Bài 06 — Subagents**: SubagentStart/Stop hooks, frontmatter hooks, conditional rules.
- **Bài 10 — Permissions**: hook deny thắng bypass; hook allow không nới deny/org.
- **Bài 12 — SDK/CI**: Setup hook cho CI warmup; PreToolUse cho `-p` automate permissions.
