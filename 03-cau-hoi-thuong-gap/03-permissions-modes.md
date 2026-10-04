# FAQ 03 — Permissions & Modes

**allow/ask/deny ở đâu?** `/permissions` (alias `/allowed-tools`). Files: `.claude/settings.json` (team, commit),
`.claude/settings.local.json` (personal), managed policy (org). Xem merged ở `/permissions`, đừng đoán.

**Shift+Tab là gì?** Xoay `default → acceptEdits → plan → auto → bypassPermissions`. Plan = read-only duyệt trước;
bypass = bỏ hỏi (chỉ CI sandbox, không máy dev).

**Cloud có Bypass không?** Không. Cloud chỉ Accept edits / Plan (/Auto tùy bản).

**Hook vs permission rule, ai thắng?** `PreToolUse` deny thắng cả bypass. Hook allow KHÔNG nới được deny/`ask` của org.
Hooks siết thêm, không nới lỏng.

**Rules có chặn được lệnh lách (binary khác)?** Không chắc — rules không phải shell security parser.
Việc critical → hook + OS sandbox.

**Background subagent bị deny trong `-p`?** Có thể: non-interactive không hiện prompt; hooks vẫn chạy cho tool calls của nó,
không hook decision → deny. Thiết kế hooks headless + allowlist rõ.

**Frontmatter hooks project subagent không chạy?** Cần trust workspace dialog cho folder chứa agent file;
`-p` không tính trusted → skip + log. User-level (`~/.claude/agents/`) và `--agents` inline thì chạy luôn.
