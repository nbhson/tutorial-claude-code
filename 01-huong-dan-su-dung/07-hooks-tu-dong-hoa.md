# 07 — Hooks: Tự Động Hóa Deterministic (Luật, Không Phải Gợi Ý)

## 1. Hook là gì

Shell command (hoặc http/mcp_tool/prompt/agent) Claude Code **tự chạy khi tới lifecycle event** —
không qua LLM quyết định → **deterministic, 0 model tokens, Claude không override được**.
Dùng để: format sau edit, block lệnh nguy hiểm, gửi notification, inject context đầu session, enforce rules.

> Triết lý: CLAUDE.md/skills = advisory (Claude có thể quên). Hooks = law.
> Rule nào bị miss 2 lần → nâng thành hook.

## 2. Bảng events (thuộc lòng nhóm chính)

| Event | Khi lửa |
|---|---|
| `SessionStart` | Session bắt đầu/resume |
| `Setup` | `claude --init-only`, hoặc `--init`/`--maintenance` trong `-p` (chuẩn bị CI/scripts) |
| `UserPromptSubmit` | User submit prompt, trước khi Claude xử lý |
| `UserPromptExpansion` | Command user gõ expand thành prompt (có thể block) |
| `PreToolUse` | Trước tool call (**block được**) — chạy trước mọi permission check, kể cả `dontAsk`/`bypass` |
| `PermissionRequest` | Tool call cần quyết định permission (trong `-p` plain: dùng `PreToolUse` thay vì event này) |
| `PermissionDenied` | Auto mode deny (có thể `retry: true` để model thử lại) |
| `PostToolUse` / `PostToolUseFailure` | Sau tool call thành công/thất bại |
| `PostToolBatch` | Sau cả batch parallel tool calls, trước model call kế |
| `Notification` | Khi Claude gửi notification |
| `MessageDisplay` | Khi assistant text hiển thị |
| `SubagentStart`/`SubagentStop` | Subagent spawn/finish (matcher = tên agent type) |
| `TaskCreated`/`TaskCompleted` | Task lifecycle (`TaskCreate`) |
| `Stop` / `StopFailure` | Claude xong response / turn kết thúc do API error (Stop **không** lửa khi user interrupt) |
| `TeammateIdle` | Agent-team teammate sắp idle |
| `InstructionsLoaded` | 1 file CLAUDE.md/rules vừa load (đầu session + lazy-load) |
| `PreCompact`/`PostCompact`, `ConfigChange`, `PreToolUse`... | Compaction/config (matcher: `manual/auto`, source settings...) |

Types: `command` (shell, phổ biến), `http` (POST event JSON tới URL), `mcp_tool` (gọi tool của MCP server đã connect),
`prompt` (LLM 1-turn, default Haiku, quyết định cần judgment), `agent` (experimental: subagent verify multi-turn, ~60s/50 turns).

## 3. Cấu hình (settings.json)

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write", "type": "command",
        "command": "npx prettier --write \"$CLAUDE_FILE_PATHS\"" }
    ],
    "PreToolUse": [
      { "matcher": "Bash", "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-main-push.sh" },
      { "matcher": "Write", "type": "command",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/guard-migrations.sh" }
    ],
    "Stop": [
      { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/cost-ledger.sh" }
    ],
    "Notification": [
      { "type": "command", "command": "osascript -e 'display notification \"Claude cần bạn\"'" }
    ]
  }
}
```

- Hook nhận JSON qua **stdin**, trả về pass/block (exit code / JSON `permissionDecision: allow|deny`, `updatedInput`...).
- Matcher **case-sensitive**, match tên tool (`Edit`, `Write`, `Bash`...). Nhiều hooks cùng event chạy **song song**;
  2 hook cùng rewrite `updatedInput` → thằng finish cuối thắng (non-deterministic — tránh overlap).
- Xem: `/hooks`. Debug: check event đúng chưa (Pre vs Post), matcher đúng case chưa, folder đã trust chưa
  (frontmatter hooks project-level cần trust dialog; `-p` session không tính là trusted).
- Bảo mật: hook deny thắng cả `bypassPermissions`/`--dangerously-skip-permissions`; ngược lại hook allow
  KHÔNG nới được deny rules hay `ask` của org — hooks chỉ siết, không nới.

## 4. Ba recipes phải có (copy từ `templates/`)

**a) Lint-on-write (PostToolUse Edit|Write)** — format/lint file vừa sửa, lỗi trả lại cho agent fix ngay:

```bash
#!/bin/bash
# .claude/hooks/lint-on-write.sh — đọc JSON stdin, lấy file paths, chạy prettier/eslint
```

**b) Branch-protect (PreToolUse Bash)** — block `push main`, force-push, xóa branch. Match theo **intent**,
không substring `main` (lọt `git log main..HEAD`, miss `-f`). Test với:
`git push -f`, `git push --force`, `git push --force-with-lease`, `git push origin HEAD:main`.

**c) Cost-cap (Stop)** — đọc token usage từ logs, quy ra $, append daily ledger, quá cap → ping Slack.

Thêm: prompt-hook kiểm tra câu chữ cần judgment (vd "commit message có leak secret?"),
agent-hook verify cần đọc code (experimental, production ưu tiên command hooks),
`SessionStart` inject context (branch hiện tại, ticket liên quan), `Stop` gate (script check, block turn-end
tới khi pass — tối đa 8 blocks liên tiếp rồi Claude override để thoát).

## 5. Nhờ Claude viết hook

```
"Viết hook chạy eslint sau mỗi lần edit file .ts" / "Viết hook block writes vào thư mục migrations"
```

Claude sửa `.claude/settings.json` trực tiếp; bạn `/hooks` duyệt lại. Đối xử hooks như production code
(chạy với quyền của bạn, đọc FS + network + ghi disk).
