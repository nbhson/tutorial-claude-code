# 04 — Slash Commands Toàn Tập (Built-in + Bundled Skills)

> Gõ `/` trong session để liệt kê lệnh khả dụng **ở môi trường của bạn** (khác plan/provider/version sẽ khác).

## 1. Hai loại entries

- **Built-in command**: logic code cứng trong CLI (`/help`, `/clear`, `/compact`, `/model`, `/permissions`...).
- **Skill (bundled)**: prompt trao cho Claude, Claude tự orchestrate (vd `/debug`, `/code-review`, `/batch`, `/doctor`, `/loop`, `/claude-api`).
  Từ v2.1.215: `/verify` và `/code-review` **chỉ chạy khi bạn gọi**, không tự trigger (đỡ tốn token).
- **Workflow**: dynamic workflow bung ra nhiều subagents chạy background (vd `/batch`).
- **MCP prompts**: `/mcp__<server>__<prompt>` do MCP server expose, discover động.

## 2. Bảng tra cứu (tổng hợp từ docs + thực tế v2.1.x)

### Session & context

| Lệnh | Dùng khi nào |
|---|---|
| `/help` | Xem help |
| `/clear` | Xóa context, bắt đầu task mới (giữ CLAUDE.md) — thói quen #1 |
| `/compact [focus]` | Nén context khi >80%, kèm focus ("focus on auth changes") |
| `/context` | Visualize context usage dạng grid |
| `/cost` | Token usage + billing session hiện tại |
| `/usage` | Breakdown theo category (skills, subagents, plugins, per-MCP-server) — tìm ai ngốn limit |
| `/export [file]` | Export conversation ra text |
| `/resume [id]`, `/fork`, `/branch`, `/rename` | Resume/fork/branch/đặt tên session |
| `/rewind` (+ double-Esc menu) | Khôi phục code + conversation về checkpoint |
| `/todos`, `/tasks` (`/bashes`) | Xem todos / background work (subagents đã xong...) |

### Model & effort & mode

| Lệnh | Dùng khi nào |
|---|---|
| `/model [opus\|sonnet\|haiku]` | Đổi model giữa session (việc khó→Opus, việc rẻ→Haiku) |
| `/effort [low\|medium\|high\|xhigh\|max\|auto]` | Độ kỹ (≥v2.1.205, `max/ultracode` chỉ session hiện tại) |
| `/fast`, `/extra-usage` | Fast mode Opus 4.6 (cần bật extra-usage trước) |
| `/plan` | Vào plan mode (read-only, duyệt trước khi code) |
| `/goal <điều kiện>` (≥2.1.139) | Đặt completion condition, Claude tự làm tới khi đạt; `/goal clear` dừng |
| `/permissions` (`/allowed-tools`) | Quản lý allow/ask/deny rules |

### Làm việc với code & repo

| Lệnh | Dùng khi nào |
|---|---|
| `/init` | Sinh CLAUDE.md nháp (lần đầu trong repo) |
| `/diff` | Interactive diff viewer trước khi commit |
| `/review`, `/code-review [PR\|branch]` | Review; `/ultrareview` = deep multi-agent review trong cloud sandbox |
| `/verify` (≥2.1.145) | Build + chạy app thật + quan sát, không chỉ tin test/typecheck |
| `/pr_comments` | Xem PR comments để address |
| `/batch` | Chia 1 change lớn thành 5–30 worktree-isolated subagents, mỗi đứa 1 PR |
| `/loop` | Lặp task theo schedule (kết hợp `/schedule` routines) |

### Tri thức & hệ thống

| Lệnh | Dùng khi nào |
|---|---|
| `/memory` | Sửa CLAUDE.md files, auto-memory |
| `/rules` | Quản lý `.claude/rules/` |
| `/agents` | Panel Running (subagents live) + Library (definitions) |
| `/skills` tương đương | Quản lý skills (tùy bản) |
| `/mcp [reconnect\|enable\|disable]` | Quản lý MCP connections/OAuth (no-arg mở list; `-p` non-interactive in text summary ≥2.1.205) |
| `/plugin` (`/plugins`) | Plugin manager: Discover/Browse/Manage |
| `/hooks` | Xem hooks cho tool events |
| `/config` (`/settings`), `/status`, `/ide`, `/theme`, `/keybindings`, `/vim`, `/statusline`, `/terminal-setup`, `/sandbox` | Settings/giao diện/môi trường |
| `/doctor` (`/checkup`), `/debug`, `/bug` | Chẩn đoán, troubleshoot, report bug |
| `/login`, `/logout`, `/teleport`, `/mobile`, `/remote-env`, `/cd <dir>`, `/add-dir` | Auth, remote/mobile, di chuyển working dir (giữ prompt cache; `/cd` ≥2.1.169) |
| `/btw <câu hỏi>` | Hỏi nhanh dùng full context nhưng **không** thêm vào history (ngược với subagent) |
| `/stats`, `/insights`, `/cost`, `/usage` | Thống kê thói quen coding (HTML report), streaks, model prefs |
| `/simplify`, `/claude-api [...]`, `/design-sync`, `/radio`, `/run`, `/subtask` | Bundled skills/workflows theo version/plan |

## 3. Session đầu trong repo — công thức 5 lệnh

```
/init → /memory → /mcp → (nhờ Claude tạo subagents cần thiết) → /permissions
```

## 4. Custom commands = Skills (đã merge)

`.claude/commands/deploy.md` ≡ `.claude/skills/deploy/SKILL.md` → cùng tạo `/deploy`.
File cũ vẫn chạy, nhưng đường mới (skills) thêm được: frontmatter (`description`, `disable-model-invocation`,
`allowed-tools`, `context: fork`, `agent:`, `model:`...), thư mục support files, auto-trigger.
`$ARGUMENTS` để nhận input: `/deploy staging`.

## 5. Lưu ý version/plan

- Không thấy lệnh nào → check version (`/status`) + plan/provider (bài 10 & FAQ).
  Vd `/design-sync`, `/radio` vắng mặt trên Bedrock/AWS Platform/GCP Agent Platform.
- Non-interactive (`-p`): một số lệnh có text-mode riêng (vd `/mcp` in summary).
