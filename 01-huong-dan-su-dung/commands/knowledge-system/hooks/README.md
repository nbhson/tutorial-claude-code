# /hooks — Tự động hoá: việc máy làm được thì đừng bắt AI làm

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có (hooks chạy shell code trên máy bạn mỗi khi trigger — hook độc/sai là mất file, lộ secret, hoặc vòng lặp tốn tiền)

`/hooks` mở trung tâm quản lý hooks: những script tự chạy khi sự kiện xảy ra — trước/sau tool-call, khi session bắt đầu/kết thúc, khi model dừng... Dùng hooks để ép luật máy kiểm được (format, chặn `rm -rf`, log) thay vì năn nỉ model bằng lời. Hiểu `/hooks` là hiểu "phản xạ tự động" của Claude Code.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/hooks` | _(không có)_ | Mở UI: liệt kê hooks theo event + enable/disable |
| File config | `.claude/settings.json` → `hooks` | Khai báo hooks bằng JSON (commit cho team) |
| File local | `.claude/settings.local.json` | Hooks riêng máy (không commit) |
| Script file | `.claude/hooks/*.sh` | Code hook (bash/python/node) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI quản lý
/hooks
# → thấy theo event: PreToolUse, PostToolUse, SessionStart, Stop...
```

```bash
# Dạng 2: hook auto-format sau mỗi Edit (file .claude/settings.json)
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": ".claude/hooks/format.sh" }]
      }
    ]
  }
}
```

```bash
# Dạng 3: nội dung format.sh (copy-paste)
```

```bash
#!/bin/bash
# .claude/hooks/format.sh — format file vừa sửa, đọc JSON từ stdin
INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input'].get('file_path',''))")
case "$FILE" in
  *.py) uvx ruff format "$FILE" 2>/dev/null ;;
  *.ts|*.tsx) npx prettier --write "$FILE" 2>/dev/null ;;
esac
exit 0
```

```bash
# Dạng 4: hook chặn lệnh nguy hiểm (PreToolUse, exit 2 = chặn)
```

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": ".claude/hooks/guard.sh" }]
      }
    ]
  }
}
```

```bash
# Dạng 5: guard.sh — chặn rm -rf và git push main
#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input'].get('command',''))")
case "$CMD" in
  *rm\ -rf*|*push*main*) echo "BLOCKED: lệnh nguy hiểm ($CMD)" >&2; exit 2 ;;
esac
exit 0
```

---

## Cách nó hoạt động

### Cơ chế sâu: events / matchers / exit codes

1. **Events (sự kiện nào kích hook):**
   - `PreToolUse`: trước khi tool chạy — DÙNG ĐỂ CHẶN. Nhận JSON `{tool_name, tool_input}`, trả exit 2 = chặn (kèm lý do stderr), exit 0 = cho qua (có thể sửa input).
   - `PostToolUse`: sau khi tool chạy xong — DÙNG ĐỂ FORMAT/LOG. Nhận thêm `tool_response`. Không chặn được (việc đã xong), chỉ xử lý hậu kỳ.
   - `SessionStart`: khi session mở — DÙNG ĐỂ SETUP. VD kiểm tra `git status`, nhắc "đang ở nhánh X", reconnect MCP.
   - `SessionEnd`: khi session đóng — DÙNG ĐỂ DỌN. VD tóm tắt việc làm, push log.
   - `Stop`: khi model dừng trả lời — DÙNG ĐỂ VALIDATE. VD chạy lint, fail thì bắt model sửa tiếp (feedback loop).
   - `SubagentStop`: khi subagent xong — VD kiểm tra output con có đúng format không.
   - `Notification`: khi cần input bạn — VD kêu "ting" khi xong việc dài.
   - `PreCompact`: trước khi compact — VD lưu state quan trọng vào file kẻo mất.
2. **Matchers (hook nào nghe tool nào):**
   - `"matcher": "Edit|Write"` = chỉ nghe 2 tools đó (regex).
   - `"matcher": "Bash"` = mọi lệnh shell (rồi lọc tiếp trong script).
   - `"matcher": ""` hoặc không có = nghe TẤT CẢ (đắt, chậm — tránh).
   - Matcher càng hẹp càng nhanh (hook không khớp thì không spawn process).
3. **Dữ liệu vào/ra (stdin/stdout/exit):**
   - Hook nhận JSON qua `stdin`: `{tool_name, tool_input, tool_response?, session_id, ...}`.
   - Hook nói lại bằng `stdout` (JSON bổ sung context cho model) + `exit code`:
     - `exit 0` = OK (cho qua; stdout nếu có sẽ đưa vào context).
     - `exit 2` = BLOCK (chỉ PreToolUse): chặn tool, stderr hiện cho model + bạn đọc.
     - exit khác (1, 3...) = lỗi hook (log, không chặn — trừ khi config `failClosed`).
   - Timeout mặc định ~60s — hook chạy lâu (npm install) sẽ bị kill. Việc nặng thì cho chạy nền, ghi file, không chặn.
4. **Thứ tự khi nhiều hooks cùng event:**
   - Chạy tuần tự theo thứ tự khai báo trong settings. Hook 1 exit 2 → dừng luôn, hook 2 không chạy.
   - Project hooks chạy trước user hooks (team luật trước, cá nhân sau).
   - Plugin hooks xen vào theo thứ tự cài — xung đột thì disable từng cái trong `/hooks` UI để tìm thủ phạm.
5. **Scopes (khai báo ở đâu):**
   - Project (`.claude/settings.json`, commit): luật team (format, guard, lint).
   - Local (`settings.local.json`, gitignore): riêng máy (notify âm thanh, reconnect MCP của bạn).
   - Plugin (`hooks.json` trong plugin): kèm theo plugin — xem được và disable trong `/hooks` UI.
6. **Stop-hook feedback loop (pattern mạnh nhất):**
   - `Stop` hook chạy lint/test → fail → trả exit 2 + lỗi → model TỰ SỬA TIẾP thay vì báo "xong" ẩu.
   - Giới hạn vòng (max 3) kẻo vòng lặp vô hạn tốn tiền. Đếm bằng file `/tmp/lint-loop-count`.

### Sơ đồ PreToolUse chặn lệnh

```text
Model xin chạy: Bash("rm -rf /tmp/cache")
  ↓ PreToolUse hooks (matcher Bash)
  ├─ guard.sh đọc stdin → thấy "rm -rf" → echo BLOCKED >&2 → exit 2
  ↓ TOOL BỊ CHẶN (không chạy)
Model nhận: "Hook blocked: lệnh nguy hiểm" → tìm cách an toàn hơn (rm file cụ thể)
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Chạy khi nào? | Cần AI không? | Dùng khi nào? |
|---|---|---|---|
| Hook | Event trigger (tự động) | Không (script máy) | Việc máy kiểm được 100% (format, chặn pattern) |
| Skill | Model thấy khớp việc | Có | Quy trình cần phán đoán |
| `/permissions` ask | Tool nhạy cảm | Bạn bấm Yes/No | Quyết định cần người |
| Subagent | Được spawning | Có (context riêng) | Việc nặng cần AI đọc hiểu |

> Quy tắc ngón tay cái:
>
> - **Máy kiểm được chắc chắn → hook. Cần phán đoán → skill/agent. Cần người quyết → permissions ask.**

---

## Ví dụ thực tế

### Kịch bản 1: Auto-format + lint sau mỗi lần sửa (khỏi nhắc)

```json
// .claude/settings.json (commit cho team)
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{ "type": "command", "command": ".claude/hooks/format.sh" }]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": ".claude/hooks/lint-stop.sh" }]
      }
    ]
  }
}
```

```bash
#!/bin/bash
# lint-stop.sh — model báo xong thì kiểm, fail bắt làm tiếp (tối đa 3 vòng)
COUNT_FILE=/tmp/lint-loop-count
COUNT=$(cat $COUNT_FILE 2>/dev/null || echo 0)
if [ "$COUNT" -ge 3 ]; then echo 0 > $COUNT_FILE; exit 0; fi
if ! uvx ruff check . 2>/dev/null; then
  echo $((COUNT+1)) > $COUNT_FILE
  echo "LINT FAIL — sửa các lỗi trên rồi mới được dừng" >&2
  exit 2
fi
echo 0 > $COUNT_FILE
exit 0
```

> Kết quả: code xong là đã format + lint sạch. Model không "xong ẩu" được.

### Kịch bản 2: Guard chặn đường chết (rm -rf, push main, .env)

Dùng `guard.sh` ở mục Cú pháp dạng 4-5, cộng thêm chặn đọc secret:

```bash
#!/bin/bash
# Guard mở rộng: chặn cả Read .env
INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))")
ARG=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(str(d.get('tool_input',{})))")
case "$ARG" in
  *rm\ -rf*|*push*main*|*.env*|*id_rsa*) echo "BLOCKED: nguy hiểm/secret ($ARG)" >&2; exit 2 ;;
esac
exit 0
```

> Kết quả: kể cả model "lỡ tay" cũng không chạy được lệnh chết. Phanh máy cứng hơn phanh lời.

### Kịch bản 3: SessionStart nhắc ngữ cảnh (khỏi ngơ ngác)

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": ".claude/hooks/start.sh" }]
      }
    ]
  }
}
```

```bash
#!/bin/bash
# start.sh — nhắc model đang ở đâu
BRANCH=$(git branch --show-current 2>/dev/null)
DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
echo "{\"additionalContext\": \"Đang ở nhánh $BRANCH, $DIRTY file chưa commit. Nhớ tuân .claude/rules/.\"}"
exit 0
```

> Kết quả: mở session là model biết đang ở nhánh nào, có file dở dang không — khỏi hỏi "anh đang làm gì dở?".

### Kịch bản 4: Debug hook không chạy (matcher sai)

Triệu chứng: `format.sh` không bao giờ chạy dù đã khai báo.

```bash
# Bước 1: mở UI kiểm tra
/hooks
# → thấy hook nhưng matcher ghi "Edit,Write" (sai — phải regex "Edit|Write", không phải phẩy!)

# Bước 2: sửa settings.json: "Edit,Write" → "Edit|Write"

# Bước 3: test tay (giả stdin):
echo '{"tool_name":"Edit","tool_input":{"file_path":"a.py"}}' | .claude/hooks/format.sh
# → chạy OK là hook sống, chỉ sai matcher
```

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Hook từ plugin lạ (chưa đọc code) | Chạy `curl key lên server lạ` mỗi lần Edit | Đọc script hook trước khi enable; `/hooks` disable hook của plugin không tin |
| Guard regex ẩu (`*rm*`) | Chặn cả lệnh lành (`npm i form-data`) | Test regex với lệnh lành trước; chặn pattern hẹp (`rm -rf`, không phải `rm`) |
| Stop-hook không giới hạn vòng | Lint fail mãi → vòng lặp vô hạn, tốn tiền | Đếm vòng bằng file, max 3 rồi cho qua + báo bạn |
| Hook chạy lâu (npm install trong PreToolUse) | Treo mọi tool-call 60s+ rồi timeout | Hook chỉ làm việc <5s; việc nặng cho chạy nền (background) |
| Hook echo rác vào stdout | Rác vào context mỗi lần trigger, tốn token | stdout chỉ khi cần; còn lại im lặng + exit 0 |
| Commit hook chứa secret/token | Lộ credential trong git | Hook đọc từ env (`$TOKEN`), không hardcode |

### Tốn token?

- Hook tự thân tốn 0 token nếu im lặng (exit 0, không stdout).
- Hook nói nhiều (echo 500 dòng mỗi Edit) → 500 token × 50 Edit = 25k vứt đi. Chỉ bổ sung context khi thật cần.

### Version / provider

- Hooks + `/hooks` UI: bản v1.0.40+ (Pre/PostToolUse), SessionStart/Stop: v1.0.70+, PreCompact: v2.x.
- `failClosed` (lỗi hook = chặn tool): v2.x. Bản cũ lỗi hook là cho qua.
- Bedrock/Vertex: hooks chạy local bình thường (không qua cloud).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/hooks` + `/rules` | Hook enforce rules máy kiểm được | Rules viết "dùng ruff", hook chạy ruff thật |
| `/hooks` + `/permissions` | Guard chặn trước cả gate hỏi | Hook chặn `rm -rf` luôn, khỏi hiện picker |
| `/hooks` + `/plugin` | Khóa hooks plugin lạ | `/hooks` disable hooks của plugin không tin |
| `/hooks` + `/mcp` | SessionStart reconnect MCP hay rớt | Hook start chạy reconnect db |
| `/hooks` + `/verify` | Stop-hook chạy verify mini | Fail thì model sửa tiếp, không cần gọi `/verify` tay |

Workflow chuẩn "dựng phanh team mới":

```bash
# 1. Viết guard.sh (chặn rm -rf, push main, đọc .env)
# 2. Viết format.sh (PostToolUse Edit|Write)
# 3. Viết lint-stop.sh (Stop, max 3 vòng)
# 4. Khai báo vào .claude/settings.json, chmod +x scripts/*.sh
# 5. Commit, team pull về là có phanh + auto-format
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Hook không chạy bao giờ | Matcher sai (`Edit,Write` thay vì `Edit\|Write`) | Sửa thành regex `Edit\|Write`; test bằng echo JSON pipe tay |
| Hook báo permission denied | Quên `chmod +x` | `chmod +x .claude/hooks/*.sh` |
| PreToolUse chặn cả lệnh lành | Regex quá rộng (`*rm*`) | Thu hẹp (`rm -rf`, `rm -rf /`); test với lệnh lành |
| Vòng lặp Stop-hook vô hạn | Lint fail mãi, không max vòng | Thêm đếm file `/tmp/...`, max 3 rồi exit 0 + báo tay |
| Hook chạy 60s rồi timeout | Việc nặng trong hook đồng bộ | Chuyển việc nặng ra nền; hook chỉ check nhanh <5s |
| `/hooks` không thấy hook plugin | Plugin disabled | Enable plugin trong `/plugin` Manage trước |
| Hook echo tiếng Việt lỗi font | Thiếu UTF-8 trong script | Thêm `export LC_ALL=C.UTF-8` đầu script |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../permissions/README.md](../../model-mode/permissions/README.md) — gate hỏi/deny, hook chặn trước cả gate
  - [../plugin/README.md](../../knowledge-system/plugin/README.md) — hooks kèm theo plugin
  - [../rules/README.md](../../knowledge-system/rules/README.md) — rules viết luật, hooks thi hành phần máy kiểm được
  - [../verify/README.md](../../code-repo/verify/README.md) — Stop-hook gọi verify mini
  - [../mcp/README.md](../../knowledge-system/mcp/README.md) — reconnect MCP bằng SessionStart hook
  - [../doctor/README.md](../../knowledge-system/doctor/README.md) — doctor có audit hooks không
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../../03-claude-md-memory-rules.md) — hooks có đọc memory không
  - [../../05-skills-custom-commands.md](../../../05-skills-custom-commands.md) — hook vs skill
  - [../../06-subagents-agent-teams-parallel.md](../../../06-subagents-agent-teams-parallel.md) — SubagentStop hook
  - [../../07-hooks-tu-dong-hoa.md](../../../07-hooks-tu-dong-hoa.md) — bài gốc: catalog hooks đầy đủ
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../../08-mcp-ket-noi-cong-cu-ngoai.md) — MCP + hooks
  - [../../09-plugins-marketplaces.md](../../../09-plugins-marketplaces.md) — hooks trong plugin

> Mẹo 1 dòng: _matcher hẹp, script nhanh <5s, Stop-hook nhớ max 3 vòng — và đọc code hook lạ trước khi enable._
