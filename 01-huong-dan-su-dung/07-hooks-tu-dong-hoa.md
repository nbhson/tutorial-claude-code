# 07 — Hooks: tự động hóa tất định (luật, không phải gợi ý)

> **Bài này cho ai:** dev đã dùng CLAUDE.md/skills mà rule vẫn bị Claude quên, muốn nâng rule thành luật chạy thật.
> **Cần gì trước:** đã cài và đăng nhập (bài 01); nên đọc [bài 03](./03-claude-md-memory-rules.md) để phân biệt "gợi ý" với "luật".
> **Đọc xong bạn làm được:** giải thích vì sao hook chạy 0 token model + chặn được cả khi bật `--dangerously-skip-permissions`; copy full `settings.json` mẫu + 5 hooks hoàn chỉnh; chọn đúng event/matcher/type; debug hook không chạy bằng flowchart 7 bước.
> **Thời gian:** ~40 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Hook | Aptomat tự nhảy: harness tự chạy lệnh, không hỏi model | Sau mỗi `Edit` tự chạy `eslint` |
| Event | Tín hiệu 1 việc vừa xảy ra | `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop` |
| Matcher | Lọc "hook này áp cho tool nào" (nhiều tool nối `\|`) | `Bash`, `Edit\|Write` — **case-sensitive** |
| Exit code | 0 = cho qua, 2 = chặn | `exit 2` kèm `permissionDecision: deny` |
| stdin/stdout | Ống dẫn JSON đưa vào hook + kết quả trả ra | `INPUT="$(cat)"` |
| Type của hook | `command` (shell), `http`, `mcp_tool`, `prompt`, `agent` | 95% việc dùng `command` |
| Advisory vs law | Gợi ý thì Claude có thể quên; luật bắt buộc chạy | CLAUDE.md = gợi ý, hook = luật |

## Mục lục

1. [Hook là gì và vì sao luật thắng gợi ý](#1-hook-là-gì-và-vì-sao-luật-thắng-gợi-ý)
2. [Các event + type](#2-các-event--type)
3. [Cấu hình settings.json + hợp đồng stdin/stdout](#3-cấu-hình-settingsjson--hợp-đồng-stdinstdout)
4. [Full settings.json mẫu + 5 hooks hoàn chỉnh](#4-full-settingsjson-mẫu--5-hooks-hoàn-chỉnh)
5. [Walkthrough + debug khi hook không chạy](#5-walkthrough--debug-khi-hook-không-chạy)
6. [Bẫy, bài tập, link](#6-bẫy-bài-tập-link)

---

## 1. Hook là gì và vì sao luật thắng gợi ý

**Nôm na 1 câu:** Hook là *khóa cửa tự động* — tới giờ là khóa, không cần hỏi chủ nhà (model) có muốn khóa không.

```bash
mkdir -p .claude/hooks
cat > .claude/hooks/block-main-push.sh <<'EOS'
#!/bin/bash
set -euo pipefail
INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.input.command // empty')"
if echo "$CMD" | grep -Eq 'git[[:space:]]+push.*(main|master)'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: không push trực tiếp main. Mở PR."}'
  exit 2
fi
exit 0
EOS
chmod +x .claude/hooks/block-main-push.sh
# Verify: echo '{"input":{"command":"git push origin main"}}' | .claude/hooks/block-main-push.sh; echo "exit=$?"
```

**Vì sao hook chắc chắn hơn CLAUDE.md:** hook chạy **ngoài model** (harness chạy shell, không qua LLM — trừ type `prompt`/`agent`) → 0 model tokens, không bị prompt-injection thuyết phục, chạy trước cả `bypassPermissions`/`--dangerously-skip-permissions`, và **chỉ siết không nới** (hook allow không thắng được deny rules hay `ask` của org — sửa deny gốc ở bài 10).

```text
CLAUDE.md "NEVER push main"   → Claude đọc, gật gù, đôi khi vẫn push (quên/misread)
PreToolUse hook match push    → block 100%, kể cả --dangerously-skip-permissions
```

> Công thức cả bài: **CLAUDE.md/skills = gợi ý (advisory) — hook = luật (law, chạy chắc)**. Rule bị Claude miss ≥2 lần → nâng thành hook. Mọi team cần ít nhất hook block-push-main + lint-on-write.

---

## 2. Các event + type

| Event | Khi lửa | Dùng cho |
|---|---|---|
| `SessionStart` | Session bắt đầu/resume | Inject context (branch, ticket, env check) |
| `Setup` | `claude --init-only` / `--init` trong `-p` | CI warmup (bài 12) |
| `UserPromptSubmit` | User submit prompt | Block/redirect prompt nguy hiểm, log |
| `PreToolUse` | Trước tool call (**block được**), chạy trước mọi permission check | Guard rails (branch-protect, migration-guard) |
| `PermissionRequest` / `PermissionDenied` | Tool cần quyết định quyền / auto mode deny | Custom permission UI; `retry: true` gợi ý lệnh đúng |
| `PostToolUse` / `PostToolUseFailure` | Sau tool thành công/thất bại | Lint-on-write, format, log |
| `PostToolBatch` | Sau cả batch parallel tool calls | Tổng hợp batch (check tổng files đổi) |
| `Notification` | Claude gửi notification | Ping Slack/osascript |
| `SubagentStart`/`SubagentStop` | Subagent spawn/finish (matcher = tên agent) | Log cost, inject context |
| `TaskCreated`/`TaskCompleted` | Task lifecycle | Tracking, ledger |
| `Stop` / `StopFailure` | Turn kết thúc (không lửa khi user interrupt) | Cost ledger; gate block turn-end tới khi pass (tối đa 8 blocks) |
| `TeammateIdle` | Teammate agent-team sắp idle | Giao việc tiếp (teams) |
| `InstructionsLoaded` | 1 file CLAUDE.md/rules vừa load | Validate/audit memory load |
| `PreCompact`/`PostCompact`, `ConfigChange` | Compaction/config | Backup context trước compact |

| Type | Khi nào | Ví dụ |
|---|---|---|
| `command` | 95% cases — deterministic, nhanh, 0 token | Lint, block push, guard migrations |
| `prompt` | Cần judgment ngôn ngữ (regex không được) | "Commit message có leak secret không?" |
| `agent` | Verify cần đọc code multi-turn (experimental) | Review diff trước khi cho push |
| `http` / `mcp_tool` | Đẩy event ra hệ ngoài / gọi tool MCP đã connect | Log sang ticketing; PostToolUse → tạo ticket Linear |

> Hooks nhận được cả **effort level** hiện tại trong event JSON (w19/2026) — có thể siết chặt hơn khi effort thấp.

---

## 3. Cấu hình settings.json + hợp đồng stdin/stdout

Thứ tự ưu tiên: `managed policy (org) > .claude/settings.local.json (personal, không commit) > .claude/settings.json (team, commit) > ~/.claude/settings.json`. Xem merged result bằng `/permissions` — đừng đoán.

```text
1. Harness gửi event JSON qua STDIN: {"tool":"Bash","input":{"command":"git push origin main"},"cwd":"..."}
2. Hook đọc stdin (jq/python), quyết định:
   - Exit 0 (+ optional {"permissionDecision":"allow"})   → cho qua
   - Exit 2 / {"permissionDecision":"deny","reason":"..."} → block, reason hiện cho Claude + user
   - {"updatedInput":{...}}                                → rewrite input (vd thêm --dry-run)
   - Stop gate: {"decision":"block","reason":"tests fail"} → Claude fix tiếp (tối đa 8 blocks)
```

- Matcher **case-sensitive** (`Edit` ≠ `edit`). Nhiều hooks cùng event chạy song song; 2 hook cùng rewrite `updatedInput` → thằng finish cuối thắng (non-deterministic — tránh overlap).
- Hook lỗi/timeout mặc định **thả qua**; đặt `onFailure: "block"` (≥2.1.295) để chặn khi hook lỗi — dùng cho guard bảo mật.

---

## 4. Full settings.json mẫu + 5 hooks hoàn chỉnh

```json
{
  "$schema": "https://claude.ai/code/settings-schema.json",
  "permissions": {
    "allow": ["Read", "Glob", "Grep", "Bash(pnpm test:*)", "Bash(git diff:*)", "Bash(git status:*)"],
    "ask": ["Edit", "Write", "Bash(pnpm:*)", "Bash(git push:*)"],
    "deny": ["Bash(rm -rf:*)", "Bash(git push origin main:*)", "Write(.env*)"]
  },
  "hooks": {
    "SessionStart": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/session-context.sh" }],
    "PreToolUse": [
      { "matcher": "Bash",  "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-main-push.sh" },
      { "matcher": "Write", "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard-migrations.sh" }
    ],
    "PostToolUse": [{ "matcher": "Edit|Write", "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-on-write.sh" }],
    "Stop":        [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/cost-ledger.sh" }],
    "Notification":[{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/notify.sh" }],
    "SubagentStop":[{ "matcher": "explorer|tester", "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/log-subagent.sh" }]
  }
}
```

**Hook 1 — lint-on-write (PostToolUse Edit|Write)** — format/lint file vừa sửa, lỗi trả lại cho agent fix ngay:

```bash
#!/bin/bash
# .claude/hooks/lint-on-write.sh — chỉ lint file vừa sửa, đừng lint cả repo (chậm 8s+)
set -euo pipefail
INPUT="$(cat)"
FILES="$(echo "$INPUT" | jq -r '.input.file_path // .input.path // empty')"
[ -z "$FILES" ] && exit 0
echo "$FILES" | tr ' ' '\n' | grep -E '\.(ts|tsx|js|jsx)$' | while read -r f; do
  [ -f "$f" ] || continue
  npx prettier --write "$f" >/dev/null 2>&1 || true
  npx eslint "$f" --max-warnings 0
done
# eslint fail → exit nonzero → PostToolUseFailure → Claude thấy lỗi, fix ngay.
```

**Hook 2 — branch-protect (PreToolUse Bash)** — match theo INTENT, không substring "main":

```bash
#!/bin/bash
# .claude/hooks/block-main-push.sh — block push main/master, force-push, xóa branch remote
set -euo pipefail
INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.input.command // empty')"
if echo "$CMD" | grep -Eq 'git[[:space:]]+push([^&|;]*[[:space:]]|^)(origin[[:space:]]+)?(HEAD:)?(main|master)([[:space:]]|$)'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: không push trực tiếp main. Mở PR từ branch feat/*."}'; exit 2
fi
if echo "$CMD" | grep -Eq '\-\-force($|[[:space:]])|-f([[:space:]]|$)|--force-with-lease'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: force-push bị cấm. Dùng rebase thường."}'; exit 2
fi
if echo "$CMD" | grep -Eq 'git[[:space:]]+push[[:space:]]+[^ ]*[[:space:]]+--delete|:heads/'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: xóa branch remote cần xác nhận tay."}'; exit 2
fi
exit 0
# Test với: git push -f, git push --force, git push --force-with-lease, git push origin HEAD:main.
```

**Hook 3 — guard-migrations (PreToolUse Write)** — block sửa migration đã merge:

```bash
#!/bin/bash
set -euo pipefail
INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.input.file_path // .input.path // empty')"
case "$FILE" in *db/migrations/*|*prisma/migrations/*) ;; *) exit 0 ;; esac
if git ls-files --error-unmatch "$FILE" >/dev/null 2>&1; then
  echo "{\"permissionDecision\":\"deny\",\"reason\":\"BLOCKED: $FILE đã merge. Viết migration MỚI.\"}"; exit 2
fi
```

**Hook 4 — cost-ledger (Stop)** — append token usage vào CSV hàng ngày:

```bash
#!/bin/bash
set -euo pipefail
INPUT="$(cat)"
LEDGER="${CLAUDE_PROJECT_DIR:-.}/.claude/cost-ledger.csv"
[ -f "$LEDGER" ] || echo "date,tokens_in,tokens_out,note" > "$LEDGER"
echo "$(date +%F),$(echo "$INPUT" | jq -r '.usage.input_tokens // "?"'),$(echo "$INPUT" | jq -r '.usage.output_tokens // "?"'),stop-event" >> "$LEDGER"
# Quá cap → ping Slack webhook nếu có.
```

**Hook 5 — session-context (SessionStart)** — inject branch + git status vào context:

```bash
#!/bin/bash
set -euo pipefail
BRANCH="$(git branch --show-current 2>/dev/null || echo '?')"
STATUS="$(git status --short 2>/dev/null | head -5 || true)"
jq -n --arg b "$BRANCH" --arg s "$STATUS" \
  '{additionalContext: ("Branch: \($b)\nGit status (top5):\n\($s)\nNhắc: chạy focused test sau sửa, không push main.")}'
```

Cài: `chmod +x .claude/hooks/*.sh` → `/hooks` xác nhận → mở session MỚI (hooks load lúc start). Ngoài 5 hook trên: Stop gate (script check, block turn-end tới khi pass), prompt-hook (judgment câu chữ), agent-hook (verify multi-turn — production ưu tiên command hooks).

---

## 5. Walkthrough + debug khi hook không chạy

**Thêm hook đầu tiên (10 phút):**

```text
1. mkdir -p .claude/hooks + copy hook 2 (block-main-push.sh)
2. chmod +x .claude/hooks/block-main-push.sh
3. Thêm vào .claude/settings.json (mục 4, PreToolUse Bash)
4. /hooks → xác nhận hiện; mở session MỚI
5. Test: prompt "chạy git push origin main" → phải BLOCKED
6. Test lọt: "git push -f", "--force", "--force-with-lease", "git push origin HEAD:main" → cả 4 phải block
```

**Debug flowchart — hook không chạy:**

```text
Hook không chạy?
├─ 1. /hooks có hiện hook?          Không → settings.json sai path/JSON parse lỗi → claude doctor, sửa, mở session mới
├─ 2. Event đúng?                   Muốn block phải PreToolUse, không phải Post
├─ 3. Matcher đúng case?            "edit" ≠ "Edit", "bash" ≠ "Bash"
├─ 4. Folder đã trust?              Frontmatter hooks project-level cần trust dialog; -p session không trusted → bị skip
├─ 5. Script +x + shebang?          chmod +x; test tay: echo '<json>' | ./hook.sh
├─ 6. Nhiều hooks overlap?          2 hook cùng rewrite updatedInput → finish cuối thắng. Tách matcher
└─ 7. Muốn nới nhưng vẫn deny?      Hook allow KHÔNG nới được deny/org ask — hooks chỉ siết (bài 10)
```

```bash
# Debug tay:
echo '{"tool":"Bash","input":{"command":"git push origin main"}}'    | .claude/hooks/block-main-push.sh; echo "exit=$?"   # kỳ vọng 2
echo '{"tool":"Bash","input":{"command":"git push origin feat/x"}}'  | .claude/hooks/block-main-push.sh; echo "exit=$?"   # kỳ vọng 0
```

Nhờ Claude viết hook: "Viết hook chạy eslint sau mỗi lần edit file .ts" — Claude sửa settings.json, bạn `/hooks` duyệt lại. Đối xử hooks như production code (chạy với quyền của bạn, đọc FS + network + ghi disk).

---

## 6. Bẫy, bài tập, link

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| "Hook tốn tokens như gọi LLM" | `command` hooks chạy shell ngoài model → 0 tokens. Chỉ `prompt`/`agent` hooks tốn |
| "Hook allow nới được deny" | Không — hooks chỉ siết, không nới (bài 10) |
| "Rules settings.json đủ chặn, khỏi hook" | Rules prefix-match lọt `HEAD:main`, `-f` chen giữa, binary khác. Chắc chắn → hook match theo intent |
| "Matcher không phân biệt hoa thường" | Có phân biệt — sai case là hook im lặng |
| "Hook thay được OS sandbox" | Hook vẫn bypass được qua binary lạ. Critical → hook + sandbox + deny rules (bài 10) |

### Bẫy cấu hình + fix

| Bẫy | Fix |
|---|---|
| Hook `.sh` báo permission denied | `chmod +x .claude/hooks/*.sh` (file từ Windows mất +x) |
| Chạy local nhưng không chạy cloud | Commit `.claude/hooks/` + dùng `${CLAUDE_PROJECT_DIR}` |
| Lint hook chậm 8s mỗi edit | Scope hẹp: chỉ file từ stdin, chỉ ext liên quan |
| 2 hooks cùng rewrite → non-deterministic | Mỗi rewrite 1 owner; còn lại chỉ read/block |
| Stop gate block mãi không thoát | Tối đa 8 blocks rồi override — nhưng fix script gốc |
| Prompt-hook tốn token bất ngờ | Chỉ dùng `prompt` khi regex không làm được |

### Bài tập

1. (15') Cài hook 2 (branch-protect); test 4 lệnh push, ghi lại cái nào lọt.
2. (15') Cài hook 1 (lint-on-write); sửa 1 file `.ts` sai lint, xem Claude tự fix; >2s → thu hẹp scope.
3. (15') Cài hook 5 (session-context); session mới kiểm tra context có branch.
4. (20') Viết 1 prompt-hook ("commit message có leak secret?"); so token cost vs command-hook.
5. (15') Chạy debug flowchart cho 1 hook cấu hình sai cố ý (matcher thường); ghi lại bước bắt được lỗi.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: hooks 0 token; **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)**: advisory vs law.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/hooks`, `/doctor` audit hooks chậm; **[05 — Skills](./05-skills-custom-commands.md)**: skill dạy "làm thế nào", hook bắt "phải làm".
- **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: SubagentStart/Stop hooks; **[10 — Permissions](./10-permissions-modes-availability.md)**: hook deny thắng bypass, hook allow không nới org; **[12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md)**: Setup hook cho CI warmup.
