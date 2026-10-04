# 10 — Permissions, Modes & Tính Khả Dụng Theo Plan/Provider

## 1. Permission rules: allow / ask / deny

- Read-only thường chạy không hỏi; **edit file + shell** tuân permission mode + rules.
- Quản lý: `/permissions` (alias `/allowed-tools`) — xem rules theo scope, thêm/xóa, quản lý working dirs,
  review auto-mode denials gần đây.
- File: `.claude/settings.json` (team, commit) vs `.claude/settings.local.json` (personal, không commit),
  cộng managed policy (org) — xem merged result ở `/permissions`, đừng đoán.
- Rules **không phải shell security parser**: command tương đương qua binary khác có thể lọt —
  việc thật sự critical thì dùng **hook + OS sandbox**, đừng chỉ trông vào rules.
- Hooks `PreToolUse` deny thắng cả `bypassPermissions`; hook allow không nới được deny/`ask` của org.

## 2. Permission modes (Shift+Tab để xoay)

```
default → acceptEdits → plan → auto → bypassPermissions
```

| Mode | Hành vi | Khi dùng |
|---|---|---|
| `default` | Hỏi khi cần | Mặc định hàng ngày |
| `acceptEdits` | Tự sửa file, push branch (cloud default) | Tin task, muốn nhanh |
| `plan` | **Read-only**: outline thay đổi, chờ duyệt mới được code | Mọi task multi-file/kiến trúc (phản xạ) |
| `auto` | Tự tiến xa, ít hỏi (có classifier + deny rules lưng) | Task dài có verification gate |
| `bypassPermissions` (`--dangerously-skip-permissions`) | Bỏ hỏi | **Chỉ CI sandbox** — không dùng máy dev |

Cloud sessions (Web): chỉ Accept edits / Plan (/Auto tùy bản) — không Manual/Bypass.

## 3. Tính khả dụng: không phải feature nào cũng có ở mọi nơi

**Chạy local (CLI + IDE + Agent SDK + subagents/hooks/skills/CLAUDE.md/plugins/MCP/checkpoints/sandbox/workflows/OTel...)**: có trên **mọi provider**.

**Bắt buộc Claude subscription (claude.ai sign-in)**: Web, Mobile, Slack, Desktop app full,
Routines (`/schedule`), Ultraplan/Ultrareview, Code Review (Team/Enterprise), Remote Control,
Chrome extension, Computer use (Pro/Max), Artifacts (Pro/Max/Team/Enterprise tùy admin), Voice dictation.

**Khác nhau theo provider** (Console API key / Bedrock / AWS Platform / GCP Agent Platform / Foundry):

| Khả năng | Sub | Console | Bedrock | AWS Plat | GCP | Foundry |
|---|---|---|---|---|---|---|
| Web search | ✓ | ✓ | ✗ | ✓ | tùy | ✓ (hosted on Anthropic) |
| Fast mode | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Auto mode | ✓ | ✓ | tùy note | ✓ | tùy | tùy |
| Advisor / Channels | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |
| `/loop` scheduled | ✓ | ✓ | tùy | tùy | tùy | tùy |
| GH Actions / GitLab CI | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ |
| Analytics/server settings | Team/Ent | Team/Ent | ✗ | ✗ | ✗ | ✗ |

Vắng trên Bedrock/AWS/GCP thêm: `/design-sync`, `/radio`. Trên Foundry: CI/CD GitHub thiếu.
Chi tiết: docs `feature-availability`. Gặp "lệnh không tồn tại" → check provider + version trước khi kết luận bug.

## 4. Theo plan (sign-in claude.ai)

| Feature | Pro | Max | Team | Enterprise |
|---|---|---|---|---|
| Web / Routines / Remote / Computer use / Dispatch | ✓ | ✓ | ✓/admin | ✓/admin |
| Code Review | ✗ | ✗ | ✓ | ✓ |
| Artifacts | ✓ | ✓ | ✓ | admin-enabled |
| Analytics dashboard | ✗ | ✗ | ✓ | ✓ (+ API) |
| Server-managed settings / SSO | ✗ | ✗ | ✓ | ✓ (+SCIM/Compliance/ZDR) |
