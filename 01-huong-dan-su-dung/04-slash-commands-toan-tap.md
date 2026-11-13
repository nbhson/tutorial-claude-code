# 04 — Slash commands toàn tập (built-in và skill đi kèm)

> **Bài này cho ai:** dev cần tra nhanh 1 lệnh `/...` của Claude Code — người mới muốn thuộc vài lệnh đầu, người đã dùng muốn biết lệnh cần tìm nằm ở nhóm nào.
> **Cần gì trước:** đã cài và đăng nhập ([01-cai-dat-va-xac-thuc.md](./01-cai-dat-va-xac-thuc.md)), mở được 1 session.
> **Đọc xong bạn làm được:** gõ `/` phân biệt built-in với skill; thuộc công thức 5 lệnh mỗi repo + 5 lệnh hằng ngày; tra lệnh theo 4 nhóm; biết lệnh vắng ở máy mình là do version hay do provider.
> **Thời gian:** ~30 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na là gì |
|---|---|
| Slash command | Nút preset: gõ `/tên` là Claude làm đúng 1 việc đã đóng gói — `/cost` xem tiền, `/clear` reset não |
| Built-in | Nút cứng của máy, luôn có sẵn — `/clear`, `/model`, `/compact`, `/doctor` |
| Bundled skill | Skill đi sẵn của Claude Code (`/code-review`, `/verify`, `/skill-doctor`) hoặc team tự viết ở `.claude/skills/` |
| Chi tiết lệnh | Mỗi lệnh 1 trang nhỏ: `commands/<nhóm>/<slug>/README.md` (nôm na → khi dùng → cách gọi → prompt + verify → lỗi hay gặp) |
| Version floor | Bản tối thiểu để có lệnh mới — `/cd` ≥2.1.169, `/effort` ≥2.1.205, `/goal` ≥2.1.139 (bảng mục 8) |

## Mục lục

1. [Nhóm 1 — Session & Context](#1-nhóm-1--session--context)
2. [Nhóm 2 — Model & Mode + Code](#2-nhóm-2--model--mode--code)
3. [Nhóm 3 — Tri thức & hệ thống](#3-nhóm-3--tri-thức--hệ-thống)
4. [Nhóm 4 — Auth/Remote/Settings](#4-nhóm-4--authremotesettings)
5. [Công thức 5 lệnh mỗi repo + 5 lệnh hằng ngày](#5-công-thức-5-lệnh-mỗi-repo--5-lệnh-hằng-ngày)
6. [Hiểu nhầm thường gặp](#6-hiểu-nhầm-thường-gặp)
7. [Lệnh vắng mặt: version / provider / đã gỡ](#7-lệnh-vắng-mặt-version--provider--đã-gỡ)
8. [Bài tập + link chéo](#8-bài-tập--link-chéo)

Gõ `/` trong session hiện dropdown lệnh khả dụng **ở máy bạn** (khác plan/provider/version hiện khác nhau). Cột "Chi tiết" trỏ file `commands/<nhóm>/<slug>/README.md` — link 404 ở máy bạn → xem mục 7. Hãy coi 4 bảng sắp tới như danh bạ điện thoại: không thuộc, chỉ cần biết tra theo nhóm nào.

---

## 1. Nhóm 1 — Session & Context

Mục này liệt kê các lệnh quản "trí nhớ làm việc" của session: xóa, nén, xem đang tốn bao nhiêu, quay lui và fork. Đọc khi bạn muốn dọn dẹp hoặc cứu vãn context.

| Lệnh | Mô tả | Chi tiết |
|---|---|---|
| `/clear` | Xóa context bắt đầu task mới (giữ CLAUDE.md) — thói quen #1 | [clear](./commands/session-context/clear/README.md) |
| `/compact` | Nén context khi ~70-80%, kèm focus giữ cái quan trọng | [compact](./commands/session-context/compact/README.md) |
| `/context` | Grid trực quan ai ngốn context | [context](./commands/session-context/context/README.md) |
| `/cost` | Token usage + billing session hiện tại | [cost](./commands/session-context/cost/README.md) |
| `/usage` | Breakdown limit theo skills/subagents/plugins/MCP | [usage](./commands/session-context/usage/README.md) |
| `/fork` | Fork session hiện tại thành session song song (thử what-if) | [fork](./commands/session-context/fork/README.md) |
| `/rewind` | Khôi phục code + conversation về checkpoint — resume được cả trước khi `/clear` (w26/2026) | [rewind](./commands/session-context/rewind/README.md) |
| `/resume` | Tiếp tục session cũ theo tên/id (`--continue` ngoài CLI) | [resume](./commands/session-context/resume/README.md) |
| `/rename` | Đặt tên session (để `--resume "name"` tìm thấy) | [rename](./commands/session-context/rename/README.md) |
| `/tasks` | Xem background work/subagents đang chạy hoặc đã xong | [tasks](./commands/session-context/tasks/README.md) |
| `/background` | Đẩy session thành agent nền, rảnh tay làm việc khác | [background](./commands/session-context/background/README.md) |
| `/recap` | Tóm tắt context khi quay lại session sau break | [recap](./commands/session-context/recap/README.md) |
| `/todos` | Xem todo list của task nhiều bước | [todos](./commands/session-context/todos/README.md) |
| `/branch` · `/copy` · `/export` · `/help` · `/restart` | Tách branch session; copy clipboard; export file; help; restart CLI giữ session | tương ứng trong `commands/session-context/` |

> **Cách đọc bảng này:** cột "Lệnh" là tên nút, cột "Mô tả" là nút đó làm gì trong 1 câu, cột "Chi tiết" trỏ trang tra sâu khi cần — tra theo nhu cầu, không cần học thuộc cả bảng.

> **Tóm gọn 1 câu:** Nhóm này là "bộ dọn dẹp + camera" của context: `/clear` khi đổi việc, `/compact` khi chạm ~75%, `/context /usage /cost` để biết ai ngốn.

```text
# Task mới sau khi fix CSS 45 phút:
/clear
Hãy đọc docs/payment-spec.md và triển khai POST /api/payments theo spec.

# Context ~75%, vẫn giữ mạch (đừng để tới 95%):
/compact tập trung vào auth refactor, giữ quyết định về error shape

# Cuối ngày:
/context && /usage && /cost
"đề xuất 3 thứ cắt giảm context mà không mất chất lượng"
```

---

## 2. Nhóm 2 — Model & Mode + Code

Mục này gom lệnh "vặn núm máy" (đổi model, độ kỹ suy luận, permission mode) và lệnh làm việc với code (review, verify, chia việc). Đọc khi muốn chọn đúng sức mạnh và quy trình cho từng việc.

| Lệnh | Mô tả | Chi tiết |
|---|---|---|
| `/model` | Đổi model giữa session (việc khó → Opus, việc lặp → model rẻ) | [model](./commands/model-mode/model/README.md) |
| `/effort` | Độ kỹ suy luận low/medium/high/xhigh/max/auto (≥2.1.205) | [effort](./commands/model-mode/effort/README.md) |
| `/fast` | Fast mode cho Opus (~2.5× nhanh, tính thêm tiền) — cần `/usage-credits` bật quota trước | [fast](./commands/model-mode/fast/README.md) |
| `/plan` | Plan mode read-only, duyệt plan trước khi code | [plan](./commands/model-mode/plan/README.md) |
| `/goal` | Đặt điều kiện hoàn thành, Claude tự loop tới khi đạt (≥2.1.139) | [goal](./commands/model-mode/goal/README.md) |
| `/permissions` | Quản lý allow/ask/deny rules | [permissions](./commands/model-mode/permissions/README.md) |
| `/init` | Sinh CLAUDE.md nháp cho repo mới | [init](./commands/code-repo/init/README.md) |
| `/diff` | Interactive diff viewer duyệt hunk (panel ≥2.1.260) | [diff](./commands/code-repo/diff/README.md) |
| `/review` | Review nhanh diff hiện tại (cùng agent, nông) | [review](./commands/code-repo/review/README.md) |
| `/code-review` | Review sâu PR/branch range — từ ≥2.1.215 chỉ chạy khi gọi tay; chạy bằng background subagent (w30/2026) | [code-review](./commands/code-repo/code-review/README.md) |
| `/ultrareview` | Fleet bug-hunting agents trên cloud sandbox (public preview, w17/2026); bản CI: `claude ultrareview` | [ultrareview](./commands/code-repo/ultrareview/README.md) |
| `/verify` | Build + chạy app thật để quan sát hành vi (≥2.1.145) | [verify](./commands/code-repo/verify/README.md) |
| `/batch` | Chia change lớn thành 5-30 worktree-isolated subagents, mỗi đứa 1 PR | [batch](./commands/code-repo/batch/README.md) |
| `/subtask` | Giao việc phụ cho subagent, báo về ngay trong session (≥2.1.212) | [subtask](./commands/code-repo/subtask/README.md) |
| `/btw` | Hỏi nhanh dùng full context nhưng không thêm vào history | [btw](./commands/code-repo/btw/README.md) |
| `/security-review` | Quét bảo mật on-demand trên branch hiện tại | [security-review](./commands/code-repo/security-review/README.md) |
| `/loop` · `/run` · `/radio` · `/design-sync` · `/fewer-permission-prompts` | Lặp theo schedule; chạy app thật; hỏi-đáp realtime; kéo design Figma; đề xuất allowlist | tương ứng trong `commands/code-repo/` |

> **Cách đọc bảng này:** nửa trên là lệnh "vặn núm" (model/effort/mode), nửa dưới là lệnh làm việc với code; cột "Mô tả" kèm version ≥... nghĩa là lệnh đó có "đỉnh cửa" bản tối thiểu — không thấy thì xem mục 7.

> **Tóm gọn 1 câu:** Nhóm 2 là bàn điều khiển: `/model` + `/effort` chọn sức mạnh, `/plan` chốt phương án trước, và review-verify là "2 mắt soi + chạy thật" trước khi kết thúc.

```text
# Task khó, model giỏi nhất + suy kỹ (≥2.1.205):
/model opus && /effort max
"Fix 2 tests đỏ trong apps/api, tìm root cause, không sửa test cho pass ảo."

# Việc nguy hiểm — duyệt plan trước khi cho sờ code:
/plan
"Thêm rate-limit cho POST /login: đề xuất giải pháp + files sẽ sửa, chờ tao duyệt."

# Vừa refactor xong — 2 mắt soi + chạy thật:
/review src/auth/login.ts → /code-review --focus security,tests → /verify
```

---

## 3. Nhóm 3 — Tri thức & hệ thống

Mục này là lệnh quản "kho tri thức và dây điện" của Claude Code: memory, rules, MCP, plugin, hooks, doctor. Đọc khi cần bảo trì hệ thống chứ không phải làm task code.

| Lệnh | Mô tả | Chi tiết |
|---|---|---|
| `/memory` | Sửa CLAUDE.md entries + bật/tắt auto-memory | [memory](./commands/knowledge-system/memory/README.md) |
| `/rules` | Quản lý `.claude/rules/` theo path | [rules](./commands/knowledge-system/rules/README.md) |
| `/agents` | Panel Running + Library quản lý subagents | [agents](./commands/knowledge-system/agents/README.md) |
| `/mcp` | Quản lý MCP connections/OAuth, reconnect/enable/disable (text-mode ≥2.1.205) | [mcp](./commands/knowledge-system/mcp/README.md) |
| `/plugin` | Plugin manager: Discover/Browse/Manage (inline list ≥2.1.260) | [plugin](./commands/knowledge-system/plugin/README.md) |
| `/hooks` | Xem hooks cho tool events | [hooks](./commands/knowledge-system/hooks/README.md) |
| `/doctor` | Chẩn đoán setup + trim CLAUDE.md (trim ≥2.1.206); alias `/checkup` | [doctor](./commands/knowledge-system/doctor/README.md) |
| `/debug` | Troubleshoot session/tools khi có lỗi lạ | [debug](./commands/knowledge-system/debug/README.md) |
| `/skill-doctor` | Báo skill nào ngốn context, skill nào chết (≥2.1.252) | [skill-doctor](./commands/knowledge-system/skill-doctor/README.md) |
| `/bug` | Report bug cho Anthropic | [bug](./commands/knowledge-system/bug/README.md) |
| `/claude-api` | Hướng dẫn gọi Claude API / migrate SDK | [claude-api](./commands/knowledge-system/claude-api/README.md) |
| `/pr-comments` | Liệt kê PR comments để address từng cái (đã gỡ v2.1.91 — xem mục 7) | [pr-comments](./commands/code-repo/pr-comments/README.md) |
| `/simplify` · `/insights` · `/stats` · `/mcp-serve` · `/plugin-validate` · `/run-skill-generator` | Rút gọn code; thói quen coding; thống kê; biến Claude thành MCP server; audit plugin; ghi recipe thành skill | tương ứng trong `commands/` |

> **Cách đọc bảng này:** cột "Lệnh" là công cụ bảo trì, cột "Mô tả" là việc nó làm; các lệnh nằm dòng gộp cuối (dấu `·`) ít dùng hơn — để đó, cần thì tra.

> **Tóm gọn 1 câu:** Nhóm 3 là "bộ quản nhà": memory/rules nuôi tri thức, `/mcp /plugin /hooks` nối dây điện, `/doctor /debug /skill-doctor` khám bệnh khi hệ thống khó ở.

---

## 4. Nhóm 4 — Auth/Remote/Settings

Mục này liệt kê lệnh "hồ sơ cá nhân": đăng nhập, đổi thư mục, nối IDE, điều khiển từ xa và tinh chỉnh giao diện. Đọc khi cần cấu hình môi trường làm việc của chính bạn.

| Lệnh | Mô tả | Chi tiết |
|---|---|---|
| `/login` · `/logout` | Đăng nhập/đăng xuất, đổi account | [login](./commands/auth-settings/login/README.md) |
| `/status` | Version/model/account hiện tại | [status](./commands/auth-settings/status/README.md) |
| `/config` | Mở settings — hỗ trợ set trực tiếp `/config key=value` (w25/2026) | [config](./commands/auth-settings/config/README.md) |
| `/cd` | Đổi working dir giữ prompt cache (≥2.1.169) | [cd](./commands/auth-settings/cd/README.md) |
| `/add-dir` | Thêm thư mục ngoài vào context (cross-repo) | [add-dir](./commands/auth-settings/add-dir/README.md) |
| `/ide` | Kết nối IDE (VS Code/JetBrains) | [ide](./commands/auth-settings/ide/README.md) |
| `/teleport` | Chuyển session sang máy/IDE/cloud khác giữ nguyên context | [teleport](./commands/auth-settings/teleport/README.md) |
| `/mobile` | Pair điều khiển session từ mobile (QR) | [mobile](./commands/auth-settings/mobile/README.md) |
| `/remote-env` | Quản lý env vars cho remote/cloud session | [remote-env](./commands/auth-settings/remote-env/README.md) |
| `/theme` | Đổi theme (custom themes từ w17/2026) | [theme](./commands/auth-settings/theme/README.md) |
| `/voice` | Nói thay vì gõ (giữ Space để nói) | [voice](./commands/auth-settings/voice/README.md) |
| `/sandbox` | Quản lý sandbox côisolated lệnh nguy hiểm | [sandbox](./commands/auth-settings/sandbox/README.md) |
| `/exit` · `/keybindings` · `/vim` · `/statusline` · `/terminal-setup` · `/setup-bedrock` · `/setup-vertex` | Thoát; phím tắt; vim mode; statusline; terminal setup; wizard Bedrock/Vertex | tương ứng trong `commands/auth-settings/` |

> **Cách đọc bảng này:** mỗi dòng là một "cài đặt cá nhân"; lệnh dòng gộp cuối là nhóm ít đụng đến — setup 1 lần rồi quên. Đổi account thì tìm `/login /logout`, đổi chỗ làm thì tìm `/cd /add-dir`.

> **Tóm gọn 1 câu:** Nhóm 4 là hồ sơ cá nhân của bạn trong session — login, thư mục, IDE, điều khiển từ xa: setup xong phần lớn là "đặt-và-quên".

---

## 5. Công thức 5 lệnh mỗi repo + 5 lệnh hằng ngày

Mục này chưng cất cả bài thành 10 lệnh cần thuộc. Đọc mục này trước, phần còn lại của bài tra khi cần — thuộc 10 lệnh là dùng được ~90% Claude Code.

### 5 lệnh chạy 1 lần mỗi repo

Khối lệnh này như giấy khai sinh của repo: điền một lần, sau đó mọi session hưởng lợi.

```text
/init → /memory → /mcp → /agents → /permissions
```

1. `/init` — sinh CLAUDE.md nháp, đọc rồi cắt 50% (bài 03).
2. `/memory` — xem entries, bật/tắt auto-memory, xóa learnings sai.
3. `/mcp` — thêm GitHub (+ DB nếu có); test "liệt kê 5 PRs mở gần nhất" (bài 08).
4. `/agents` — tạo 2 subagents chuẩn: prompt "tạo 2 subagents: explorer (read-only) và tester (chạy pnpm test)".
5. `/permissions` — đặt allow/ask/deny, test 1 task nhỏ end-to-end (bài 10).

### 5 lệnh hằng ngày

Chuỗi 5 lệnh này như thói quen sáng-tối trong ngày làm việc: mở việc bằng `/clear`, đóng việc bằng `/cost`.

`/clear` (đầu task) → `/model` (đổi loại việc: khó lên Opus, lặp xuống model rẻ) → `/review` (sau khi code) → `/compact` (khi context chạm ~75%) → `/cost` (xem tiền).

**Cross-session (w32-33/2026):** từ 1 session có thể **`@` mention session khác** để hỏi/giao tin, và nhận **cross-session messaging** từ session khác đang chạy (macOS/Linux) — hữu ích khi chạy nhiều session song song mà không muốn merge context. Giống 2 đồng nghiệp ngồi phòng riêng nhưng vẫn nhắn tin cho nhau, khỏi phải dồn hết giấy tờ vào một bàn.

> **Tóm gọn 1 câu:** 5 lệnh setup mỗi repo + 5 lệnh mỗi ngày — thuộc 10 cái này là đi được 90% đường, phần còn lại tra khi cần.

---

## 6. Hiểu nhầm thường gặp

Mục này phá mấy tin đồn về slash command hay khiến người dùng tự trách hoặc bỏ cuộc. Đọc để khỏi chẩn đoán sai khi lệnh "hành xử lạ".

| Hiểu nhầm | Sự thật |
|---|---|
| 78 lệnh phải thuộc hết | Thuộc 10 lệnh ở mục 5 là đủ 90%; còn lại tra `commands/` index khi cần |
| `/review` khen là code xong | `/review` là cùng agent tự chấm (mù cùng chỗ). Mắt mới → `/code-review`; chắc chắn → `/verify` chạy thật |
| `/clear` xóa hết kể cả CLAUDE.md | `/clear` chỉ xóa conversation, giữ CLAUDE.md + memory. Muốn khôi phục: `/rewind` resume được cả trước khi `/clear` |
| Không thấy lệnh = bug | 90% là version floor (mục 7) hoặc provider cắt feature (bài 10) |
| `/verify` + `/code-review` tự chạy sau mỗi task | Từ ≥2.1.215 chỉ chạy khi gọi tay — đừng chờ tự trigger |
| Skill `user-invocable: false` là hỏng | Là cố ý: chỉ Claude tự gọi khi ngữ cảnh khớp (bài 05) |

> **Cách đọc bảng này:** cột trái là câu bạn từng nói ("sao nó...?"); đọc sang cột phải để biết chuyện gì thật sự xảy ra — dòng nào đang tin thì thử ngay dòng đó.

> **Tóm gọn 1 câu:** Lệnh vắng không phải bug mà là version floor; `/review` khen chưa chắc code đúng — cần `/code-review` và `/verify` chốt hạ.

---

## 7. Lệnh vắng mặt: version / provider / đã gỡ

Mục này là "hồ sơ truy tìm lệnh mất tích": 3 lý do khiến một lệnh không hiện ở máy bạn, xếp theo tần suất. Đọc khi dropdown không có lệnh bạn cần.

**Lý do 1 — version floor** (gom từ các bảng trên):

| Lệnh | Bản tối thiểu |
|---|---|
| `/goal` ≥2.1.139 · `/verify` ≥2.1.145 · `/cd` ≥2.1.169 | |
| `/effort` + `/mcp` text-mode ≥2.1.205 · `/doctor` trim ≥2.1.206 | |
| `/subtask` ≥2.1.212 · `/verify`+`/code-review` gọi tay ≥2.1.215 | |
| `/skill-doctor` ≥2.1.252 · `/diff` panel ≥2.1.260 (terminal ≥110 cột + git repo) | |

> **Cách đọc bảng này:** mỗi dòng gộp nhiều lệnh với "đỉnh cửa" version; đối chiếu `claude --version` — bản thấp hơn con số nào là lệnh ở dòng đó chưa hiện.

**Lý do 2 — provider cắt:** `/design-sync`, `/radio` và vài bundled skills vắng trên Bedrock/Vertex/GCP Agent Platform; Bedrock/Vertex còn mất fast mode, web search (bài 10).

**Lý do 3 — đã gỡ:** `/ultraplan` (CLI) gỡ w32/2026 — trong CLI dùng plan mode `/plan`; tính năng Ultraplan vẫn có trên Claude Code web/cloud (w15/2026).

> 📄 **Code ví dụ:** [`examples/01-7-lenh-vang-mat-version-provider-a-go.sh`](examples/01-7-lenh-vang-mat-version-provider-a-go.sh)

> **Tóm gọn 1 câu:** Lệnh mất tích lần lượt xét 3 "hồ sơ": bản chưa đủ, provider cắt, hoặc đã bị gỡ — kiểm tra theo đúng thứ tự đó trước khi report bug.

---

## 8. Bài tập + link chéo

Mục này cho bạn 4 bài tập luyện tay với chính dropdown của máy mình, rồi đường sang các bài liên quan. Làm xong 10 phút đầu là bạn thuộc sẵn danh bạ của riêng máy bạn.

1. **Dropdown drill (10'):** gõ `/`, chụp list lệnh ở máy bạn; đối chiếu 4 bảng — lệnh nào vắng → check floor + provider, ghi lý do.
2. **Công thức 5 lệnh (15'):** repo thật chạy đủ `/init → /memory → /mcp → /agents → /permissions` + 1 task end-to-end; lưu `/cost` + `/export`.
3. **Review 3 tầng (15'):** 1 diff thật chạy `/review` → `/code-review --focus security,tests` → `/verify`; so sánh tầng nào bắt được gì.
4. **Context drill (10'):** task dài tới ~70% context → `/context` → `/compact [focus]` → hỏi lại quyết định quan trọng còn nhớ không.

Link chéo: **[00 — Tổng quan](./00-tong-quan-claude-code.md)** (token economics, vì sao `/compact` khi 70-80%) · **[01 — Cài đặt](./01-cai-dat-va-xac-thuc.md)** (`claude doctor` vs `/doctor`, version floor) · **[02 — Bề mặt](./02-cac-be-mat-terminal-ide-web-desktop.md)** (`/ide /mobile /teleport /web-setup` theo surface) · **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)** (`/init /memory /rules`, `@AGENTS.md`) · **[05 — Skills](./05-skills-custom-commands.md)** (`user-invocable`, `$ARGUMENTS`) · **[06 — Subagents](./06-subagents-agent-teams-parallel.md)** (`/agents /tasks /batch /subtask`) · **[10 — Permissions](./10-permissions-modes-availability.md)** (`/permissions` + availability) · tra cứu chi tiết từng lệnh ở `commands/<nhóm>/<slug>/README.md`.
