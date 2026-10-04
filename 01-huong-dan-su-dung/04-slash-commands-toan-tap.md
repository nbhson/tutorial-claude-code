# 04 — Slash Commands Toàn Tập (Built-in + Bundled Skills)

> Bài 04 là INDEX tra cứu 62 slash commands v2.1.x. Mỗi lệnh có 1 folder riêng trong `commands/` (vd `commands/plan/`), chứa README chi tiết: cú pháp, ví dụ, pitfalls, version floor.
> Cách dùng file này: tìm nhóm của bạn → đọc dòng mô tả 1 dòng → click link sang folder chi tiết.
> Gõ `/` trong session để xem lệnh khả dụng **ở môi trường của bạn** (khác plan/provider/version sẽ khác).

## Cách đọc index này

- Mỗi dòng = 1 lệnh: `/lệnh` — 1 dòng mô tả — link tới `./commands/<slug>/README.md`.
- Tổng 62 folders, chia 4 nhóm: Session & Context (15) · Model & Mode + Code (16) · Tri thức & Hệ thống (14) · Auth/Remote/Settings (17).
- Nếu link nào 404 ở máy bạn (lệnh vắng mặt) → xem mục "Công thức 5 lệnh + lưu ý version/provider" cuối file.

---

## Nhóm 1 — Session & Context (15)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/branch` | Tách branch session để thử what-if không mất mạch chính | [./commands/branch/README.md](./commands/branch/README.md) |
| `/clear` | Xóa context bắt đầu task mới (giữ CLAUDE.md), thói quen #1 | [./commands/clear/README.md](./commands/clear/README.md) |
| `/compact` | Nén context khi ~70-80%, kèm focus giữ cái quan trọng | [./commands/compact/README.md](./commands/compact/README.md) |
| `/context` | Visualize ai ngốn context dạng grid | [./commands/context/README.md](./commands/context/README.md) |
| `/copy` | Copy nội dung/conversation ra clipboard hoặc file | [./commands/copy/README.md](./commands/copy/README.md) |
| `/cost` | Xem token usage + billing của session hiện tại | [./commands/cost/README.md](./commands/cost/README.md) |
| `/export` | Export conversation ra file text để lưu/share | [./commands/export/README.md](./commands/export/README.md) |
| `/fork` | Fork session hiện tại thành session song song | [./commands/fork/README.md](./commands/fork/README.md) |
| `/help` | Xem help + nhóm lệnh khả dụng | [./commands/help/README.md](./commands/help/README.md) |
| `/rename` | Đặt tên gợi nhớ cho session hiện tại | [./commands/rename/README.md](./commands/rename/README.md) |
| `/resume` | Tiếp tục session cũ theo tên/id (`--continue` ngoài CLI) | [./commands/resume/README.md](./commands/resume/README.md) |
| `/rewind` | Khôi phục code + conversation về checkpoint (kèm menu Double-Esc) | [./commands/rewind/README.md](./commands/rewind/README.md) |
| `/tasks` | Xem background work/subagents đang chạy hoặc đã xong | [./commands/tasks/README.md](./commands/tasks/README.md) |
| `/todos` | Xem quản lý todo list của task nhiều bước | [./commands/todos/README.md](./commands/todos/README.md) |
| `/usage` | Breakdown limit theo category (skills, subagents, per-MCP-server) | [./commands/usage/README.md](./commands/usage/README.md) |

## Nhóm 2 — Model & Mode + Code (16)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/model` | Đổi model giữa session (opus khó, haiku rẻ) | [./commands/model/README.md](./commands/model/README.md) |
| `/effort` | Đặt độ kỹ low/medium/high/xhigh/max/auto (≥2.1.205) | [./commands/effort/README.md](./commands/effort/README.md) |
| `/fast` | Bật fast mode Opus 4.6 khi cần tốc độ (cần extra-usage trước) | [./commands/fast/README.md](./commands/fast/README.md) |
| `/extra-usage` | Bật quota extra để dùng fast mode | [./commands/extra-usage/README.md](./commands/extra-usage/README.md) |
| `/plan` | Vào plan mode read-only, duyệt plan trước khi code | [./commands/plan/README.md](./commands/plan/README.md) |
| `/goal` | Đặt completion condition, Claude tự loop tới khi đạt (≥2.1.139) | [./commands/goal/README.md](./commands/goal/README.md) |
| `/permissions` | Quản lý allow/ask/deny rules cho tools | [./commands/permissions/README.md](./commands/permissions/README.md) |
| `/init` | Sinh CLAUDE.md nháp cho repo mới | [./commands/init/README.md](./commands/init/README.md) |
| `/diff` | Mở interactive diff viewer duyệt hunk trước commit | [./commands/diff/README.md](./commands/diff/README.md) |
| `/review` | Review nhanh diff hiện tại (nhẹ hơn code-review) | [./commands/review/README.md](./commands/review/README.md) |
| `/code-review` | Review sâu theo PR/branch range (từ 2.1.215 chỉ chạy khi gọi) | [./commands/code-review/README.md](./commands/code-review/README.md) |
| `/ultrareview` | Deep multi-agent review trong cloud sandbox | [./commands/ultrareview/README.md](./commands/ultrareview/README.md) |
| `/verify` | Build + chạy app thật để quan sát hành vi (≥2.1.145) | [./commands/verify/README.md](./commands/verify/README.md) |
| `/batch` | Chia change lớn thành 5-30 worktree-isolated subagents, mỗi đứa 1 PR | [./commands/batch/README.md](./commands/batch/README.md) |
| `/loop` | Lặp task theo schedule (kết hợp /schedule routines) | [./commands/loop/README.md](./commands/loop/README.md) |
| `/btw` | Hỏi nhanh dùng full context nhưng không thêm vào history | [./commands/btw/README.md](./commands/btw/README.md) |

## Nhóm 3 — Tri thức & Hệ thống (14)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/memory` | Sửa CLAUDE.md entries + bật/tắt auto-memory | [./commands/memory/README.md](./commands/memory/README.md) |
| `/rules` | Quản lý `.claude/rules/` theo path | [./commands/rules/README.md](./commands/rules/README.md) |
| `/agents` | Panel Running + Library quản lý subagents | [./commands/agents/README.md](./commands/agents/README.md) |
| `/mcp` | Quản lý MCP connections/OAuth, reconnect/enable/disable | [./commands/mcp/README.md](./commands/mcp/README.md) |
| `/plugin` | Plugin manager: Discover/Browse/Manage plugins | [./commands/plugin/README.md](./commands/plugin/README.md) |
| `/hooks` | Xem hooks cho tool events (Pre/PostToolUse, Stop...) | [./commands/hooks/README.md](./commands/hooks/README.md) |
| `/doctor` | Chẩn đoán setup, version, trim CLAUDE.md (≥2.1.206) | [./commands/doctor/README.md](./commands/doctor/README.md) |
| `/debug` | Troubleshoot session/tools khi có lỗi lạ | [./commands/debug/README.md](./commands/debug/README.md) |
| `/bug` | Report bug về Claude Code cho Anthropic | [./commands/bug/README.md](./commands/bug/README.md) |
| `/pr_comments` | Liệt kê PR comments để address từng cái | [./commands/pr_comments/README.md](./commands/pr_comments/README.md) |
| `/claude-api` | Hướng dẫn gọi Claude API / migrate sang API usage | [./commands/claude-api/README.md](./commands/claude-api/README.md) |
| `/simplify` | Rút gọn code/context thừa theo gợi ý | [./commands/simplify/README.md](./commands/simplify/README.md) |
| `/insights` | Báo cáo thói quen coding, streaks, model prefs | [./commands/insights/README.md](./commands/insights/README.md) |
| `/stats` | Thống kê coding dạng HTML report cuối tuần | [./commands/stats/README.md](./commands/stats/README.md) |

## Nhóm 4 — Auth/Remote/Settings (17)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/login` | Đăng nhập tài khoản Claude (Pro/Max/API) | [./commands/login/README.md](./commands/login/README.md) |
| `/logout` | Đăng xuất, xóa credentials local | [./commands/logout/README.md](./commands/logout/README.md) |
| `/exit` | Thoát session hiện tại (giữ history để resume) | [./commands/exit/README.md](./commands/exit/README.md) |
| `/teleport` | Chuyển session sang máy/IDE khác giữ nguyên context | [./commands/teleport/README.md](./commands/teleport/README.md) |
| `/mobile` | Pair/setup điều khiển session từ mobile | [./commands/mobile/README.md](./commands/mobile/README.md) |
| `/remote-env` | Quản lý biến môi trường cho remote/cloud session | [./commands/remote-env/README.md](./commands/remote-env/README.md) |
| `/cd` | Đổi working dir giữ prompt cache (≥2.1.169) | [./commands/cd/README.md](./commands/cd/README.md) |
| `/add-dir` | Thêm thư mục ngoài vào context (cross-repo) | [./commands/add-dir/README.md](./commands/add-dir/README.md) |
| `/config` | Mở settings/config (alias /settings) | [./commands/config/README.md](./commands/config/README.md) |
| `/status` | Xem version/model/account hiện tại | [./commands/status/README.md](./commands/status/README.md) |
| `/ide` | Kết nối/quản lý IDE integration (VS Code/JetBrains) | [./commands/ide/README.md](./commands/ide/README.md) |
| `/theme` | Đổi theme/giao diện terminal | [./commands/theme/README.md](./commands/theme/README.md) |
| `/keybindings` | Xem/sửa phím tắt trong session | [./commands/keybindings/README.md](./commands/keybindings/README.md) |
| `/vim` | Bật/tắt vim keybindings cho input | [./commands/vim/README.md](./commands/vim/README.md) |
| `/statusline` | Cấu hình dòng statusline hiển thị dưới prompt | [./commands/statusline/README.md](./commands/statusline/README.md) |
| `/terminal-setup` | Setup terminal (font, truecolor, keycodes) cho Claude Code | [./commands/terminal-setup/README.md](./commands/terminal-setup/README.md) |
| `/sandbox` | Quản lý sandbox cô lập lệnh nguy hiểm | [./commands/sandbox/README.md](./commands/sandbox/README.md) |

---

## Công thức 5 lệnh session đầu (giữ nguyên, làm 1 lần/repo)

```
 /init → /memory → /mcp → (nhờ Claude tạo subagents cần thiết) → /permissions
```

- Bước 1 `/init` — sinh CLAUDE.md nháp, đọc rồi cắt 50% (chi tiết [./commands/init/README.md](./commands/init/README.md)).
- Bước 2 `/memory` — xem entries, bật/tắt auto-memory, xóa learnings sai ([./commands/memory/README.md](./commands/memory/README.md)).
- Bước 3 `/mcp` — thêm GitHub (+ DB nếu có), test "liệt kê 5 PRs mở gần nhất" ([./commands/mcp/README.md](./commands/mcp/README.md)).
- Bước 4 tạo subagents — prompt "tạo 2 subagents: explorer (read-only) và tester (chạy pnpm test)", duyệt bằng `/agents` ([./commands/agents/README.md](./commands/agents/README.md)).
- Bước 5 `/permissions` — đặt allow/ask/deny, test 1 task nhỏ end-to-end ([./commands/permissions/README.md](./commands/permissions/README.md)).

## Lưu ý version/provider (giữ nguyên)

- Không thấy lệnh nào → check `/status` + plan/provider trước khi kết luận lệnh không tồn tại.
- Version floor hay gặp: `/cd` ≥2.1.169, `/goal` ≥2.1.139, `/verify` ≥2.1.145, `/effort` ≥2.1.205, `/mcp` text-mode ≥2.1.205, `/verify`+`/code-review` không auto-trigger từ ≥2.1.215.
- Provider cắt feature: `/design-sync`, `/radio` và một số bundled skills vắng mặt trên Bedrock/AWS Platform/GCP Agent Platform — gõ `/` để xem list thực tế ở máy bạn.
- Checklist khi "lệnh không tồn tại": `/status` → `claude --version` → đối chiếu version floor → đối chiếu provider → gõ `/` xem list thực tế.
