# Cheatsheet Claude Code v2.1.292 (1 trang — in ra dán cạnh màn hình)

> Mọi dòng đều copy-paste được. Gõ `/` trong session để xem lệnh nào hiện ở máy bạn (version/provider khác nhau hiện khác nhau).
> Cập nhật 10/2026: Opus 5.5 là mặc định phần lớn gói, Fable 5.1 cho việc khó nhất, MCP protocol `2026-07-28`.

## CLI (ngoài terminal)

```bash
claude                                  # mở session mới
claude "refactor auth/ theo docs/spec.md"  # vd: giao task ngay khi mở
claude -p "tóm tắt diff main...HEAD"    # vd: headless cho CI (không tương tác)
claude --continue                       # vd: quay lại session gần nhất
claude --resume <id>                    # vd: mở lại session cũ theo id
claude doctor                           # vd: khám duplicate install, settings lỗi
claude agents                           # vd: xem/quản lý subagents đã định nghĩa
claude update && claude --version       # vd: update trước, debug sau
```

## Session / context (trong session)

```bash
/clear                                  # vd: xong task cũ -> trắng context làm task mới
/compact tóm tắt phần auth              # vd: cùng task nhưng context >60%
/context                                # vd: xem % đầy trước khi quyết clear/compact
/cost                                   # vd: tiền session này; /usage xem trần + breakdown
/export                                 # vd: lưu transcript trước khi /clear
/resume                                 # vd: cứu session sau khi clear nhầm
/fork                                   # vd: thử hướng B mà giữ bản gốc
/rewind                                 # vd: lỡ đi sai 5 bước -> quay checkpoint (double-Esc)
/todos                                  # vd: liệt kê todos; /tasks xem jobs nền
```

## Model / mode

```bash
/model sonnet                          # vd: task vừa; opus 5.5 (mặc định) cho kiến trúc, fable 5.1 cho việc khó nhất, haiku cho việc vặt
/effort high                            # vd: plan khó; low|medium|high|xhigh|max|auto
/fast                                   # vd: cần nhanh, chấp nhận ẩu hơn (Opus 5.5 fast mode ~2.5x, $8/$40)
/plan Thêm MoMo vào payments. Chỉ plan. # vd: task lớn -> khóa ghi, duyệt rồi mới code
/goal "pytest pass + không đổi API cũ"  # vd: đặt tiêu chí xong (≥2.1.139)
/permissions                            # vd: xem allow/ask/deny merged
# Shift+Tab xoay: default -> acceptEdits -> plan -> auto -> bypass (bypass chỉ CI sandbox)
# Fork mode (con song song giữ context) bật mặc định từ ≥2.1.232; tắt bằng CLAUDE_CODE_FORK_SUBAGENT=0
```

## Code / repo

```bash
/init                                   # vd: repo mới -> sinh CLAUDE.md từ code thật
/diff                                   # vd: sau mỗi bước code -> duyệt từng hunk
/review                                 # vd: nhận xét nhanh; /code-review cho PR/branch
/verify                                 # vd: build + chạy thật, paste output (≥2.1.145)
/security-review                        # vd: soi auth/input/crypto trước khi merge
/batch "mỗi worktree 1 service"         # vd: chia việc song song nhiều worktree
/subtask "viết test cho auth.ts"        # vd: việc phụ trong session (≥2.1.212)
/run                                    # vd: boot app thật + lái thử
/cd web                                 # vd: chuyển thư mục trong session (≥2.1.169)
```

## System / tri thức

```bash
/agents                                 # vd: xem subagents; giao việc ồn sang worker
/mcp                                    # vd: xem servers; /mcp reconnect github khi vàng
/hooks                                  # vd: xem hooks; rule miss 2 lần -> viết hook
/plugin                                 # vd: cài plugin team; validate trước khi tin
/doctor                                 # vd: khám tổng; /debug chẩn đoán session; /bug gửi report
/memory                                 # vd: tách sở thích cá nhân khỏi CLAUDE.md
/rules                                  # vd: rules theo path; /config xem settings
/skill-doctor                           # vd: soi skill ngốn context/chết lâm sàng (≥2.1.252)
/status                                 # vd: soi account/provider/model/version (gõ đầu mỗi lỗi lạ)
```

## Hooks events (nhớ 6 cái hay dùng nhất)

```bash
# PreToolUse (chặn trước khi chạy) | PostToolUse (lint sau khi ghi) | Stop (gate cuối turn)
# SessionStart | UserPromptSubmit | SubagentStop | Notification
# Types: command | http | mcp_tool | prompt | agent. Matcher case-sensitive.
```

## MCP day-one (3–6 servers là đủ)

```bash
claude mcp add --transport stdio github -- npx -y @modelcontextprotocol/server-github
claude mcp add --transport http linear --url https://mcp.linear.app/mcp --headers "Authorization: Bearer ${LINEAR_TOKEN}"
# secrets qua ${VAR}, không hardcode. Scope: project (.mcp.json team) | local (chỉ bạn) | user (~/.claude/)
# MCP protocol 2026-07-28 từ CLI ≥2.1.292. Validate server trước khi tin: claude plugin details/eval
```

## Vòng chuẩn (thuộc lòng)

```text
Explore -> /plan (duyệt) -> Implement từng bước (/diff sau mỗi bước) -> /verify + reviewer fresh
Rule miss 2 lần -> viết hook. Việc ồn -> đẩy subagent. Context bẩn -> /compact hoặc /clear.
```

## Tra cứu chi tiết từng lệnh (78 lệnh)

- Index: [01-huong-dan-su-dung/commands/README.md](01-huong-dan-su-dung/commands/README.md)
- Hay dùng: `/plan` → [commands/model-mode/plan/README.md](01-huong-dan-su-dung/commands/model-mode/plan/README.md) · `/compact` → [commands/session-context/compact/README.md](01-huong-dan-su-dung/commands/session-context/compact/README.md) · `/verify` → [commands/code-repo/verify/README.md](01-huong-dan-su-dung/commands/code-repo/verify/README.md) · `/mcp` → [commands/knowledge-system/mcp/README.md](01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) · `/doctor` → [commands/knowledge-system/doctor/README.md](01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md)
