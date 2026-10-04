# Tips 09 — Teamwork: Chuẩn Hóa Claude Code Cho Cả Team

## 1. Cái gì commit, cái gì không

| Commit (`settings.json`, `.claude/`, `.mcp.json`, `CLAUDE.md`) | Không commit (`settings.local.json`, `~/.claude/`, secrets) |
|---|---|
| Verified commands, code style, architecture rules | Preferences cá nhân, project overrides riêng |
| Skills/agents/hooks chuẩn team | API tokens (chỉ qua env vars) |
| MCP servers project-scope (URL không secret) | Tokens/headers bí mật |

## 2. Gói phân phối: plugin > copy-paste dotfiles

Bộ setup chuẩn (skills + hooks + agents + MCP) dùng ≥2 repo → đóng **plugin** (`/plugin` manager).
Teammate cài 1 phát đồng bộ; Browse hiện trước commands/agents/skills/hooks/MCP để audit.
Org lớn: server-managed settings + policy (Team/Enterprise).

## 3. Quy trình PR với Claude (đề xuất)

```
Dev: plan mode → implement theo phase → /verify → /diff tự đọc
  → spawn reviewer subagent fresh (hoặc /code-review) → fix gaps
  → /ship (merge base, test, bump, changelog, commit, push, PR)
CI: claude -p review job (scope hẹp, dontAsk) + human review
Merge: squash, remove worktrees, sync docs (routine)
```

## 4. Code Review chuẩn team (`/code-review` + `/ultrareview`)

- Mọi PR nontrivial qua reviewer fresh-context trước human.
- PR lớn/rủi ro cao → `/ultrareview` (multi-agent, cloud sandbox).
- Calibration reviewer bằng 3 diffs lịch sử repo để chuẩn "độ khó tính" (false-positive ~15% là ok cho self-review).

## 5. Chống drift & đo lường

- `/insights` (HTML report thói quen coding), `/stats` (usage/streaks), analytics dashboard (Team/Enterprise).
- RoutineDocs-sync sau merge; weekly dep audit; overnight CI failure analysis.
- Monthly: `/doctor` toàn team + prune skills/MCP + review hook performance.
