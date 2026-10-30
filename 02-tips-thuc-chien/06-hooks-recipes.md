# Tips 06 — Hooks recipes: biến mọi rule hay quên thành luật

> **Bài này cho ai:** dev đang dặn Claude "nhớ chạy lint / đừng push main" tới lần thứ hai, hoặc tech lead chuẩn hóa hooks cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 04 — Verification](./04-verification-done-that.md) trước vì recipe test-gate ở mục 3 nối tiếp vòng verify của Tips 04.
> **Đọc xong bạn làm được:**
> - Copy-paste 3 recipes bắt buộc (lint-on-write, branch-protect, cost-cap) + 3 recipes nâng cao, lắp cho repo mới trong 30 phút.
> - Tránh 7 bẫy hooks (matcher sai, chạy headless, hook chậm...).
> **Thời gian:** ~45 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Hook | Luật tự chạy ngoài model: 0 tokens, không bị thuyết phục, không mệt | `hooks/lint-on-write.sh` tự chạy sau mỗi lần sửa file |
| PreToolUse / PostToolUse | Hook chạy trước khi tool được phép chạy / chạy xong tool | `PreToolUse Bash` chặn `git push -f` trước khi lệnh chạy |
| Stop / SessionStart / SessionEnd | Hook chạy lúc sắp kết thúc turn / mở session / đóng session | `Stop` → test-gate, `SessionStart` → nạp branch + `git status` |
| Matcher | Chuỗi chọn tool nào bị áp luật — phân biệt hoa thường | `matcher: "Edit\|Write"` chỉ áp cho lệnh sửa/ghi file |
| exit code | Đèn tín hiệu: `0` cho qua, `2` chặn và hiện lý do cho agent | `branch-protect.sh` trả `exit 2` khi push thẳng main |

---

## 1. Triết lý + cơ chế hooks

### 1.1. Triết lý 1 dòng

**Rule bị miss 2 lần → viết thành hook.** Nhắc lần 1 quên, nhắc lần 2 vẫn quên khi vội; lần 3 đừng nhắc nữa — viết hook tự chạy lint sau mỗi edit.

### 1.2. Cơ chế: hooks chạy ở đâu?

Hook can thiệp 4 mốc: **PreToolUse** (định chạy tool — cho hay chặn?), **PostToolUse** (tool xong — lint/format/log?), **Stop** (turn định kết thúc — test xanh chưa?), **SessionStart/SessionEnd** (mở/đóng session — nạp branch, tóm tắt).

- Hooks chạy **ngoài model** (shell script, LLM 1-turn, agent, HTTP, MCP) → 0 tokens cho rule lặp lại.
- Hook có thể: **cho qua**, **chặn + báo lý do**, **sửa input** (`updatedInput`), **ghi log**. Hook lỗi hoặc timeout mặc định **không chặn**; muốn lỗi cũng chặn thì đặt `"onFailure": "block"`.
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

Cả 3 cùng khuôn `settings.json` — đổi `matcher`, event và `command` cho từng recipe:

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/lint-on-write.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/branch-protect.sh" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/cost-cap.sh" }] }
    ]
  }
}
```

### 2a. Lint-on-write — `PostToolUse` match `Edit|Write`

**Mục tiêu:** sau mỗi edit, chạy prettier/eslint đúng file vừa đổi. Lỗi → trả cho agent fix ngay turn sau, không dồn thành cleanup 40 files cuối tuần.

**`hooks/lint-on-write.sh`:**

```bash
#!/usr/bin/env bash
# Lint file vừa edit. Đọc tool input từ stdin JSON, lấy file path.
set -euo pipefail
FILE=$(cat | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")

# Bỏ qua file không cần lint / ngoài project
case "$FILE" in
  ""|*.md|*.json|*generated*|*.min.js|*node_modules*|*.git/*) exit 0 ;;
esac

if [[ "$FILE" == *.ts || "$FILE" == *.tsx || "$FILE" == *.js ]]; then
  npx prettier --check "$FILE" 2>&1 || npx prettier --write "$FILE" 2>&1
  npx eslint "$FILE" 2>&1 || exit 2
fi

exit 0
# exit 0 = cho qua, exit 2 = báo lỗi cho agent (block + hiện output)
```

**Kiểm tra nhanh:** `echo '{"tool_input":{"file_path":"src/a.ts"}}' | ./hooks/lint-on-write.sh` — sửa `src/a.ts` sai lint phải bị báo; file `.md` và `generated/foo.ts` phải được bỏ qua.

### 2b. Branch-protect — `PreToolUse` match `Bash`

**Mục tiêu:** block push lên `main`, mọi force-push, xóa branch, `push origin HEAD:main`. **Match theo intent, không substring.**

**`hooks/branch-protect.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail
CMD=$(cat | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))")

# Không phải git → cho qua
echo "$CMD" | grep -qE '(^|[;&| ])git ' || exit 0

echo "$CMD" | tr ';' '\n' | sed 's/&&/\n/g; s/||/\n/g' | while IFS= read -r line; do
  if echo "$line" | grep -qE 'git\s+push\b.*(--force-with-lease|--force\b|-f\b)'; then
    echo "BLOCKED: force-push bị cấm. Dùng PR + merge thay vì push -f." >&2; exit 2
  fi
  if echo "$line" | grep -qE 'git\s+push\b.*(\bmain\b|\bmaster\b|HEAD:main|HEAD:master)'; then
    echo "BLOCKED: push thẳng main/master bị cấm. Push feature branch + mở PR." >&2; exit 2
  fi
  if echo "$line" | grep -qE 'git\s+(branch\s+-D|branch\s+--delete|push\b.*--delete)'; then
    echo "BLOCKED: xóa branch cần human duyệt." >&2; exit 2
  fi
done
```

**Kiểm tra nhanh:** 4 ca blocked + 2 ca đối chứng (copy-paste):

```bash
run() { echo "{\"tool_input\":{\"command\":\"$1\"}}" | ./hooks/branch-protect.sh; echo "[$1] exit=$?"; }
run "git push -f origin feat/x"; run "git push --force origin feat/x"; run "git push --force-with-lease origin feat/x"; run "git push origin HEAD:main"
# Cả 4 phải exit=2. Đối chứng (phải exit=0 — chứng minh không substring "main" bừa):
run "git push origin feat/my-main-fix"; run "git status"
```

### 2c. Cost-cap — `Stop`

**Mục tiêu:** đọc token usage từ hook input → quy $ theo pricing hiện tại → append daily ledger → quá cap cảnh báo. Bảo hiểm rẻ nhất, add sớm bất kể project lớn nhỏ.

**`hooks/cost-cap.sh` (điền giá per-token theo bảng pricing hiện tại của provider, đừng hardcode số cũ):**

```bash
#!/usr/bin/env bash
set -euo pipefail
DAILY_CAP_USD="${DAILY_CAP_USD:-20}"
LEDGER_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/ledger"
PRICE_INPUT_PER_1K="${PRICE_INPUT_PER_1K:?điền giá input/1K hiện tại}"
PRICE_OUTPUT_PER_1K="${PRICE_OUTPUT_PER_1K:?điền giá output/1K hiện tại}"

mkdir -p "$LEDGER_DIR"; LEDGER="$LEDGER_DIR/cost-$(date +%F).jsonl"
INPUT=$(cat)
# Stop hook nhận usage tùy version — parse defensive
TOKENS_IN=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('input_tokens',0))" 2>/dev/null || echo 0)
TOKENS_OUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)

COST=$(python3 -c "print($TOKENS_IN/1000*$PRICE_INPUT_PER_1K + $TOKENS_OUT/1000*$PRICE_OUTPUT_PER_1K)")
echo "{\"ts\":\"$(date -Is)\",\"in\":$TOKENS_IN,\"out\":$TOKENS_OUT,\"cost_usd\":$COST}" >> "$LEDGER"
TOTAL=$(python3 -c "import json; print(sum(json.loads(l).get('cost_usd',0) for l in open('$LEDGER')))")
if python3 -c "import sys; sys.exit(0 if $TOTAL > float('$DAILY_CAP_USD') else 1)"; then
  echo "Cost-cap: hôm nay đã $TOTAL USD (cap $DAILY_CAP_USD). Session tiếp nên /clear + model rẻ cho explore." >&2
  # Không block (exit 0) — chỉ cảnh báo. Muốn chặn cứng thì exit 2, ping Slack bằng curl nếu cần.
fi
exit 0
```

**Kiểm tra nhanh:** `DAILY_CAP_USD=0.01 ./hooks/cost-cap.sh < /dev/null` → ledger append + cảnh báo khi quá cap.

---

## 3. Ba recipes nâng cao

### 3.1. Guard sensitive paths — `PreToolUse` match `Write|Edit`

```bash
#!/usr/bin/env bash
# hooks/guard-paths.sh — block writes vào vùng cấm
set -euo pipefail
FILE=$(cat | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")case "$FILE" in
  *migrations/*|*.pem|*.key|.env*|*generated*|*dist/*)
    echo "BLOCKED: $FILE là vùng cấm. Muốn sửa cần human duyệt + ghi lý do vào PR." >&2
    exit 2 ;;
esac
exit 0
```

### 3.2. Test-gate — `Stop`

```bash
#!/usr/bin/env bash
# hooks/test-gate.sh — test đỏ không cho kết thúc turn (tối đa 8 blocks là giới hạn)
set -euo pipefail
SCOPE="${TEST_SCOPE:-payments}"
pnpm --filter "$SCOPE" test 2>&1 | tail -n 25
[[ "${PIPESTATUS[0]:-0}" != "0" ]] && { echo "BLOCKED: test $SCOPE còn đỏ. Fix rồi mới kết thúc turn." >&2; exit 2; }
exit 0
```

> Dùng kèm `/goal` + reviewer cuối (xem [Tips 04](./04-verification-done-that.md)). Gate đảm bảo "xanh", reviewer đảm bảo "đúng".

### 3.3. SessionStart inject

Tự nạp branch hiện tại, ticket, `git status` tóm tắt vào context lúc mở session: script in ra stdout vài dòng `git branch --show-current`, `git status --short | head -20`, `git log --oneline -5`, ticket parse từ tên branch, và rule "1 task 1 session, đổi task thì /clear". Biến thể dynamic line trong skill (data tươi mà không cần hook): `` `!`git branch --show-current`` ``.

---

## 4. Năm loại hook: command/prompt/agent/http/mcp

| Loại | Chạy bằng gì | Khi dùng |
|---|---|---|
| `command` (shell, default) | Script bash/python | Mọi thứ deterministic — production ưu tiên (2a–3.2 ở trên) |
| `prompt` (LLM 1-turn, Haiku default) | Model 1 turn đọc input | Judgment từ input: commit msg có leak secret? |
| `agent` (experimental, ~60s/50 turns) | Subagent thật | Verify cần đọc code/chạy lệnh thật: pre-push smoke |
| `http` | POST ra ngoài | Ping Slack khi cost quá cap, ghi audit log |
| `mcp_tool` | Gọi MCP tool trong hook | SessionStart lấy ticket Jira/Linear gắn branch |

> Rule: **production ưu tiên `command`.** `prompt`/`agent` để judgment, `http`/`mcp_tool` để tích hợp ngoài. Hook lỗi/timeout mặc định thả qua; thêm `"onFailure": "block"` để lỗi cũng chặn.

---

## 5. Lắp hooks cho repo mới trong 30 phút

1. **0–5p:** `mkdir -p hooks .claude/ledger && chmod +x hooks/*.sh`, copy 4 scripts (2a, 2b, 2c, 3.1).
2. **5–15p:** ghép khuôn `settings.json` mục 2 → test 4 ca push + 3 ca lint → `/hooks` kiểm tra matcher/event.
3. **15–25p:** thêm `test-gate.sh` (sửa `TEST_SCOPE`) — làm đỏ 1 test, xác nhận Stop block.
4. **25–30p:** thêm `session-start.sh`, mở session mới xem branch/status → commit `settings.json` + `hooks/`, ghi 1 dòng vào `CLAUDE.md`.

---

## 6. Bảy bẫy thường gặp

1. **Matcher case-sensitive, sai event.** `edit|write` không match `Edit|Write`; Pre vs Post ngược → chạy sai lúc. Fix: `/hooks` + test từng event.
2. **2 hooks cùng rewrite `updatedInput`.** Kết quả non-deterministic. Fix: mỗi hook 1 field riêng, hoặc gộp 1 script.
3. **Headless (`-p`) + background subagents không trả lời prompt được.** Hook chờ input là treo. Fix: không `read`, không mở editor, timeout rõ.
4. **Hooks là production code nhưng review như đồ chơi.** Hook chạy với quyền của bạn. Fix: review/test/version như code, không curl pipe bash lạ vào `hooks/`.
5. **Substring match (`main`).** `feat/my-main-fix` bị chặn oan, `HEAD:main` lọt. Fix: match intent bằng regex (2b) + test cả ca đối chứng.
6. **Bẫy version.** Schema stdin/hooks từng đổi qua các bản — hook viết năm ngoái có thể lặng lẽ không chạy năm nay. Fix: đối chiếu release notes trước khi tin hook chặn CI/push; pin version Claude trong team ([Tips 09](./09-teamwork-chuan-hoa.md)).
7. **Hook chậm làm mọi turn chậm.** Full suite 5 phút mỗi turn-end = tự DDoS mình. Fix: `TEST_SCOPE` + cache + timeout, chỉ gate ở Stop.

---

## 7. Bài tập

- **Bài 1 (20 phút):** copy 3 scripts mục 2 + khuôn `settings.json`, chạy 3 ca lint + 4 ca push + cost-cap (`DAILY_CAP_USD=0.01`). Sửa regex tới khi 4 blocked + 2 ca đối chứng pass.
- **Bài 2 (20 phút):** thêm `guard-paths.sh` (write `migrations/001.sql`, `.env` phải blocked) + `test-gate.sh` (làm đỏ 1 test → Stop exit 2; sửa xanh → exit 0).
- **Bài 3 (15 phút):** `/hooks` kiểm tra overlap `updatedInput`; `time` từng hook (>5s thì focus scope/cache); viết 1 `prompt` hook check secret cho `git commit`, test với `ghp_fake123`.

---

## 8. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — xem/sửa hooks · [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — phát hiện hooks chậm
- [Tips 04](./04-verification-done-that.md) — Stop test-gate · [Tips 05](./05-parallel-agents.md) — hooks bound subagent · [Tips 08](./08-tiet-kiem-cost-token.md) — cost-cap + route model · [Tips 09](./09-teamwork-chuan-hoa.md) — commit hooks cho team

> Mẹo 1 dòng: _lần thứ hai phải nhắc cùng 1 rule bằng miệng là lần đáng lẽ đã viết hook._
