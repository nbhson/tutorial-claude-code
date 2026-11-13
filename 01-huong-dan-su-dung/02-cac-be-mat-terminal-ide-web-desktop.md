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

Mục này nói về cách chọn "cửa vào" nào cho task trước mặt. Đọc xong bạn đừng mở terminal theo thói quen nữa — mà chọn theo độ dài và tính chất của task.

Cùng 1 agentic loop (bài 00), khác nhau ở **code chạy ở đâu** và **config nào được dùng**. Hãy hình dung một nhà hàng có nhiều cửa: vào cửa nào thì cũng cùng bếp, nhưng khác chỗ đặt xe và khác menu kèm theo.

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

> **Cách đọc bảng này:** cột "Task" là việc bạn định giao, đọc ngang sang phải để lấy đúng cửa vào và lệnh mở đầu — tra theo dòng khớp task, không cần học thuộc.

> Không có surface nào thắng mọi trường hợp: task nhỏ cần latency thấp → local; task dài cần máy chạy tiếp khi disconnect → cloud. Giống đi lại trong thành phố: xe máy nhanh cho quãng ngắn, máy bay mới đáng giá cho quãng dài.

> **Tóm gọn 1 câu:** Một bếp, nhiều cửa: task ngắn đi local cho nhanh, task dài giao cloud để khỏi còng lưng chờ.

---

## 2. Terminal CLI — flags toàn tập

Mục này là "bảng công tắc" của terminal: flag nào khóa cách chạy cả session. Đọc để biết có công tắc nào trước khi gõ `claude` trần trụi.

### Lệnh khởi động hay dùng

> 📄 **Code ví dụ:** [`examples/01-lenh-khoi-ong-hay-dung.sh`](examples/01-lenh-khoi-ong-hay-dung.sh)

### Bảng tra flags theo nhóm (check `claude --help` trên máy bạn làm chuẩn cuối)

Flag giống dặn dò tài xế trước khi lên xe: đi đường nào, mở nhanh đến đâu, ai được chạm vô-lăng. Dặn sai là cả chuyến đi lệch hướng.

> 📄 **Code ví dụ:** [`examples/02-bang-tra-flags-theo-nhom-check-claude-help.sh`](examples/02-bang-tra-flags-theo-nhom-check-claude-help.sh)

> **Auto mode** là permission mode mặc định cho session mới trên Pro/Max/Team từ 14/08/2026 (bài 10). `--dangerously-skip-permissions` = bypass — CHỈ dùng trong CI sandbox.

### 3 flow copy-paste

> 📄 **Code ví dụ:** [`examples/03-3-flow-copy-paste.sh`](examples/03-3-flow-copy-paste.sh)

### Phím tắt sống còn trong REPL

Bốn phím tắt này như nút khẩn cấp trên xe: biết chỗ để bấm thì đỡ hỏng cả ngày.

- **Shift+Tab**: xoay permission modes `default → acceptEdits → plan → auto → bypassPermissions`.
- **Double-Esc** (prompt rỗng): mở rewind menu — khôi phục code + conversation (bài 11).
- **Ctrl+X Ctrl+K ×2 trong 3s**: kill toàn bộ background subagents.
- **Ctrl+R**: search history. **Ctrl+C**: interrupt turn (Stop hook không chạy khi interrupt).

> **Tóm gọn 1 câu:** Flags quyết định session chạy thế nào ngay từ giây đầu — và Shift+Tab với Double-Esc là 2 phím nên nhớ thuộc.

---

## 3. IDE và Desktop

Mục này so 2 "mặt bàn rộng" khi terminal thấy chật: IDE cho code từng dòng, Desktop cho quản nhiều session cùng lúc. Đọc để biết mỗi bên thắng ở đâu và khi nào nên rời terminal.

### IDE (VS Code / JetBrains) — thắng terminal ở 4 điểm

Cứ nghĩ IDE extension như trợ lý ngồi ngay cạnh bàn làm việc, còn terminal như trợ lý ngồi phòng bên — gọi được nhưng phải đứng dậy đi qua.

Inline diffs trong editor (accept/reject từng hunk); `@`-mention file/selection chính xác; plan review UI; conversation history panel. Dùng chung config với CLI, `/ide` xem status.

```text
Bước 1: Cài extension "Claude Code" → reload.
Bước 2: Mở repo → sidebar Claude → "Connect".
Bước 3: Trong terminal VS Code gõ `claude` rồi `/ide` → "VS Code connected".
Bước 4: Bôi đen hàm → @ → "giải thích + đề xuất 2 edge cases thiếu test".
Bước 5: Giao task sửa nhỏ → review inline diff từng hunk → Accept.
```

### Desktop app — thắng ở 3 việc

Desktop app như phòng điều khiển nhiều màn hình: mỗi màn một session, bạn đứng giữa nhìn toàn cảnh.

1. **Multi-session side-by-side**: 2-3 sessions (feat A, B, review) kéo-thả diff qua lại.
2. **Review diff lớn trực quan**: hunk folding, syntax highlight, accept từng phần.
3. **Lên lịch routines + tính năng riêng**: tạo `/schedule` bằng UI; in-app browser (w28/2026); iOS Simulator pane (beta); background computer use macOS (w36/2026); `/resume` trong Desktop mở session CLI (w35/2026).

> **Tóm gọn 1 câu:** IDE là nơi nhận việc từng dòng code, Desktop là nơi chỉ huy nhiều session cùng lúc — terminal vẫn là gốc nối mọi thứ.

---

## 4. Web + setup cloud environment

Mục này nói về đường cloud: giao task cho một máy ảo của Anthropic chạy thay máy bạn. Đọc để biết luồng chuẩn và cách "lắp đồ" cho cái VM trống trơn đó.

> Web (`claude.ai/code`) còn ở dạng research preview: Pro/Max/Team + Enterprise seat đủ điều kiện; bắt buộc sign-in claude.ai (bài 10).

### Luồng chuẩn

Hãy hình dung giao việc cho một bạn ở chi nhánh khác: gửi repo, dặn rõ quyền hạn, xong nhận sản phẩm qua PR.

1. Connect GitHub repo → Claude clone vào isolated VM.
2. Submit task (mode: **Accept edits** = tự sửa + push branch; **Plan** = chờ duyệt). Cloud session KHÔNG có Manual/Bypass permissions.
3. Review PR, comment, Claude address; bật auto-fix PR nếu muốn.
4. Teleport: `/teleport` đưa local session lên cloud; ngược lại trên web copy session id rồi `claude --resume <id>`.

### Setup cloud environment (làm 1 lần, dùng mãi)

VM cloud là căn phòng trống mới thuê: không có Node, không có token, không biết project cần gì — setup environment là viết "danh sách đồ đạc" cho phòng đó. Làm một lần, mỗi lần VM boot lại là tự dọn sẵn.

> 📄 **Code ví dụ:** [`examples/04-setup-cloud-environment-lam-1-lan-dung-mai.sh`](examples/04-setup-cloud-environment-lam-1-lan-dung-mai.sh)

Trên web `claude.ai/code → Settings → Environments`:

```text
1. Network access: Off (thuần offline) / Trusted (npm, pypi, github... — khuyến nghị) / Custom allowlist.
2. Environment variables: DATABASE_URL, NPM_TOKEN... — KHÔNG commit secrets vào repo.
   MCP local/hook local KHÔNG theo lên cloud → cấu hình lại trong env này.
3. Setup script (chạy mỗi lần VM boot — quan trọng nhất):
```

> 📄 **Code ví dụ:** [`examples/05-setup-cloud-environment-lam-1-lan-dung-mai.sh`](examples/05-setup-cloud-environment-lam-1-lan-dung-mai.sh)

Verify: `claude --cloud "đọc README và tóm tắt project, không sửa gì"` → xem logs trên web, setup script phải pass; fail → sửa script → relaunch.

> **Tóm gọn 1 câu:** Web cloud là "gửi việc sang chi nhánh" — setup environment 1 lần như dán sẵn danh sách đồ đạc vào tường, VM nào boot lên cũng biết phải chuẩn bị gì.

---

## 5. Mobile, remote control, Slack

Mục này nói về 2 kiểu "điều khiển từ xa": Remote control (máy bạn vẫn chạy, bạn chỉ chat qua điện thoại) và Slack (Claude vào hẳn channel làm việc). Đọc để chọn cách rời khỏi bàn phím đúng nghĩa.

Remote control giống camera giám sát nhà: bạn đang ở ngoài nhưng vẫn thấy và bấm điều khiển mọi thứ trong nhà.

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

> **Cách đọc bảng này:** đây là bảng đối đầu Web cloud vs Remote control — mỗi dòng là một tiêu chí, đọc ngang để thấy bên nào thắng tiêu chí đó và chọn theo việc quan trọng nhất với bạn.

Slack: chạy Claude trong channel — cần subscription + admin enable tùy plan (bài 10).

> **Tóm gọn 1 câu:** Remote control = bạn đi xa nhưng máy vẫn nấu bếp; Web cloud = tháo cả bếp sang nơi khác — cần disconnect vẫn chạy thì chọn cloud.

---

## 6. Config nào theo surface nào + pitfalls

Mục này trả lời câu hỏi hay gây "owww sao cloud không thấy": config nào theo bạn lên cloud, config nào cứ kẹt lại máy local. Đọc trước khi chạy session cloud để khỏi đoán mò.

Cứ coi config như hành lý: có món là đồ xách tay (theo bạn mọi nơi), có món phải ký gửi (commit mới đi được), và có món chỉ dùng trong nước (local-only).

| Config | Local (CLI/IDE/Remote) | Cloud (Web) |
|---|---|---|
| `~/.claude/` (personal skills/agents) | Có | Không |
| `.claude/` repo (team) | Có | Có (phải commit) |
| `.mcp.json` project | Có | Có (nếu commit; secrets qua env) |
| MCP stdio local | Có | Không — cấu hình lại HTTP/SSE trong cloud env |
| Hooks `.claude/hooks/*.sh` | Có | Có nếu commit + trust (test lại trên cloud) |
| Env vars máy bạn | Có | Không — dùng cloud env vars |
| `--add-dir` dirs | Có | Không |

> **Cách đọc bảng này:** cột giữa là "đồ xách tay" (local có gì), cột phải là thứ bị giữ ở cửa — cell nào ghi "Không" là bạn phải chuẩn bị thay thế trước khi bay.

| Pitfall | Fix |
|---|---|
| Cloud báo "MCP server not found" dù local chạy tốt | MCP local stdio không theo lên cloud → cấu hình MCP http/sse trong cloud env (bài 08) |
| Cloud setup script fail → session chết | Test setup script trong docker sạch trước; thiếu lockfile/env là nguyên nhân hay gặp nhất |
| `--dangerously-skip-permissions` trên máy dev | Chỉ CI sandbox; máy dev dùng `auto` + rules hẹp (bài 10) |
| Remote mất khi terminal đóng | Task dài + cần gập máy → `--cloud`, không dùng remote |
| IDE báo "not connected" | Chạy `/ide` trong đúng session CLI của repo đó |
| Teleport mất context | Add-dir dirs không theo → gộp files vào repo trước khi teleport |

> **Cách đọc bảng này:** cột "Pitfall" là cảnh báo bạn thấy trên màn hình hoặc hiện tượng lạ; cột "Fix" là việc xử lý — tra đúng dòng bị dính, như tra mã lỗi đèn xe.

> **Tóm gọn 1 câu:** Cloud chỉ mang được thứ đã commit hoặc khai trong cloud env — mọi thứ nằm ở `~/.claude/` hay env máy bạn đều để lại sân bay.

---

## 7. Hiểu nhầm, bài tập, link

Mục này chốt bài bằng mấy tin sai thường nghe, vài bài tập tự luyện và đường sang bài liên quan. Đọc phần hiểu nhầm để tiết kiệm thời gian thử-sai.

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| Surface nào cũng như nhau | Khác nơi chạy + config: local dùng `~/.claude/` + MCP/hook máy bạn; cloud chỉ thấy repo + cloud env |
| Web cloud là "bản yếu" của CLI | Cloud thắng task dài (gập laptop vẫn chạy, VM cô lập); CLI thắng latency + MCP local |
| Remote Control = Web | Remote chạy trên máy bạn; Web chạy cloud VM disconnect vẫn chạy |
| IDE thay được CLI | IDE thắng nhìn diff; thua chạy Bash dài + multi-session |

> **Cách đọc bảng này:** cột trái là lời đồn, cột phải là lời giải — đọc theo từng dòng để phá misconception đúng chỗ mình đang tin.

### Bài tập

1. **Flags drill (10'):** chạy `claude --help`, đối chiếu mục 2; thử `--permission-mode plan`, `--add-dir`, `--output-format json`. Flag nào máy không có → check version/provider.
2. **Cloud env setup (20'):** làm đủ mục 4 (`gh auth login` → `/web-setup` → setup script → `claude --cloud` test). Chụp log pass; liệt kê 3 env vars phải đặt lại trên cloud.
3. **Surface matrix (15'):** 5 tasks thật tuần qua → điền surface hợp lý + vì sao; thử 1 task bằng surface khác thường dùng.

> **Tóm gọn 1 câu:** Bài học của bài: surface không phải sở thích mà là quyết định kỹ thuật — chọn theo task, kiểm tra config nào theo được.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: agentic loop mọi surface; **[01 — Cài đặt](./01-cai-dat-va-xac-thuc.md)**: `gh auth login`, `claude doctor`.
- **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)**: config nào commit để cloud thấy; **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/ide /mobile /teleport /web-setup /schedule`.
- **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: agent view + worktree parallel; **[10 — Permissions](./10-permissions-modes-availability.md)**: modes theo surface; **[11 — Worktrees](./11-git-worktrees-checkpoints.md)**; **[12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md)**: `claude -p` + routines.
