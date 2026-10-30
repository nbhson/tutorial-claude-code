# 02 — Các bề mặt sử dụng: terminal, IDE, desktop, web, mobile

> **Bài này cho ai:** dev đã cài Claude Code nhưng chưa biết nên mở bằng cách nào cho từng loại task.
> **Cần gì trước:** đã cài và đăng nhập (bài 01), dùng terminal cơ bản được.
> **Đọc xong bạn làm được:** chọn đúng surface cho task trước mặt; gọi rành CLI flags hay dùng; setup cloud environment 1 lần dùng mãi; chỉ ra config nào đi theo máy, config nào phải cấu hình lại trên cloud.
> **Thời gian:** ~25 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Surface | Cửa vào cùng 1 agentic loop, khác chỗ code chạy | Typo → terminal; refactor 1 giờ → `claude --cloud` |
| CLI flag | Công tắc lúc khởi động, khóa cách chạy cả session | `--permission-mode plan`, `--add-dir ../shared` |
| IDE extension | Inline diff + @-mention ngay trong editor | Bôi đen hàm → `@` → giải thích |
| Desktop app | Nhiều session cạnh nhau + review trực quan | 3 session feat A/B/review side-by-side |
| Web (`claude.ai/code`) | Code chạy trên VM của Anthropic | Task 2 giờ, gập laptop vẫn chạy |
| Cloud environment | Setup script + env vars cho cloud VM | `pnpm install --frozen-lockfile && pnpm build` |
| Remote control | Chat từ điện thoại, code vẫn chạy máy bạn | `claude remote-control`, xem session qua claude.ai |

## Mục lục

1. [Nguyên tắc chọn surface](#1-nguyên-tắc-chọn-surface)
2. [Terminal CLI — flags toàn tập](#2-terminal-cli--flags-toàn-tập)
3. [IDE và Desktop](#3-ide-và-desktop)
4. [Web + setup cloud environment](#4-web--setup-cloud-environment)
5. [Mobile, remote control, Slack](#5-mobile-remote-control-slack)
6. [Config nào theo surface nào + pitfalls](#6-config-nào-theo-surface-nào--pitfalls)
7. [Hiểu nhầm, bài tập, link](#7-hiểu-nhầm-bài-tập-link)

---

## 1. Nguyên tắc chọn surface

Cùng 1 agentic loop (bài 00), khác nhau ở **code chạy ở đâu** và **config nào được dùng**:

```text
Terminal / IDE / Desktop-local / Remote control → chạy TRÊN MÁY BẠN, dùng ~/.claude/ + .claude/
Web (claude.ai/code) / Desktop-cloud            → chạy TRÊN CLOUD VM, chỉ repo + cloud env vars
```

Chọn theo task:

| Task | Chọn | Lệnh mở đầu |
|---|---|---|
| Fix typo, task < 10 phút | Terminal | `claude` |
| Code hàng ngày, cần inline diff | IDE | `claude` + extension |
| Review diff lớn, nhiều session | Desktop | 1 window/session |
| Task dài 30'+, muốn gập laptop | Web cloud | `claude --cloud "..."` |
| Ra ngoài vẫn approve/deny | Mobile/Remote | `/mobile` pair trước |
| Việc lặp theo lịch / team automation | Routines + CI | `/schedule`, `claude -p` (bài 12) |

> Không có surface nào thắng mọi trường hợp: task nhỏ cần latency thấp → local; task dài cần máy chạy tiếp khi disconnect → cloud.

---

## 2. Terminal CLI — flags toàn tập

### Lệnh khởi động hay dùng

```bash
claude                     # session interactive
claude "fix failing tests" # 1-shot prompt
claude -p "summarize diff" # print mode, non-interactive (CI/scripts, bài 12)
claude --continue          # tiếp tục session gần nhất
claude --resume <id|name>  # resume theo id/name (không truyền id → mở picker)
claude --agent explore     # chạy cả session dưới 1 subagent persona (bài 06)
claude --add-dir ../shared # truy cập thêm thư mục ngoài CWD
claude --cloud             # ném session lên cloud (cần GitHub + /web-setup)
```

### Bảng tra flags theo nhóm (check `claude --help` trên máy bạn làm chuẩn cuối)

```bash
# Session & resume:
claude --fork <id>          # fork session thử what-if, giữ mạch chính

# Non-interactive (CI/scripts):
claude -p "review diff, in findings JSON" \
  --output-format json \    # text | json | stream-json
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"
claude --init-only          # chỉ chạy Setup hooks, không mở session (CI warmup)

# Model & effort:
claude --model opus         # opus | sonnet | haiku (đổi giữa session: /model)
claude --effort high        # low | medium | high | xhigh | max | auto (≥2.1.205)
claude --agents '{"reviewer":{"prompt":"...","tools":["Read","Grep"]}}'  # agent inline JSON

# Dirs & sandbox:
claude --add-dir ../shared --add-dir /tmp/contracts
claude --sandbox            # bật OS sandbox (giới hạn FS/network)
claude --safe-mode          # chế độ an toàn thêm (w24/2026)
claude --restricted         # chạy giới hạn tối đa (w35/2026)

# Permissions:
claude --permission-mode plan   # default | acceptEdits | plan | auto | dontAsk | bypassPermissions
claude --disallowedTools "Bash, Write"

# Cloud:
claude --cloud "migrate table X, mở PR" [--model opus]
```

> **Auto mode** là permission mode mặc định cho session mới trên Pro/Max/Team từ 14/08/2026 (bài 10). `--dangerously-skip-permissions` = bypass — CHỈ dùng trong CI sandbox.

### 3 flow copy-paste

```bash
# 1 — Đọc hiểu, không cho sửa (an toàn tuyệt đối):
claude --permission-mode plan "đọc apps/api/src/routes/login.ts, giải thích flow auth, không sửa gì"

# 2 — Shared lib ngoài repo (monorepo tách folder):
claude --add-dir ../shared-contracts
# > "Đọc types trong ../shared-contracts, đối chiếu apps/api usage, báo mismatch."
# Load CLAUDE.md của add-dir: export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 (bài 01)

# 3 — CI one-shot review:
claude -p "review git diff main...HEAD, in tối đa 10 findings" \
  --output-format text --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash"
```

### Phím tắt sống còn trong REPL

- **Shift+Tab**: xoay permission modes `default → acceptEdits → plan → auto → bypassPermissions`.
- **Double-Esc** (prompt rỗng): mở rewind menu — khôi phục code + conversation (bài 11).
- **Ctrl+X Ctrl+K ×2 trong 3s**: kill toàn bộ background subagents.
- **Ctrl+R**: search history. **Ctrl+C**: interrupt turn (Stop hook không chạy khi interrupt).

---

## 3. IDE và Desktop

### IDE (VS Code / JetBrains) — thắng terminal ở 4 điểm

Inline diffs trong editor (accept/reject từng hunk); `@`-mention file/selection chính xác; plan review UI; conversation history panel. Dùng chung config với CLI, `/ide` xem status.

```text
Bước 1: Cài extension "Claude Code" → reload.
Bước 2: Mở repo → sidebar Claude → "Connect".
Bước 3: Trong terminal VS Code gõ `claude` rồi `/ide` → "VS Code connected".
Bước 4: Bôi đen hàm → @ → "giải thích + đề xuất 2 edge cases thiếu test".
Bước 5: Giao task sửa nhỏ → review inline diff từng hunk → Accept.
```

### Desktop app — thắng ở 3 việc

1. **Multi-session side-by-side**: 2-3 sessions (feat A, B, review) kéo-thả diff qua lại.
2. **Review diff lớn trực quan**: hunk folding, syntax highlight, accept từng phần.
3. **Lên lịch routines + tính năng riêng**: tạo `/schedule` bằng UI; in-app browser (w28/2026); iOS Simulator pane (beta); background computer use macOS (w36/2026); `/resume` trong Desktop mở session CLI (w35/2026).

---

## 4. Web + setup cloud environment

> Web (`claude.ai/code`) còn ở dạng research preview: Pro/Max/Team + Enterprise seat đủ điều kiện; bắt buộc sign-in claude.ai (bài 10).

### Luồng chuẩn

1. Connect GitHub repo → Claude clone vào isolated VM.
2. Submit task (mode: **Accept edits** = tự sửa + push branch; **Plan** = chờ duyệt). Cloud session KHÔNG có Manual/Bypass permissions.
3. Review PR, comment, Claude address; bật auto-fix PR nếu muốn.
4. Teleport: `/teleport` đưa local session lên cloud; ngược lại trên web copy session id rồi `claude --resume <id>`.

### Setup cloud environment (làm 1 lần, dùng mãi)

```bash
gh auth login && gh auth status   # phải thấy Logged in
# Trong session Claude CLI:
/web-setup
# → sync gh token, tạo cloud environment (Trusted network, chưa có setup script).
```

Trên web `claude.ai/code → Settings → Environments`:

```text
1. Network access: Off (thuần offline) / Trusted (npm, pypi, github... — khuyến nghị) / Custom allowlist.
2. Environment variables: DATABASE_URL, NPM_TOKEN... — KHÔNG commit secrets vào repo.
   MCP local/hook local KHÔNG theo lên cloud → cấu hình lại trong env này.
3. Setup script (chạy mỗi lần VM boot — quan trọng nhất):
```

```bash
#!/bin/bash
# Node monorepo:
set -eux
corepack enable
pnpm install --frozen-lockfile
pnpm build
echo "CLOUD_ENV_READY=1"
```

Verify: `claude --cloud "đọc README và tóm tắt project, không sửa gì"` → xem logs trên web, setup script phải pass; fail → sửa script → relaunch.

---

## 5. Mobile, remote control, Slack

```text
# Pair mobile (trong CLI session): /mobile → QR → quét bằng Claude mobile app → sessions sync.
# Remote control flow:
# 1. Máy dev: claude remote-control (session để terminal mở, hiện device card).
# 2. Điện thoại: claude.ai → thấy session máy dev → chat tiếp, approve/deny.
# 3. Code vẫn chạy trên máy dev (dùng local config, MCP local OK).
```

| | Web cloud | Remote control |
|---|---|---|
| Chạy trên | Cloud VM | Máy bạn |
| Disconnect vẫn chạy | Có | Không (terminal đóng là mất) |
| MCP/hook local | Không (cấu hình lại) | Có |

Slack: chạy Claude trong channel — cần subscription + admin enable tùy plan (bài 10).

---

## 6. Config nào theo surface nào + pitfalls

| Config | Local (CLI/IDE/Remote) | Cloud (Web) |
|---|---|---|
| `~/.claude/` (personal skills/agents) | Có | Không |
| `.claude/` repo (team) | Có | Có (phải commit) |
| `.mcp.json` project | Có | Có (nếu commit; secrets qua env) |
| MCP stdio local | Có | Không — cấu hình lại HTTP/SSE trong cloud env |
| Hooks `.claude/hooks/*.sh` | Có | Có nếu commit + trust (test lại trên cloud) |
| Env vars máy bạn | Có | Không — dùng cloud env vars |
| `--add-dir` dirs | Có | Không |

| Pitfall | Fix |
|---|---|
| Cloud báo "MCP server not found" dù local chạy tốt | MCP local stdio không theo lên cloud → cấu hình MCP http/sse trong cloud env (bài 08) |
| Cloud setup script fail → session chết | Test setup script trong docker sạch trước; thiếu lockfile/env là nguyên nhân hay gặp nhất |
| `--dangerously-skip-permissions` trên máy dev | Chỉ CI sandbox; máy dev dùng `auto` + rules hẹp (bài 10) |
| Remote mất khi terminal đóng | Task dài + cần gập máy → `--cloud`, không dùng remote |
| IDE báo "not connected" | Chạy `/ide` trong đúng session CLI của repo đó |
| Teleport mất context | Add-dir dirs không theo → gộp files vào repo trước khi teleport |

---

## 7. Hiểu nhầm, bài tập, link

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| Surface nào cũng như nhau | Khác nơi chạy + config: local dùng `~/.claude/` + MCP/hook máy bạn; cloud chỉ thấy repo + cloud env |
| Web cloud là "bản yếu" của CLI | Cloud thắng task dài (gập laptop vẫn chạy, VM cô lập); CLI thắng latency + MCP local |
| Remote Control = Web | Remote chạy trên máy bạn; Web chạy cloud VM disconnect vẫn chạy |
| IDE thay được CLI | IDE thắng nhìn diff; thua chạy Bash dài + multi-session |

### Bài tập

1. **Flags drill (10'):** chạy `claude --help`, đối chiếu mục 2; thử `--permission-mode plan`, `--add-dir`, `--output-format json`. Flag nào máy không có → check version/provider.
2. **Cloud env setup (20'):** làm đủ mục 4 (`gh auth login` → `/web-setup` → setup script → `claude --cloud` test). Chụp log pass; liệt kê 3 env vars phải đặt lại trên cloud.
3. **Surface matrix (15'):** 5 tasks thật tuần qua → điền surface hợp lý + vì sao; thử 1 task bằng surface khác thường dùng.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: agentic loop mọi surface; **[01 — Cài đặt](./01-cai-dat-va-xac-thuc.md)**: `gh auth login`, `claude doctor`.
- **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)**: config nào commit để cloud thấy; **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/ide /mobile /teleport /web-setup /schedule`.
- **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: agent view + worktree parallel; **[10 — Permissions](./10-permissions-modes-availability.md)**: modes theo surface; **[11 — Worktrees](./11-git-worktrees-checkpoints.md)**; **[12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md)**: `claude -p` + routines.
