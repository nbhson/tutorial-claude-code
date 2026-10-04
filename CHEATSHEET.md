# Cheatsheet Claude Code v2.1.x (1 trang)

## CLI
`claude` · `claude "task"` · `claude -p "task"` · `--continue` · `--resume <id>` · `--agent <ten>`
`--add-dir <dir>` · `--cloud` · `--dangerously-skip-permissions` (chỉ CI sandbox) · `claude doctor/update/login/logout`

## Session/context
`/clear` (mỗi task) · `/compact [focus]` · `/context` · `/cost` · `/usage` · `/export` · `/resume /fork /branch /rename`
`/rewind` (double-Esc menu) · `/todos` · `/tasks`

## Model/mode
`/model opus|sonnet|haiku` · `/effort low|medium|high|xhigh|max|auto` · `/fast` (+`/extra-usage`)
`Shift+Tab`: default→acceptEdits→plan→auto→bypass · `/plan` · `/goal <dk>` (`/goal clear`) · `/permissions`

## Code/repo
`/init` · `/memory` · `/rules` · `/diff` · `/review` · `/code-review [PR|branch]` · `/ultrareview`
`/verify` (≥2.1.145) · `/pr_comments` · `/batch` · `/loop` · `/cd` (≥2.1.169) · `/add-dir`

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
