# 04 — Slash Commands Toàn Tập (Built-in + Bundled Skills)

> Bài 04 là INDEX tra cứu 76 slash commands v2.1.x. Mỗi lệnh có 1 folder riêng trong `commands/` (vd `commands/model-mode/plan/`), chứa README chi tiết: cú pháp, ví dụ, pitfalls, version floor.
> Cách dùng file này: tìm nhóm của bạn → đọc dòng mô tả 1 dòng → click link sang folder chi tiết.
> Gõ `/` trong session để xem lệnh khả dụng **ở môi trường của bạn** (khác plan/provider/version sẽ khác).

## Cách đọc index này

- Mỗi dòng = 1 lệnh: `/lệnh` — 1 dòng mô tả — link tới `./commands/<slug>/README.md`.
- Tổng 76 folders, chia 4 nhóm: Session & Context (18) · Model & Mode + Code (20) · Tri thức & Hệ thống (18) · Auth/Remote/Settings (20).
- Nếu link nào 404 ở máy bạn (lệnh vắng mặt) → xem mục "Công thức 5 lệnh + lưu ý version/provider" cuối file.

---

## Nhóm 1 — Session & Context (18)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/branch` | Tách branch session để thử what-if không mất mạch chính | [./commands/session-context/branch/README.md](./commands/session-context/branch/README.md) |
| `/clear` | Xóa context bắt đầu task mới (giữ CLAUDE.md), thói quen #1 | [./commands/session-context/clear/README.md](./commands/session-context/clear/README.md) |
| `/compact` | Nén context khi ~70-80%, kèm focus giữ cái quan trọng | [./commands/session-context/compact/README.md](./commands/session-context/compact/README.md) |
| `/context` | Visualize ai ngốn context dạng grid | [./commands/session-context/context/README.md](./commands/session-context/context/README.md) |
| `/copy` | Copy nội dung/conversation ra clipboard hoặc file | [./commands/session-context/copy/README.md](./commands/session-context/copy/README.md) |
| `/cost` | Xem token usage + billing của session hiện tại | [./commands/session-context/cost/README.md](./commands/session-context/cost/README.md) |
| `/export` | Export conversation ra file text để lưu/share | [./commands/session-context/export/README.md](./commands/session-context/export/README.md) |
| `/fork` | Fork session hiện tại thành session song song | [./commands/session-context/fork/README.md](./commands/session-context/fork/README.md) |
| `/help` | Xem help + nhóm lệnh khả dụng | [./commands/session-context/help/README.md](./commands/session-context/help/README.md) |
| `/rename` | Đặt tên gợi nhớ cho session hiện tại | [./commands/session-context/rename/README.md](./commands/session-context/rename/README.md) |
| `/resume` | Tiếp tục session cũ theo tên/id (`--continue` ngoài CLI) | [./commands/session-context/resume/README.md](./commands/session-context/resume/README.md) |
| `/rewind` | Khôi phục code + conversation về checkpoint (kèm menu Double-Esc) | [./commands/session-context/rewind/README.md](./commands/session-context/rewind/README.md) |
| `/tasks` | Xem background work/subagents đang chạy hoặc đã xong | [./commands/session-context/tasks/README.md](./commands/session-context/tasks/README.md) |
| `/todos` | Xem quản lý todo list của task nhiều bước | [./commands/session-context/todos/README.md](./commands/session-context/todos/README.md) |
| `/usage` | Breakdown limit theo category (skills, subagents, per-MCP-server) | [./commands/session-context/usage/README.md](./commands/session-context/usage/README.md) |
| `/restart` | Khởi động lại CLI giữ nguyên session | [./commands/session-context/restart/README.md](./commands/session-context/restart/README.md) |
| `/background` | Đẩy session thành agent nền, rảnh tay làm việc khác | [./commands/session-context/background/README.md](./commands/session-context/background/README.md) |
| `/recap` | Tóm tắt context khi quay lại session sau break | [./commands/session-context/recap/README.md](./commands/session-context/recap/README.md) |

## Nhóm 2 — Model & Mode + Code (20)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/model` | Đổi model giữa session (opus khó, haiku rẻ) | [./commands/model-mode/model/README.md](./commands/model-mode/model/README.md) |
| `/effort` | Đặt độ kỹ low/medium/high/xhigh/max/auto (≥2.1.205) | [./commands/model-mode/effort/README.md](./commands/model-mode/effort/README.md) |
| `/fast` | Bật fast mode Opus 4.6 khi cần tốc độ (cần extra-usage trước) | [./commands/model-mode/fast/README.md](./commands/model-mode/fast/README.md) |
| `/extra-usage` | Bật quota extra để dùng fast mode | [./commands/model-mode/extra-usage/README.md](./commands/model-mode/extra-usage/README.md) |
| `/plan` | Vào plan mode read-only, duyệt plan trước khi code | [./commands/model-mode/plan/README.md](./commands/model-mode/plan/README.md) |
| `/goal` | Đặt completion condition, Claude tự loop tới khi đạt (≥2.1.139) | [./commands/model-mode/goal/README.md](./commands/model-mode/goal/README.md) |
| `/permissions` | Quản lý allow/ask/deny rules cho tools | [./commands/model-mode/permissions/README.md](./commands/model-mode/permissions/README.md) |
| `/init` | Sinh CLAUDE.md nháp cho repo mới | [./commands/code-repo/init/README.md](./commands/code-repo/init/README.md) |
| `/diff` | Mở interactive diff viewer duyệt hunk trước commit | [./commands/code-repo/diff/README.md](./commands/code-repo/diff/README.md) |
| `/review` | Review nhanh diff hiện tại (nhẹ hơn code-review) | [./commands/code-repo/review/README.md](./commands/code-repo/review/README.md) |
| `/code-review` | Review sâu theo PR/branch range (từ 2.1.215 chỉ chạy khi gọi) | [./commands/code-repo/code-review/README.md](./commands/code-repo/code-review/README.md) |
| `/ultrareview` | Deep multi-agent review trong cloud sandbox | [./commands/code-repo/ultrareview/README.md](./commands/code-repo/ultrareview/README.md) |
| `/verify` | Build + chạy app thật để quan sát hành vi (≥2.1.145) | [./commands/code-repo/verify/README.md](./commands/code-repo/verify/README.md) |
| `/batch` | Chia change lớn thành 5-30 worktree-isolated subagents, mỗi đứa 1 PR | [./commands/code-repo/batch/README.md](./commands/code-repo/batch/README.md) |
| `/loop` | Lặp task theo schedule (kết hợp /schedule routines) | [./commands/code-repo/loop/README.md](./commands/code-repo/loop/README.md) |
| `/btw` | Hỏi nhanh dùng full context nhưng không thêm vào history | [./commands/code-repo/btw/README.md](./commands/code-repo/btw/README.md) |
| `/security-review` | Quét bảo mật on-demand trên branch hiện tại | [./commands/code-repo/security-review/README.md](./commands/code-repo/security-review/README.md) |
| `/run` | Mở app thật và lái nó để thấy change chạy được | [./commands/code-repo/run/README.md](./commands/code-repo/run/README.md) |
| `/subtask` | Giao việc phụ cho subagent, báo về ngay trong session | [./commands/code-repo/subtask/README.md](./commands/code-repo/subtask/README.md) |
| `/fewer-permission-prompts` | Quét transcripts, đề xuất allowlist read-only cho đỡ hỏi | [./commands/code-repo/fewer-permission-prompts/README.md](./commands/code-repo/fewer-permission-prompts/README.md) |

## Nhóm 3 — Tri thức & Hệ thống (18)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/memory` | Sửa CLAUDE.md entries + bật/tắt auto-memory | [./commands/knowledge-system/memory/README.md](./commands/knowledge-system/memory/README.md) |
| `/rules` | Quản lý `.claude/rules/` theo path | [./commands/knowledge-system/rules/README.md](./commands/knowledge-system/rules/README.md) |
| `/agents` | Panel Running + Library quản lý subagents | [./commands/knowledge-system/agents/README.md](./commands/knowledge-system/agents/README.md) |
| `/mcp` | Quản lý MCP connections/OAuth, reconnect/enable/disable | [./commands/knowledge-system/mcp/README.md](./commands/knowledge-system/mcp/README.md) |
| `/plugin` | Plugin manager: Discover/Browse/Manage plugins | [./commands/knowledge-system/plugin/README.md](./commands/knowledge-system/plugin/README.md) |
| `/hooks` | Xem hooks cho tool events (Pre/PostToolUse, Stop...) | [./commands/knowledge-system/hooks/README.md](./commands/knowledge-system/hooks/README.md) |
| `/doctor` | Chẩn đoán setup, version, trim CLAUDE.md (≥2.1.206) | [./commands/knowledge-system/doctor/README.md](./commands/knowledge-system/doctor/README.md) |
| `/debug` | Troubleshoot session/tools khi có lỗi lạ | [./commands/knowledge-system/debug/README.md](./commands/knowledge-system/debug/README.md) |
| `/bug` | Report bug về Claude Code cho Anthropic | [./commands/knowledge-system/bug/README.md](./commands/knowledge-system/bug/README.md) |
| `/pr_comments` | Liệt kê PR comments để address từng cái | [./commands/code-repo/pr_comments/README.md](./commands/code-repo/pr_comments/README.md) |
| `/claude-api` | Hướng dẫn gọi Claude API / migrate sang API usage | [./commands/knowledge-system/claude-api/README.md](./commands/knowledge-system/claude-api/README.md) |
| `/simplify` | Rút gọn code/context thừa theo gợi ý | [./commands/knowledge-system/simplify/README.md](./commands/knowledge-system/simplify/README.md) |
| `/insights` | Báo cáo thói quen coding, streaks, model prefs | [./commands/knowledge-system/insights/README.md](./commands/knowledge-system/insights/README.md) |
| `/stats` | Thống kê coding dạng HTML report cuối tuần | [./commands/knowledge-system/stats/README.md](./commands/knowledge-system/stats/README.md) |
| `/run-skill-generator` | Ghi recipe cách chạy app thành skill tái dùng | [./commands/code-repo/run-skill-generator/README.md](./commands/code-repo/run-skill-generator/README.md) |
| `/skill-doctor` | Báo cáo skill nào ngốn context, skill nào chết lâm sàng | [./commands/knowledge-system/skill-doctor/README.md](./commands/knowledge-system/skill-doctor/README.md) |
| `/mcp-serve` | Biến Claude Code thành MCP server cho app khác gọi | [./commands/knowledge-system/mcp-serve/README.md](./commands/knowledge-system/mcp-serve/README.md) |
| `/plugin-validate` | Audit plugin/mod trước khi cài | [./commands/knowledge-system/plugin-validate/README.md](./commands/knowledge-system/plugin-validate/README.md) |

## Nhóm 4 — Auth/Remote/Settings (20)

| Lệnh | Mô tả 1 dòng | Chi tiết |
|---|---|---|
| `/login` | Đăng nhập tài khoản Claude (Pro/Max/API) | [./commands/auth-settings/login/README.md](./commands/auth-settings/login/README.md) |
| `/logout` | Đăng xuất, xóa credentials local | [./commands/auth-settings/logout/README.md](./commands/auth-settings/logout/README.md) |
| `/exit` | Thoát session hiện tại (giữ history để resume) | [./commands/auth-settings/exit/README.md](./commands/auth-settings/exit/README.md) |
| `/teleport` | Chuyển session sang máy/IDE khác giữ nguyên context | [./commands/auth-settings/teleport/README.md](./commands/auth-settings/teleport/README.md) |
| `/mobile` | Pair/setup điều khiển session từ mobile | [./commands/auth-settings/mobile/README.md](./commands/auth-settings/mobile/README.md) |
| `/remote-env` | Quản lý biến môi trường cho remote/cloud session | [./commands/auth-settings/remote-env/README.md](./commands/auth-settings/remote-env/README.md) |
| `/cd` | Đổi working dir giữ prompt cache (≥2.1.169) | [./commands/auth-settings/cd/README.md](./commands/auth-settings/cd/README.md) |
| `/add-dir` | Thêm thư mục ngoài vào context (cross-repo) | [./commands/auth-settings/add-dir/README.md](./commands/auth-settings/add-dir/README.md) |
| `/config` | Mở settings/config (alias /settings) | [./commands/auth-settings/config/README.md](./commands/auth-settings/config/README.md) |
| `/status` | Xem version/model/account hiện tại | [./commands/auth-settings/status/README.md](./commands/auth-settings/status/README.md) |
| `/ide` | Kết nối/quản lý IDE integration (VS Code/JetBrains) | [./commands/auth-settings/ide/README.md](./commands/auth-settings/ide/README.md) |
| `/theme` | Đổi theme/giao diện terminal | [./commands/auth-settings/theme/README.md](./commands/auth-settings/theme/README.md) |
| `/keybindings` | Xem/sửa phím tắt trong session | [./commands/auth-settings/keybindings/README.md](./commands/auth-settings/keybindings/README.md) |
| `/vim` | Bật/tắt vim keybindings cho input | [./commands/auth-settings/vim/README.md](./commands/auth-settings/vim/README.md) |
| `/statusline` | Cấu hình dòng statusline hiển thị dưới prompt | [./commands/auth-settings/statusline/README.md](./commands/auth-settings/statusline/README.md) |
| `/terminal-setup` | Setup terminal (font, truecolor, keycodes) cho Claude Code | [./commands/auth-settings/terminal-setup/README.md](./commands/auth-settings/terminal-setup/README.md) |
| `/sandbox` | Quản lý sandbox cô lập lệnh nguy hiểm | [./commands/auth-settings/sandbox/README.md](./commands/auth-settings/sandbox/README.md) |
| `/voice` | Nói thay vì gõ (giữ Space để nói, thả để gửi) | [./commands/auth-settings/voice/README.md](./commands/auth-settings/voice/README.md) |
| `/setup-bedrock` | Wizard cắm Claude Code vào AWS Bedrock | [./commands/auth-settings/setup-bedrock/README.md](./commands/auth-settings/setup-bedrock/README.md) |
| `/setup-vertex` | Wizard cắm Claude Code vào Google Vertex AI | [./commands/auth-settings/setup-vertex/README.md](./commands/auth-settings/setup-vertex/README.md) |

---

## Công thức 5 lệnh session đầu (giữ nguyên, làm 1 lần/repo)

```
 /init → /memory → /mcp → (nhờ Claude tạo subagents cần thiết) → /permissions
```

- Bước 1 `/init` — sinh CLAUDE.md nháp, đọc rồi cắt 50% (chi tiết [./commands/code-repo/init/README.md](./commands/code-repo/init/README.md)).
- Bước 2 `/memory` — xem entries, bật/tắt auto-memory, xóa learnings sai ([./commands/knowledge-system/memory/README.md](./commands/knowledge-system/memory/README.md)).
- Bước 3 `/mcp` — thêm GitHub (+ DB nếu có), test "liệt kê 5 PRs mở gần nhất" ([./commands/knowledge-system/mcp/README.md](./commands/knowledge-system/mcp/README.md)).
- Bước 4 tạo subagents — prompt "tạo 2 subagents: explorer (read-only) và tester (chạy pnpm test)", duyệt bằng `/agents` ([./commands/knowledge-system/agents/README.md](./commands/knowledge-system/agents/README.md)).
- Bước 5 `/permissions` — đặt allow/ask/deny, test 1 task nhỏ end-to-end ([./commands/model-mode/permissions/README.md](./commands/model-mode/permissions/README.md)).

## Lưu ý version/provider (giữ nguyên)

- Không thấy lệnh nào → check `/status` + plan/provider trước khi kết luận lệnh không tồn tại.
- Version floor hay gặp: `/cd` ≥2.1.169, `/goal` ≥2.1.139, `/verify` ≥2.1.145, `/effort` ≥2.1.205, `/mcp` text-mode ≥2.1.205, `/verify`+`/code-review` không auto-trigger từ ≥2.1.215.
- Provider cắt feature: `/design-sync`, `/radio` và một số bundled skills vắng mặt trên Bedrock/AWS Platform/GCP Agent Platform — gõ `/` để xem list thực tế ở máy bạn.
- Checklist khi "lệnh không tồn tại": `/status` → `claude --version` → đối chiếu version floor → đối chiếu provider → gõ `/` xem list thực tế.
