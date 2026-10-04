# Tips 10 — Debugging & Phím Tắt Power-User (Ít Người Biết)

## 1. Debug theo lớp (trước khi hỏi ai)

```
L1: /status (version/model/account) → /doctor (setup) → claude doctor (ngoài terminal)
L2: /context + /cost + /usage (context? tiền? ai ngốn?)
L3: /hooks + /mcp + /permissions (hook/mcp/rule nào chặn?)
L4: /debug (troubleshoot session) → /bug (gửi Anthropic)
```

## 2. Phím tắt & micro-features đáng tiền

| Phím/lệnh | Tác dụng |
|---|---|
| `Shift+Tab` | Xoay default → acceptEdits → plan → auto → bypass |
| `Double-Esc` (prompt rỗng) | Rewind menu (code + conversation) |
| `Ctrl+X Ctrl+K` ×2/3s | Kill all background subagents |
| `/btw <q>` | Hỏi nhanh, full context + no tools, không pollute history |
| `/fork`, `/branch` | Thử what-if không mất mạch chính |
| `/teleport` | Resume remote (claude.ai) session |
| `/export` | Xuất conversation ra text để share/debug |
| `/terminal-setup` | Fix Shift+Enter newline (iTerm2/VSCode/Kitty/Alacritty/Zed/Warp/WezTerm) |
| `/vim`, `/theme`, `/keybindings`, `/statusline` | Vim mode, theme, phím custom, status line |

## 3. Pitfalls power-user vẫn dính

- Infinite exploration ("investigate" không scope) → scope hẹp/subagent.
- Reviewer tự chấm bài mình → luôn fresh reviewer.
- Hook chặn nhầm vì substring (`main`) → match intent + test 4 ca push.
- Tin "should work" → đòi log/diff/test xanh.
- Dùng subagent cho việc skill làm được (tốn 20k overhead) / hook cho việc làm 1 lần (setup đắt hơn lợi).
- Thêm MCP khi data đã ở local repo.
- Skills pile-up: skill load sai lúc → thu hẹp description.
- Quên cloud ≠ local (config/hooks/MCP local không lên cloud).
- `--dangerously-skip-permissions` trên máy dev (chỉ CI sandbox).
