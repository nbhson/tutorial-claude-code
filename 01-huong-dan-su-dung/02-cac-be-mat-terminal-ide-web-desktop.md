# 02 — Các Bề Mặt Sử Dụng: Terminal, IDE, Desktop, Web, Mobile

## 1. Terminal CLI — sức mạnh gốc

```bash
claude                     # mở session interactive
claude "fix failing tests" # 1-shot prompt
claude -p "summarize diff" # print mode (non-interactive, dùng cho CI/scripts)
claude --continue          # tiếp tục session gần nhất
claude --resume <id>       # resume theo id/name (hoặc mở picker)
claude --agent explore     # chạy cả session dưới 1 subagent persona
claude --add-dir ../shared # cho phép truy cập thêm thư mục
claude --cloud             # ném session lên cloud (cần GitHub + setup /web-setup)
claude --dangerously-skip-permissions  # bypass (chỉ CI sandbox, KHÔNG dùng máy dev)
```

Flags quan trọng khác: `--mcp-config`, `--disable-slash-commands`, `--permission-mode`,
`--model`, `--agents '{...}'` (định nghĩa agent inline JSON).

**Shift+Tab**: xoay vòng permission modes `default → acceptEdits → plan → auto → bypassPermissions`.
**Double-Esc** (prompt rỗng): mở rewind menu (checkpointing) — khôi phục cả code + conversation.
**Ctrl+X Ctrl+K ×2 trong 3s**: kill toàn bộ background subagents.

## 2. IDE (VS Code / JetBrains)

Điểm cộng duy nhất đáng tiền so với terminal:

- Inline diffs ngay trong editor (review từng hunk).
- `@`-mention file/selection chính xác.
- Plan review UI: duyệt plan trước khi cho code.
- Conversation history panel.

Cấu hình dùng chung với CLI nên không cần setup 2 lần. `/ide` xem integrations + status.

## 3. Desktop app

- Chạy local hoặc cloud session; review diff trực quan; multi-session side-by-side.
- Schedule recurring tasks; kick off cloud sessions.
- Gateway routing có thể cấu hình qua managed settings (Team/Enterprise).

## 4. Web (`claude.ai/code`) — research preview (Pro/Max/Team, Enterprise seat đủ điều kiện)

Luồng chuẩn:

1. Connect GitHub repo → Claude clone vào isolated VM.
2. Submit task (mode dropdown: **Accept edits** = tự sửa + push branch; **Plan** = đề xuất, chờ duyệt).
   Cloud session KHÔNG có Manual/Bypass permissions.
3. Review PR, comment, Claude address; bật auto-fix PR nếu muốn.
4. Teleport session về terminal khi cần (`/teleport` ngược lại: resume remote session từ claude.ai).

Setup nhanh từ terminal (cần GitHub CLI `gh`):

```bash
/web-setup   # trong CLI: sync gh token, tạo cloud environment (Trusted network, chưa có setup script)
```

Rồi edit environment: network access levels, env vars, setup script. Cài mobile app để monitor.

Từ terminal tạo cloud session / task định kỳ:

```bash
claude --cloud "migrate table X, mở PR"
# + /schedule cho routines: morning digest, CI failure analysis overnight, weekly dep audit
```

## 5. Mobile + Remote Control + Slack

- `/mobile` hiện QR để pair điện thoại; sessions persist cross-device.
- Remote Control: chat từ claude.ai/mobile nhưng code chạy **trên máy bạn** (dùng local config).
- Slack: chạy Claude trong channel (cần subscription + admin enable tùy plan).

## 6. Chọn surface theo task (cheat)

| Task | Chọn |
|---|---|
| Code hàng ngày | Terminal hoặc IDE |
| Review diff lớn, nhiều session | Desktop |
| Task dài 30'+, không cần máy mở | Web (`--cloud`) |
| Ra ngoài vẫn muốn theo dõi | Mobile/Remote |
| Việc lặp lại theo lịch | Routines `/schedule` + Desktop/Web |
| Team automation | CI/CD + Agent SDK (bài 12) |

## 7. Lưu ý config theo surface

- Local (CLI/IDE/Desktop-local/Remote): dùng `~/.claude/` + `.claude/` repo + env máy bạn.
- Cloud (Web/Desktop-cloud): chỉ repo (+ cloud environment vars/setup script). Đừng ngạc nhiên khi
  MCP local/hook local "biến mất" trên cloud — phải cấu hình lại trong environment.
