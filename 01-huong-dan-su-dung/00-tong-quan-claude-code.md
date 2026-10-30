# 00 — Tổng quan Claude Code: Tư duy agent, không phải chatbot

> **Bài này cho ai:** dev mới muốn bức tranh toàn cảnh Claude Code trước khi đi sâu từng cấu hình.
> **Cần gì trước:** đã cài và đăng nhập (làm theo [01-cai-dat-va-xac-thuc.md](./01-cai-dat-va-xac-thuc.md)).
> **Đọc xong bạn làm được:** kể lại vòng lặp agent + 4 nhóm tool; viết prompt giao việc có phạm vi + lệnh verify; giải thích vì sao CLAUDE.md phình làm tốn token; chạy xong session đầu `/init` → 1 task nhỏ → `/cost`.
> **Thời gian:** ~20 phút đọc + ~30 phút walkthrough mục 7

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Claude Code | Thợ code tới tận nhà, tự đọc/sửa/chạy giúp bạn | Gõ `claude` trong repo, giao `fix 2 tests đỏ trong apps/api` |
| Vòng lặp agent | Làm → xem kết quả → sửa tiếp, tới khi xong | `Read(login.ts)` → `Edit` → `Bash(pnpm test)` |
| Tool (Read/Edit/Bash...) | Bộ đồ nghề của Claude | `Read` = đọc file, `Edit` = sửa đúng chuỗi, `Bash` = chạy test |
| Harness | CLI binary trên máy bạn: thực thi tools, check quyền, chạy hooks | Chặn `rm -rf` dù model muốn |
| Bề mặt (surface) | Cửa vào cùng 1 loop: terminal/IDE/desktop/web | Typo 2 phút → CLI; refactor 1 giờ → Web cloud |
| Token/context | Tiền điện tính theo chữ, nạp lại mỗi turn | CLAUDE.md 150 dòng ≈ 2.500 tokens × 10 turns = 25k tokens |
| CLAUDE.md | Tờ dặn dò đọc đầu mỗi session | `ALWAYS chạy pnpm --filter @acme/api test sau khi sửa` |
| Skill | Công thức load khi cần, startup chỉ ~100 tokens | `/deploy` checklist 20 bước, chỉ load khi gõ `/deploy` |
| Subagent | Đệ tử chạy việc ồn, chỉ báo kết quả gọn | Explorer đọc 50 file, trả về 10 dòng tóm tắt |
| Hook | Luật tự động chạy theo lifecycle event | Sau mỗi Edit tự chạy `eslint` |
| MCP | Phích cắm ra thiết bị ngoài | `mcp__github__create_pr`, `mcp__postgres__query` |

## Mục lục

1. [Claude Code là gì?](#1-claude-code-là-gì)
2. [Vòng lặp agent — giải phẫu và khi nào hỏng](#2-vòng-lặp-agent--giải-phẫu-và-khi-nào-hỏng)
3. [Các nhóm tool toàn tập](#3-các-nhóm-tool-toàn-tập)
4. [Vì sao CLAUDE.md phình làm bạn tốn tiền?](#4-vì-sao-claudemd-phình-làm-bạn-tốn-tiền)
5. [Claude Code làm được gì (thực tế)](#5-claude-code-làm-được-gì-thực-tế)
6. [Các bề mặt sử dụng — chọn cái nào?](#6-các-bề-mặt-sử-dụng--chọn-cái-nào)
7. [Bản đồ mở rộng + tính năng 2026 cần biết](#7-bản-đồ-mở-rộng--tính-năng-2026-cần-biết)
8. [Đi từng bước cho người mới](#8-đi-từng-bước-cho-người-mới)
9. [Hiểu nhầm và bẫy thường gặp](#9-hiểu-nhầm-và-bẫy-thường-gặp)
10. [Bài tập + đi tiếp tới đâu?](#10-bài-tập--đi-tiếp-tới-đâu)

---

## 1. Claude Code là gì?

**Claude Code** là coding agent của Anthropic: CLI (và IDE/Desktop/Web app) chạy model Claude với quyền truy cập trực tiếp filesystem + terminal. Khác chatbot ở chỗ:

| Chatbot (claude.ai chat) | Claude Code (vòng lặp agent) |
|---|---|
| Bạn paste code vào, nhận text | Claude tự đọc file, sửa file, chạy lệnh, lặp tới khi xong |
| 1 lượt request → 1 response | 1 task → N vòng: reasoning → tool_use → observation |
| Có tools: Read, Edit, Write, Glob, Grep, Bash, WebSearch, Task (subagent), MCP tools | Bạn là người làm việc nặng (copy/paste/chạy) — agent làm việc nặng, bạn review + quyết định |

Vòng lặp agent cốt lõi (giống nhau trên mọi bề mặt — terminal, IDE, desktop, web):

```text
Bạn prompt → Claude reasoning → gọi tools (đọc/sửa/chạy) → đọc kết quả
→ reasoning tiếp → ... → đạt mục tiêu thì dừng, báo cáo + diff
```

Điểm mấu chốt: **harness không phải model**. Model chỉ sinh text + tool calls; CLI binary trên máy bạn mới là thứ chạm disk, kiểm tra quyền, chạy hooks, nhét kết quả vào context. Nhờ vậy permission/hook enforce được kể cả khi model muốn lách, và cùng 1 model hành xử nhất quán trên mọi bề mặt.

Vì sao "agent" khác "autocomplete"? Copilot đoán **dòng tiếp theo**; Claude Code giải **task đóng** ("fix failing tests", "thêm OAuth"): tự khám phá repo → lập kế hoạch nhiều bước → thực thi bằng tools → tự kiểm chứng. Tư duy đúng: giao việc như giao cho junior dev giỏi — mục tiêu + tiêu chí xong + ranh giới, đừng prompt như hỏi Google:

```text
# TỆ — hỏi như chatbot:
"lỗi TypeError: Cannot read properties of undefined nghĩa là gì?"

# TỐT — giao task như agent:
"Trong apps/api, endpoint POST /orders crash khi payload thiếu customerId.
Tìm root cause, fix, thêm regression test, chạy pnpm --filter @acme/api test.
Đừng sửa gì ngoài scope này."
```

---

## 2. Vòng lặp agent — giải phẫu và khi nào hỏng

Mỗi vòng lặp gồm 4 pha: **REASONING** (model nghĩ cần đọc file nào, lệnh gì xác nhận) → **TOOL_USE** (gọi 1..n tools song song) → **OBSERVATION** (harness trả kết quả: file content / stdout / exit code) → **ĐIỀU KIỆN DỪNG** (chưa xong → quay lại; xong → báo cáo).

Trace 1 task thật — *"Thêm rate-limit cho POST /login"*:

```text
Turn 1: Glob(apps/api/**/login*) + Grep("POST.*login")     → ra 3 files
Turn 2: Read(route.ts) + Read(middleware.ts)
Turn 3: Read(package.json) + Grep("rate-limit")            → dùng express-rate-limit
Turn 4: (plan mode) trình plan cho bạn duyệt
Turn 5: Edit(route.ts) + Edit(route.test.ts)
Turn 6: Bash(pnpm test) → FAIL (import sai) → đọc lỗi → Edit fix
Turn 7: Bash(pnpm test) → PASS → báo cáo diff + lệnh đã chạy
```

Bạn chỉ gõ 1 prompt + 1 lần duyệt; 7 turns, ~5 tool calls song song mỗi turn.

Khi nào vòng lặp thất bại (3 nguyên nhân gốc):

| Nguyên nhân | Dấu hiệu | Thuộc về |
|---|---|---|
| Thiếu context (không tìm ra file đúng) | Đọc lung tung, sửa sai chỗ | Fix bằng CLAUDE.md + skills (bài 03, 05) |
| Thiếu verification (tự tin sai) | Báo "xong" nhưng test fail | Fix bằng hooks + reviewer subagent (bài 07, 06) |
| Loop quá dài (context đầy rác) | Càng sửa càng nát sau turn 15+ | Fix bằng `/clear`, `/compact`, subagent cô lập (bài 04, 06) |

> Quy tắc vàng: task >15 turns không tiến triển → dừng, `/clear`, chia nhỏ, giao lại. Sai 2 lần liên tiếp → `/rewind` + re-prompt rẻ hơn "argue" với agent (bài 11). Lưu ý: `/rewind` khôi phục được cả conversation đã `/clear` trước đó — `/clear` không mất dữ liệu checkpoint.

Agentic loop vs workflow: việc mới/lạ → để agent tự explore (linh hoạt, tốn token). Việc lặp >3 lần → đóng thành skill/workflow chạy deterministic (bài 05).

---

## 3. Các nhóm tool toàn tập

| Nhóm | Tool | Việc | Lưu ý |
|---|---|---|---|
| 1 — Filesystem & tìm kiếm | `Read` / `Edit` / `Write` / `Glob` / `Grep` / `NotebookEdit` | Đọc (có line numbers), sửa chuỗi chính xác, tạo file, tìm theo pattern, tìm regex cross-file, sửa `.ipynb` | Dạy Claude: **Glob trước (rẻ), Grep sau, Read cuối**. File >300 dòng → đọc theo offset/limit |
| 2 — Thực thi | `Bash` / `BashOutput` | Chạy shell; đọc output background shell | Cửa ngõ ra mọi thứ → policy quyền xoay quanh nó. Allow theo prefix hẹp (`Bash(pnpm test:*)`), đừng `Bash(*)` (bài 10) |
| 3 — Suy luận mở rộng | `Task` / `TodoWrite` / `WebSearch` / `WebFetch` / `AskUserQuestion` | Spawn subagent; checklist >3 bước; tra docs/web; hỏi bạn khi 2+ hướng | WebSearch/WebFetch tùy provider (bài 10) |
| 4 — MCP tools | `mcp__<server>__<tool>` | Tool động từ server ngoài, ví dụ `mcp__github__create_pr` | Discover lúc startup; càng nhiều tools visible càng dễ chọn nhầm → 3–6 servers (bài 08) |

```bash
# Trong session, hỏi trực tiếp (Claude tự liệt kê tools khả dụng):
# > "liệt kê tất cả tools mày đang có + 1 câu mô tả mỗi tool"
claude mcp list   # ngoài session: kiểm tra MCP tools đang expose

# Task nền: > "Chạy pnpm build ở background, báo tao khi xong"
# Claude dùng Bash(run_in_background) + BashOutput. Kill nếu kẹt: Ctrl+X Ctrl+K hai lần trong 3 giây.
```

---

## 4. Vì sao CLAUDE.md phình làm bạn tốn tiền?

Mỗi turn nạp lại **toàn bộ context** (CLAUDE.md + history + tool results). Task 20 turns với CLAUDE.md 500 dòng = trả tiền cho 500 dòng đó 20 lần.

| Feature | Load khi nào | Chi phí | Chiến lược |
|---|---|---|---|
| CLAUDE.md | Đầu session, giữ suốt (nạp lại mỗi turn + mỗi lần compact) | **Cao** | <200 dòng, chỉ pitfalls + rationale + conventions khác default |
| Skills | Startup ~100 tokens (tên+desc); full body khi trigger | Thấp tới khi dùng | Tách checklist dài thành skill |
| MCP servers | Lazy khi tool được gọi | Thấp, nhưng >10 tools visible giảm accuracy | 3–6 servers, prune định kỳ |
| Subagents | Mỗi lần spawn ~20k overhead (số liệu cộng đồng) | Đắt, multi-agent 3–4x single-thread | Chỉ khi xứng đáng (research ồn/song song) |
| Hooks (`command`) | Tại event, chạy ngoài model | **0 model tokens** | Rule quan trọng → nâng thành hook |
| Image/PDF attach | Khi paste | Cao (vision tokens) | Chỉ attach ảnh cần thiết |

Nhẩm nhanh: CLAUDE.md 150 dòng ≈ 2.500 tokens; 10 turns = 25k tokens. Phình 600 dòng (≈10k tokens) → 100k tokens cho cùng task. 1 giờ dọn CLAUDE.md (bài 03) tiết kiệm hơn 1 tuần tối ưu prompt.

```bash
# Trong session, sau 1 task dài:
# > /context     # grid: ai ngốn context nhất
# > /usage       # breakdown theo skills/subagents/plugins/MCP
# > /cost        # tiền session này
# Rồi hỏi: "đề xuất 3 thứ cắt giảm context mà không mất chất lượng"
```

Checklist tiết kiệm token (dán vào team wiki): CLAUDE.md <200 dòng (`wc -l CLAUDE.md`); checklist dài → skill; MCP ≤6 servers, tools visible ≤10; research rộng → subagent Explorer; task mới → `/clear` trước; context >80% → `/compact [focus]`; rule bị miss 2 lần → nâng thành hook.

---

## 5. Claude Code làm được gì (thực tế)

- **Build feature / fix bug đa file**: mô tả ý định, Claude tự tìm file, sửa, chạy test.
- **Việc nhàm chán**: viết test thiếu, fix lint toàn repo, resolve merge conflict, upgrade dependency, release notes.
- **Git/GitHub**: stage, commit message, branch, PR, đọc PR comments (`/pr_comments`).
- **MCP**: đọc Google Drive, Jira, Slack, DB, browser (Playwright).
- **Tự động hóa**: hooks, routines (`/schedule`), CI/CD, Agent SDK.

```text
# Fix bug đa file:
"Trong packages/auth, test `pnpm --filter @acme/auth test` đang fail 2 cases.
Tìm root cause, fix source (không sửa test cho pass ảo), chạy lại focused test,
rồi báo cáo: file nào đổi, vì sao, còn rủi ro gì."

# Việc nhàm chán:
"Trong apps/api/src/routes/, file nào chưa có test thì viết test theo mẫu
login.test.ts. Sau 5 files đầu dừng báo cáo để tao review trước khi làm tiếp."

# Git/GitHub:
"Review git diff, stage từng hunk, commit theo conventional commits, push
feat/x và mở PR với mô tả + checklist test đã chạy. Không merge."
```

---

## 6. Các bề mặt sử dụng — chọn cái nào?

| Surface | Code chạy ở đâu | Dùng local config? | Khi nào dùng |
|---|---|---|---|
| **Terminal CLI** (`claude`) | Máy bạn | Có | Mặc định, mạnh nhất, đủ flags |
| **VS Code / JetBrains** | Máy bạn | Có | Inline diff, @-mention, plan review trong editor |
| **Desktop app** | Máy bạn hoặc cloud VM | Local: có / Cloud: không | Multi-session side-by-side, review trực quan, `/schedule` bằng UI, in-app browser |
| **Web** (`claude.ai/code`) | Anthropic cloud VM | Không (chỉ repo) | Task dài 30'+, gập laptop vẫn chạy, check từ điện thoại |
| **Mobile + Remote Control** | Máy bạn (qua remote) / cloud | Tùy loại session | Monitor/approve từ điện thoại (`/mobile` hiện QR) |
| **Slack, CI/CD** | Cloud/CI runner | Tùy cấu hình | Team workflow, auto-fix PR (bài 12) |

> Hành vi agent **giống nhau mọi nơi** — chỉ khác nơi code chạy và config nào được dùng. Local dùng `~/.claude/` + `.claude/` + env máy bạn; cloud chỉ thấy repo + env đặt trên web (chi tiết bài 02).

Hỏi nhanh: task fix typo 2 phút → Terminal; refactor 1 giờ → Web cloud; review 25 files → Desktop/IDE.

---

## 7. Bản đồ mở rộng + tính năng 2026 cần biết

Lớp mở rộng trên vòng lặp agent — học thuộc bảng này:

| Feature | Là gì | Khi nào dùng | Bài |
|---|---|---|---|
| **CLAUDE.md** | Context nạp mỗi session | Quy ước "luôn luôn làm X" | 03 |
| **`.claude/rules/`** | Rule theo path (frontmatter `paths`) | Quy ước cho 1 subtree | 03 |
| **Skill** | Kiến thức + workflow tái dùng, `/ten` hoặc tự load | Việc lặp, load khi cần | 05 |
| **Subagent** | Worker context riêng, trả tóm tắt | Task ồn, song song, chuyên gia hẹp | 06 |
| **Agent teams** | Nhiều session phối hợp (lead + teammates) | Review đa góc, debug đa giả thuyết | 06 |
| **MCP** | Kết nối dịch vụ ngoài | Dữ liệu/hành động ngoài repo | 08 |
| **Hook** | Script chạy theo lifecycle event | Việc **phải** chạy, không được quên | 07 |
| **Plugin** | Đóng gói skills+hooks+subagents+MCP thành 1 unit | Tái dùng cross-repo, share team | 09 |

Tính năng mới 2026 đáng nhớ (chi tiết ở các bài tương ứng):

- **Auto mode** là permission mode mặc định cho session mới trên Pro/Max/Team từ 14/08/2026; chặn destructive git + `rm -rf`, có hard deny rules (bài 10).
- **Models hiện tại**: Claude Opus 5.5 (1M context, default), Claude Sonnet 5.5 (default Pro/Team Standard), Claude Fable 5.1 — chi tiết bài 14.
- **Background subagents mặc định**; subagent spawn subagent tối đa 5 tầng; `/fork` tạo session song song thử what-if (bài 06).
- **`/rewind`** khôi phục code + conversation, kể cả trước khi `/clear`; `/cd` đổi working dir giữa conversation; `/doctor` (alias `/checkup`) full setup checkup (bài 04).
- **Cross-session messaging** (macOS/Linux) + **`@` mention session khác** để giao tin giữa các session đang chạy (bài 06).
- **`claude mcp login` / `claude mcp logout`** — OAuth cho MCP server ngay từ terminal (bài 08).
- **`claude agents`** — Agent view một màn hình cho mọi session đang chạy (bài 06).
- **`/code-review`** chạy background subagent; `/ultrareview` fleet bug-hunting trên cloud (public preview) (bài 04).

---

## 8. Đi từng bước cho người mới

Yêu cầu: đã cài xong (bài 01). 30 phút đầu chuẩn:

```bash
cd /path/to/repo-cua-ban
claude
# Lần đầu: onboarding (theme, permissions) → chọn defaults.
```

```text
1. /init     # Claude quét repo, sinh CLAUDE.md nháp. Đọc, xóa 50% câu chung chung (bài 03).
2. "Đọc README + package.json, tóm tắt: project này là gì, chạy dev/test bằng lệnh nào.
    Không sửa gì."          # kiểm tra Claude đọc đúng repo
3. "Chạy linter, fix 3 lỗi đầu, chạy lại lint xác nhận. Chỉ sửa files liên quan."
    # quan sát vòng lặp: đọc → sửa → chạy → đọc output → sửa tiếp
4. /cost     # xem tốn bao nhiêu; /export session-01.txt nếu cần lưu
5. /clear    # nếu làm task mới (history xóa, CLAUDE.md giữ nguyên), hoặc exit
```

Checklist hiểu bài 00: giải thích được vòng lặp agent trong 2 phút; kể được 4 nhóm tools; biết vì sao CLAUDE.md phình tốn tiền; chạy xong 5 bước trên với 1 task pass thật.

---

## 9. Hiểu nhầm và bẫy thường gặp

| Hiểu nhầm / Bẫy | Sự thật / Fix |
|---|---|
| Claude Code = chatbot thông minh hơn | Là agent có tay (tools) tự làm nhiều bước; giao `tìm root cause + fix + chạy test`, đừng hỏi nghĩa lỗi |
| Càng nhiều CLAUDE.md càng tốt | Mỗi dòng tốn tiền N turns. >200 dòng → cắt, chuyển checklist thành skill |
| Subagent/MCP càng nhiều càng mạnh | ~20k overhead/spawn; quá 10 MCP tools dễ chọn nhầm. Giữ 3–6 servers, trần 3–5 subagents song song |
| Agent báo xong là xong | Mọi task code phải có lệnh verify chạy thật: `pnpm test`, `pnpm lint`, `pnpm build` |
| Surface nào cũng như nhau | Cloud mất MCP/hook local; cần setup script + env vars riêng (bài 02) |
| Loop càng dài càng gần xong | Sau turn 15+ càng sửa càng nát → `/clear`, chia nhỏ |
| Prompt như chatbot, sai scope | Prompt luôn có: mục tiêu + files scope + lệnh verify + "đừng đụng X" |
| Giao task 50 bước 1 lúc | Chia phase, mỗi phase 1 gate review; dùng TodoWrite |
| Spawn 10 subagents "cho nhanh" | Bill nổ 3–4x; trần 3–5 concurrent |
| Sửa 10 turns vẫn sai | Quy tắc 2 lần: sai 2 lần → `/rewind` + re-prompt sạch |
| Dùng `--dangerously-skip-permissions` trên máy dev | Chỉ trong sandbox/CI; máy dev dùng `auto` + rules hẹp (bài 10) |

---

## 10. Bài tập + đi tiếp tới đâu?

**Bài tập (4 bài, ~70 phút):**

1. **Trace vòng lặp (15'):** giao 1 task nhỏ, xong hỏi Claude "liệt kê từng turn: reasoning/tool/observation", đối chiếu mục 2.
2. **Token economics (15'):** chạy `/context` + `/usage` + `/cost` sau task dài; đề xuất 1 thay đổi cắt context và đo lại.
3. **Phân loại extension (20'):** lấy 5 nhu cầu thật của team, điền CLAUDE.md / Skill / Subagent / Hook / MCP / Plugin (đối chiếu bảng mục 7).
4. **Walkthrough (20'):** làm đủ 5 bước mục 8 trên repo thật, `/export` lại.

**Đi tiếp:**

- **[01 — Cài đặt + xác thực](./01-cai-dat-va-xac-thuc.md)** — chưa cài được / `claude doctor` báo đỏ.
- **[02 — Bề mặt sử dụng](./02-cac-be-mat-terminal-ide-web-desktop.md)** — CLI flags, IDE, cloud env, mobile.
- **[03 — CLAUDE.md + memory + rules](./03-claude-md-memory-rules.md)** — file quan trọng nhất.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)** — tra cứu `/clear /compact /fork /rewind...`.
- **[05 — Skills](./05-skills-custom-commands.md)** — đóng gói việc lặp lại.
- **[06 — Subagents & agent teams](./06-subagents-agent-teams-parallel.md)** — orchestration, cost math.
- **[07 — Hooks](./07-hooks-tu-dong-hoa.md)** — rule hay quên thành luật enforce thật.
- **[08 — MCP](./08-mcp-ket-noi-cong-cu-ngoai.md)** — nối GitHub/DB/browser/Slack.
- **[09 — Plugins](./09-plugins-marketplaces.md)** / **[10 — Permissions](./10-permissions-modes-availability.md)** / **[11 — Worktrees & checkpoints](./11-git-worktrees-checkpoints.md)** / **[12 — SDK & CI/CD](./12-agent-sdk-ci-cd-automation.md)**.
