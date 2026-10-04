# Cheatsheet Claude Code v2.1.x (1 trang)

## CLI
`claude` · `claude "task"` · `claude -p "task"` · `--continue` · `--resume <id>` · `--agent <ten>`
`--add-dir <dir>` · `--cloud` · `--dangerously-skip-permissions` (chỉ CI sandbox) · `claude doctor/update/login/logout`

## Session/context
`/clear` (mỗi task) · `/compact [focus]` · `/context` · `/cost` · `/usage` · `/export` · `/resume /fork /branch /rename`
`/rewind` (double-Esc menu) · `/todos` · `/tasks` · `/background` (đẩy session thành agent nền) · `/recap` (tóm tắt khi quay lại) · `/restart`

## Model/mode
`/model opus-5.5|sonnet-5.5|fable|haiku` (Opus $4/$20, Sonnet $2/$10, Fable $10/$50, Haiku $1/$5 per 1M in/out; `opusplan` = plan Opus + chạy Sonnet; Fable không bao giờ default) · `/effort low|medium|high|xhigh|max|auto` · `/fast` (+`/extra-usage`)
`Shift+Tab`: default→acceptEdits→plan→auto→bypass · `/plan` · `/goal <dk>` (`/goal clear`) · `/permissions`

## Code/repo
`/init` · `/memory` · `/rules` · `/diff` · `/review` · `/code-review [PR|branch]` (`--max-findings all|default`, `ultra` = `/ultrareview`) · `/security-review` · `/ultrareview`
`/verify` (≥2.1.145) · `/run` (mở app thật + lái) · `/pr_comments` · `/batch` · `/subtask` · `/loop` · `/cd` (≥2.1.169) · `/add-dir`

## System
`/agents` · `/mcp [reconnect|enable|disable]` · `claude mcp list|get|remove|add|add-json|add-from-claude-desktop|serve`
`/plugin` · `/hooks` · `/config /settings /status /ide /theme /keybindings /vim /statusline /terminal-setup /sandbox`
`/doctor|/checkup` · `/debug` · `/bug` · `/login /logout /teleport /mobile /remote-env`
`/btw` (hỏi nhanh, không history) · `/stats /insights` · `Ctrl+X Ctrl+K ×2` (kill bg agents)

## Hooks events
`SessionStart Setup UserPromptSubmit UserPromptExpansion PreToolUse PermissionRequest PermissionDenied
PostToolUse PostToolUseFailure PostToolBatch Notification MessageDisplay SubagentStart SubagentStop
TaskCreated TaskCompleted Stop StopFailure TeammateIdle InstructionsLoaded PreCompact PostCompact ConfigChange`
Types: `command http mcp_tool prompt agent`. Matcher case-sensitive. Xem `/hooks`.

## MCP day-one
GitHub · Playwright · Postgres/MySQL · Fetch/Brave Search · Linear/Notion (3–6 servers; secrets qua env).

## Vòng chuẩn
Explore→Plan (duyệt)→Implement (phase-gate)→Verify (`/verify`+reviewer fresh). Rule miss 2 lần→hook.

## Tra cứu chi tiết từng lệnh
Index đầy đủ 78 lệnh: [01-huong-dan-su-dung/commands/README.md](01-huong-dan-su-dung/commands/README.md)
- `/plan` → [commands/model-mode/plan/README.md](01-huong-dan-su-dung/commands/model-mode/plan/README.md)
- `/permissions` → [commands/model-mode/permissions/README.md](01-huong-dan-su-dung/commands/model-mode/permissions/README.md)
- `/compact` → [commands/session-context/compact/README.md](01-huong-dan-su-dung/commands/session-context/compact/README.md)
- `/cost` → [commands/session-context/cost/README.md](01-huong-dan-su-dung/commands/session-context/cost/README.md)
- `/init` → [commands/code-repo/init/README.md](01-huong-dan-su-dung/commands/code-repo/init/README.md)
- `/batch` → [commands/code-repo/batch/README.md](01-huong-dan-su-dung/commands/code-repo/batch/README.md)
- `/verify` → [commands/code-repo/verify/README.md](01-huong-dan-su-dung/commands/code-repo/verify/README.md)
- `/doctor` → [commands/knowledge-system/doctor/README.md](01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md)
- `/mcp` → [commands/knowledge-system/mcp/README.md](01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md)
- `/hooks` → [commands/knowledge-system/hooks/README.md](01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md)
