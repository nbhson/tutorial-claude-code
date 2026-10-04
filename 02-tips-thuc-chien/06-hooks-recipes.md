# Tips 06 — Hooks Recipes: Biến Mọi Rule Hay Quên Thành Luật

> **Rule bị miss 2 lần → viết thành hook.** Hooks chạy ngoài model: 0 tokens, không bị thuyết phục, không mệt. Bài này cho 3 recipes bắt buộc (code đầy đủ) + 3 nâng cao + 5 loại hook + 5 bẫy.

## Mục lục

- [1. Triết lý + cơ chế hooks](#1-triết-lý--cơ-chế-hooks)
- [2. Ba recipes bắt buộc (code đầy đủ)](#2-ba-recipes-bắt-buộc-code-đầy-đủ)
- [3. Ba recipes nâng cao](#3-ba-recipes-nâng-cao)
- [4. Năm loại hook: command/prompt/agent/http/mcp](#4-năm-loại-hook-commandpromptagenthttpmcp)
- [5. Walkthrough: lắp hooks cho repo mới trong 30 phút](#5-walkthrough-lắp-hooks-cho-repo-mới-trong-30-phút)
- [6. Bảng chọn hook theo vấn đề + checklist](#6-bảng-chọn-hook-theo-vấn-đề--checklist)
- [7. Năm bẫy thường gặp (+ thêm 2 bẫy version)](#7-năm-bẫy-thường-gặp--thêm-2-bẫy-version)
- [8. Pitfalls + fix nhanh](#8-pitfalls--fix-nhanh)
- [9. Bài tập](#9-bài-tập)
- [10. Tham khảo chéo](#10-tham-khảo-chéo)

---

## 1. Triết lý + cơ chế hooks

### 1.1. Triết lý 1 dòng

> **Rule bị miss 2 lần → viết thành hook.**

- Nhắc bằng lời lần 1: "nhớ chạy lint" → quên.
- Nhắc lần 2: "tôi đã bảo chạy lint" → vẫn quên khi vội.
- Lần 3: đừng nhắc nữa, viết hook tự chạy lint sau mỗi edit.

### 1.2. Cơ chế: hooks chạy ở đâu?

```text
[Bạn/Claude định làm gì] --> [Hook PreToolUse: cho hay chặn?]
        |
[Tool chạy xong] --> [Hook PostToolUse: lint? format? ghi log?]
        |
[Turn định kết thúc] --> [Hook Stop: test xanh chưa? quá cost cap chưa?]
        |
[Session bắt đầu/kết thúc] --> [SessionStart/SessionEnd: nạp branch, tóm tắt, sync docs]
```

- Hooks chạy **ngoài model** (shell script, LLM 1-turn, agent, HTTP, MCP) → 0 tokens cho rule lặp lại.
- Hook có thể: **cho qua**, **chặn + báo lý do**, **sửa input** (`updatedInput`), **ghi log**.
- Hooks là production code (chạy với quyền của bạn): review như code, version như code.

### 1.3. Khi nào hook vs skill vs prompt?

| Dùng gì | Khi nào | Ví dụ |
|---|---|---|
| Prompt (1 câu) | Việc 1 lần, ít lặp | "Lần này nhớ chạy test X" |
| Skill (`/lint`, `/deploy`) | Quy trình cần judgment, gọi khi cần | Deploy checklist, review |
| Hook | Rule lặp lại, phải đúng 100%, không tin LLM | Lint sau edit, cấm push main, cost cap |

> Rule ngón tay: **việc làm 1 lần → prompt. Việc cần người quyết → skill. Việc máy check được + lặp lại → hook.**

---

## 2. Ba recipes bắt buộc (code đầy đủ)

Cả 3 đều sống trong `settings.json` (commit được) + scripts trong `hooks/` (commit được). Secrets chỉ qua env vars.

### a) Lint-on-write — `PostToolUse` match `Edit|Write`

**Mục tiêu:** sau mỗi edit, chạy prettier/eslint đúng file vừa đổi. Lỗi → trả cho agent fix ngay turn sau. Không bao giờ dồn thành cleanup 40 files cuối tuần.

**`settings.json` (copy-paste):**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/lint-on-write.sh" }
        ]
      }
    ]
  }
}
```

**`hooks/lint-on-write.sh` (copy-paste):**

```bash
#!/usr/bin/env bash
# Lint file vừa edit. Đọc tool input từ stdin JSON, lấy file path.
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")

# Bỏ qua file không cần lint
case "$FILE" in
  ""|*.md|*.json|*generated*|*.min.js) exit 0 ;;
esac

# Chỉ lint file trong project
case "$FILE" in
  *node_modules*|*.git/*) exit 0 ;;
esac

if [[ "$FILE" == *.ts || "$FILE" == *.tsx || "$FILE" == *.js ]]; then
  # Prettier check + eslint đúng file đó (nhanh, không full repo)
  npx prettier --check "$FILE" 2>&1 || npx prettier --write "$FILE" 2>&1
  npx eslint "$FILE" 2>&1 || exit 2
fi

if [[ "$FILE" == *.py ]]; then
  ruff check "$FILE" 2>&1 || exit 2
  ruff format --check "$FILE" 2>&1 || true
fi

exit 0
# exit 0 = cho qua, exit 2 = báo lỗi cho agent (block + hiện output), exit !=0 khác = chặn
```

**Test 3 ca trước khi tin:**

```bash
echo '{"tool_input":{"file_path":"src/a.ts"}}' | ./hooks/lint-on-write.sh; echo "exit=$?"
# → sửa src/a.ts cho sai lint, edit lại, xem hook có báo không
# → tạo file .md, edit, xem hook có bỏ qua không
# → tạo file generated/foo.ts, edit, xem hook có bỏ qua không
```

### b) Branch-protect — `PreToolUse` match `Bash`

**Mục tiêu:** block push lên `main`, mọi force-push, xóa branch, `push origin HEAD:main`. **Match theo intent, không substring.**

**`settings.json`:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/branch-protect.sh" }
        ]
      }
    ]
  }
}
```

**`hooks/branch-protect.sh` (copy-paste, đã xử lý 4 ca push):**

```bash
#!/usr/bin/env bash
# Chặn git nguy hiểm. Parse intent, không substring "main".
set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))")

# Không phải git → cho qua
echo "$CMD" | grep -qE '(^|[;&| ])git ' || exit 0

# Chuẩn hóa: tách lệnh nối bằng && ; || thành từng lệnh
normalize() { echo "$1" | tr ';' '\n' | sed 's/&&/\n/g; s/||/\n/g'; }

echo "$CMD" | while IFS= read -r line; do
  # 1. Mọi force-push: -f, --force, --force-with-lease (kể cả dạng rút gọn)
  if echo "$line" | grep -qE 'git\s+push\b.*(--force-with-lease|--force\b|-f\b)'; then
    echo "BLOCKED: force-push bị cấm (dù ở branch nào). Dùng PR + merge thay vì push -f." >&2
    exit 2
  fi
  # 2. Push trực tiếp lên main/master (mọi remote, mọi cú pháp HEAD:main)
  if echo "$line" | grep -qE 'git\s+push\b.*(\bmain\b|\bmaster\b|HEAD:main|HEAD:master)'; then
    echo "BLOCKED: push thẳng main/master bị cấm. Push lên feature branch + mở PR." >&2
    exit 2
  fi
  # 3. Xóa branch (local/remote)
  if echo "$line" | grep -qE 'git\s+(branch\s+-D|branch\s+--delete|push\b.*--delete)'; then
    echo "BLOCKED: xóa branch cần human duyệt. Không tự xóa trong agent." >&2
    exit 2
  fi
done
STATUS=${PIPESTATUS[1]:-0}
exit "$STATUS"
```

**Test 4 ca bắt buộc trước khi tin (copy-paste):**

```bash
run() { echo "{\"tool_input\":{\"command\":\"$1\"}}" | ./hooks/branch-protect.sh; echo "[$1] exit=$?"; }
run "git push -f origin feat/x"
run "git push --force origin feat/x"
run "git push --force-with-lease origin feat/x"
run "git push origin HEAD:main"
# Cả 4 phải exit=2 (blocked). Thêm ca对照:
run "git push origin feat/my-main-fix"
# → phải exit=0 (cho qua — chứng minh không substring "main" bừa)
run "git status"
# → exit=0
```

### c) Cost-cap — `Stop`

**Mục tiêu:** đọc token usage từ logs → quy $ theo pricing hiện tại → append daily ledger → quá cap ping Slack. Bảo hiểm rẻ nhất, add sớm bất kể project lớn nhỏ.

**`settings.json`:**

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/cost-cap.sh" }
        ]
      }
    ]
  }
}
```

**`hooks/cost-cap.sh` (copy-paste, sửa CAP + webhook):**

```bash
#!/usr/bin/env bash
# Append daily ledger + cảnh báo Slack khi quá cap.
set -euo pipefail

# --- Cấu hình (sửa cho team bạn) ---
DAILY_CAP_USD="${DAILY_CAP_USD:-20}"
LEDGER_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/ledger"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
# Giá ví dụ — đối chiếu pricing hiện tại của provider trước khi dùng
PRICE_INPUT_PER_1K="${PRICE_INPUT_PER_1K:-0.003}"
PRICE_OUTPUT_PER_1K="${PRICE_OUTPUT_PER_1K:-0.015}"

mkdir -p "$LEDGER_DIR"
TODAY=$(date +%F)
LEDGER="$LEDGER_DIR/cost-$TODAY.jsonl"

INPUT=$(cat)
# Stop hook nhận transcript + usage tùy version — parse defensive
TOKENS_IN=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('input_tokens',0))" 2>/dev/null || echo 0)
TOKENS_OUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)

COST=$(python3 -c "print($TOKENS_IN/1000*$PRICE_INPUT_PER_1K + $TOKENS_OUT/1000*$PRICE_OUTPUT_PER_1K)")
echo "{\"ts\":\"$(date -Is)\",\"in\":$TOKENS_IN,\"out\":$TOKENS_OUT,\"cost_usd\":$COST}" >> "$LEDGER"

TOTAL=$(python3 -c "import json; print(sum(json.loads(l).get('cost_usd',0) for l in open('$LEDGER')))")
OVER=$(python3 -c "print(1 if $TOTAL > float($DAILY_CAP_USD) else 0)")

if [[ "$OVER" == "1" ]]; then
  MSG="Cost-cap: hôm nay đã $TOTAL USD (cap $DAILY_CAP_USD). Session tiếp theo nên /clear + Haiku cho explore."
  echo "$MSG" >&2
  if [[ -n "$WEBHOOK_URL" ]]; then
    curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MSG\"}" "$WEBHOOK_URL" >/dev/null || true
  fi
  # Không block (exit 0) — chỉ cảnh báo. Muốn chặn cứng thì exit 2.
fi
exit 0
```

**Kiểm tra:**

```bash
DAILY_CAP_USD=0.01 ./hooks/cost-cap.sh < /dev/null; echo "exit=$?"
cat .claude/ledger/cost-$(date +%F).jsonl | tail -n 3
# → thấy ledger append + cảnh báo khi quá cap
```

---

## 3. Ba recipes nâng cao

### 1. Guard sensitive paths (`PreToolUse` Write)

Block writes vào `migrations/`, `*.pem`, `.env*`, `generated/`.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/guard-paths.sh" }]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
set -euo pipefail
INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")
case "$FILE" in
  *migrations/*|*.pem|*.key|.env*|*generated*|*dist/*)
    echo "BLOCKED: $FILE là vùng cấm. Muốn sửa cần human duyệt + ghi lý do vào PR." >&2
    exit 2 ;;
esac
exit 0
```

### 2. Test-gate (`Stop`)

Script chạy focused tests, block turn-end tới khi xanh (tối đa 8 lần).

```json
{
  "hooks": {
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/test-gate.sh" }] }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# test-gate.sh — sửa lệnh test cho repo bạn. Tối đa 8 blocks là giới hạn của Claude Code.
set -euo pipefail
SCOPE="${TEST_SCOPE:-payments}"
pnpm --filter "$SCOPE" test 2>&1 | tail -n 25
STATUS=${PIPESTATUS[0]:-0}
if [[ "$STATUS" != "0" ]]; then
  echo "BLOCKED: test scope $SCOPE còn đỏ. Fix rồi mới được kết thúc turn (còn lại <8 blocks)." >&2
  exit 2
fi
exit 0
```

> Dùng kèm `/goal` + reviewer cuối (xem [Tips 04](./04-verification-done-that.md)). Gate đảm bảo "xanh", reviewer đảm bảo "đúng".

### 3. SessionStart inject

Tự nạp branch hiện tại, ticket liên quan, `git status` tóm tắt vào context.

```json
{
  "hooks": {
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/session-start.sh" }] }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# session-start.sh — in context tươi ra stdout (Claude đọc được lúc mở session)
set -euo pipefail
echo "=== session-start ==="
echo "branch: $(git branch --show-current 2>/dev/null || echo unknown)"
echo "status:"
git status --short 2>/dev/null | head -n 20 || true
echo "recent:"
git log --oneline -5 2>/dev/null || true
echo "ticket: $(git branch --show-current 2>/dev/null | grep -oE '[A-Z]+-[0-9]+' | head -n 1 || echo none)"
echo "rule: 1 task 1 session. Đổi task thì /clear."
```

Biến thể dynamic line trong skill (cần data tươi mà không cần hook):

```markdown
`!`git branch --show-current``
```

---

## 4. Năm loại hook: command/prompt/agent/http/mcp

| Loại | Chạy bằng gì | Khi dùng | Ví dụ |
|---|---|---|---|
| `command` (shell, default) | Script bash/python | Mọi thứ deterministic — production ưu tiên | Lint, branch-protect, test-gate, cost-cap, guard-paths |
| `prompt` (LLM 1-turn, Haiku default) | Model 1 turn đọc input | Quyết định cần judgment từ input data | Commit msg có leak secret? Diff này có đụng migrate không? |
| `agent` (experimental, 60s/50 turns) | Subagent thật | Verify cần đọc code/chạy lệnh thật | Pre-push: đọc diff + chạy smoke rồi mới cho push |
| `http` | POST ra ngoài | Báo tin / ghi ledger remote | Ping Slack khi cost quá cap, ghi audit log |
| `mcp_tool` | Gọi MCP tool trong hook | Cần data từ MCP (tickets, CI) | SessionStart: lấy ticket Jira/Linear gắn branch |

### Ví dụ `prompt` hook (commit-msg secret check)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Đọc command trong tool input. Nếu là `git commit` và message hoặc diff có vẻ chứa secret (AKIA, ghp_, sk-, -----BEGIN PRIVATE KEY, .pem, .env), trả về BLOCK với lý do. Còn lại ALLOW.",
            "model": "haiku"
          }
        ]
      }
    ]
  }
}
```

### Ví dụ `agent` hook (pre-push smoke, experimental)

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "agent", "prompt": "Đọc `git diff main...HEAD --stat` + chạy `pnpm --filter payments test`. Chỉ ALLOW nếu test xanh và diff chỉ chạm src/payments/**.", "timeout": 60, "maxTurns": 50 }] }
    ]
  }
}
```

> Rule: **production ưu tiên `command`.** `prompt`/`agent` để judgment, `http`/`mcp_tool` để tích hợp ngoài.

---

## 5. Walkthrough: lắp hooks cho repo mới trong 30 phút

| Phút | Việc | Lệnh |
|---|---|---|
| 0–5 | Tạo khung | `mkdir -p hooks .claude/ledger && chmod +x hooks/*.sh`, copy 3 scripts mục 2 |
| 5–15 | Gắn settings + test | Ghép 3 blocks `settings.json` mục 2 → test 4 ca push + 3 ca lint → `/hooks` kiểm tra matcher/event |
| 15–25 | Guard + test-gate | Copy `guard-paths.sh` + `test-gate.sh`, sửa `TEST_SCOPE`; làm đỏ 1 test → xác nhận block (exit 2) |
| 25–30 | SessionStart + commit | Copy `session-start.sh`, mở session mới xem branch/status → `git add settings.json hooks/ && git commit` + 1 dòng vào `CLAUDE.md` |

Xong: mọi rule hay quên đã thành luật. Mai onboarding người mới chỉ cần pull là có.

---

## 6. Bảng chọn hook theo vấn đề + checklist

| Vấn đề lặp lại | Hook + event | Recipe |
|---|---|---|
| Quên lint/format | `PostToolUse` Edit/Write | 2a lint-on-write |
| Push nhầm main / force-push | `PreToolUse` Bash | 2b branch-protect |
| Không biết tiền đi đâu | `Stop` | 2c cost-cap |
| Sửa nhầm migrations/secrets | `PreToolUse` Write/Edit | 3.1 guard-paths |
| Turn-end mà test còn đỏ | `Stop` | 3.2 test-gate |
| Mở session quên branch/ticket | `SessionStart` | 3.3 session-start |
| Commit leak secret | `prompt` PreToolUse Bash | Mục 4 ví dụ prompt hook |
| Push cần smoke thật | `agent` PreToolUse Bash | Mục 4 ví dụ agent hook |

**Checklist trước khi commit hooks:**

- [ ] Matcher đúng (case-sensitive)? Event đúng (Pre vs Post vs Stop vs SessionStart)?
- [ ] Test đủ ca (4 ca push, 3 ca lint, đỏ/xanh test-gate)?
- [ ] `exit 0` (cho qua) vs `exit 2` (block) đúng ý?
- [ ] Không overlap `updatedInput` giữa 2 hooks (mục 7)?
- [ ] Chạy được headless (`-p` + background subagents)?
- [ ] Secrets chỉ qua env vars, không hardcode webhook/token?
- [ ] `chmod +x`, path dùng `${CLAUDE_PROJECT_DIR}` (không hardcode `/Users/...`)?

---

## 7. Năm bẫy thường gặp (+ thêm 2 bẫy version)

1. **Matcher case-sensitive, sai event.** `edit|write` không match `Edit|Write`. `Pre` vs `Post` ngược nhau → hook chạy sai thời điểm. Fix: `/hooks` kiểm tra + test từng event.
2. **2 hooks cùng rewrite `updatedInput`.** Thằng finish cuối thắng (non-deterministic). Fix: đừng overlap — mỗi hook 1 field/input riêng, hoặc gộp thành 1 script.
3. **`-p` non-interactive + background subagents không hiện prompt flows.** Hook chờ input người là treo. Fix: thiết kế hooks chạy headless (không `read`, không mở editor, timeout rõ).
4. **Hooks là production code nhưng review như đồ chơi.** Hook chạy với quyền của bạn (xóa file, push, gửi webhook được). Fix: review như code, test như code, không curl pipe bash lạ vào hooks/.
5. **Substring match (`main`).** `feat/my-main-fix` bị chặn oan, `HEAD:main` lọt. Fix: match intent bằng regex (mục 2b) + test 4 ca + 2 ca对照.
6. **Bẫy version (2025–2026 đổi schema).** `tools` frontmatter, PreToolUse stdin schema từng đổi — hook chặn CI push viết năm ngoái có thể lặng lẽ không chạy năm nay. Fix: đối chiếu release notes trước khi đặt hook chặn CI/push; pin version Claude trong team ([Tips 09](./09-teamwork-chuan-hoa.md)).
7. **Hook chậm làm mọi turn chậm.** `test-gate` chạy full suite 5 phút mỗi turn-end = tự DDoS mình. Fix: focused scope (`TEST_SCOPE`), cache, timeout, chỉ gate ở Stop (không gate ở PostToolUse).

---

## 8. Pitfalls + fix nhanh

Pitfalls triển khai (không chạy, chặn oan, treo CI, chậm, hardcode path, quên `chmod +x`, không version) xem chi tiết ở 7 bẫy mục 7 — cùng một gốc: **sai matcher/event, regex rộng, thiếu test ca, thiếu headless.**

---

## 9. Bài tập

**Bài 1 (20 phút — 3 recipes bắt buộc):** copy 3 scripts mục 2, gắn `settings.json`, chạy 3 ca lint + 4 ca push + cost-cap (`DAILY_CAP_USD=0.01`). Sửa regex tới khi 4 blocked + 2对照 pass.

**Bài 2 (20 phút — guard + test-gate):** thêm `guard-paths.sh` (write `migrations/001.sql`, `.env` phải blocked) + `test-gate.sh` (làm đỏ 1 test → Stop exit 2; sửa xanh → exit 0).

**Bài 3 (15 phút — audit hooks):** `/hooks` kiểm tra overlap `updatedInput`; `time` từng hook (>5s thì focus scope/cache); viết 1 `prompt` hook check secret cho `git commit`, test với `ghp_fake123`.

> Đạt: sau 1 tuần không còn lần nào phải nhắc "nhớ lint / đừng push main" bằng miệng — hooks lo hết.

---

## 10. Tham khảo chéo

- Lệnh hooks:
  - [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — xem/sửa hooks
  - [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — phát hiện hooks chậm
  - [../01-huong-dan-su-dung/commands/model-mode/goal/README.md](../01-huong-dan-su-dung/commands/model-mode/goal/README.md) — kết hợp Stop-gate
  - [../01-huong-dan-su-dung/commands/code-repo/loop/README.md](../01-huong-dan-su-dung/commands/code-repo/loop/README.md) — loops + gate
  - [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — mcp_tool hooks
- Bài tips liên quan:
  - [Tips 04](./04-verification-done-that.md) — Stop test-gate + loops guard
  - [Tips 05](./05-parallel-agents.md) — hooks bound từng subagent recipe
  - [Tips 08](./08-tiet-kiem-cost-token.md) — cost-cap ledger + route model
  - [Tips 09](./09-teamwork-chuan-hoa.md) — commit hooks + plugin phân phối team

> Mẹo 1 dòng: _lần thứ hai phải nhắc cùng 1 rule bằng miệng là lần đáng lẽ đã viết hook._
