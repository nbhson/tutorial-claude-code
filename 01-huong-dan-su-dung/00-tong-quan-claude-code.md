# 00 — Tổng Quan Claude Code: Tư Duy Agent, Không Phải Chatbot

> Bài mở đầu của series `01-huong-dan-su-dung/`. Đọc xong bạn sẽ hiểu vòng lặp agentic,
> các nhóm tool, kinh tế token, và bản đồ toàn bộ khóa học. Thời gian đọc: ~25 phút.

## Mục lục

1. [Claude Code là gì?](#1-claude-code-là-gì)
2. [Agentic loop deep-dive (why, không chỉ what)](#2-agentic-loop-deep-dive-why-không-chỉ-what)
3. [Tool categories toàn tập](#3-tool-categories-toàn-tập)
4. [Token economics — tiền của bạn đi đâu?](#4-token-economics--tiền-của-bạn-đi-đâu)
5. [Claude Code làm được gì (thực tế)](#5-claude-code-làm-được-gì-thực-tế)
6. [Các bề mặt sử dụng — chọn cái nào?](#6-các-bề-mặt-sử-dụng-surfaces--chọn-cái-nào)
7. [Bản đồ extension](#7-bản-đồ-extension-claudemd--skills--subagents--hooks--mcp--plugins)
8. [Walkthrough step-by-step cho người mới](#8-walkthrough-step-by-step-cho-người-mới-từ-0-tới-task-đầu-tiên)
9. [Pitfalls + cách fix](#9-pitfalls--cách-fix)
10. [Bài tập thực hành](#10-bài-tập-thực-hành)
11. [Đi tiếp tới đâu?](#11-đi-tiếp-tới-đâu-link-chéo)

---

## 1. Claude Code là gì?

**Claude Code** là coding agent của Anthropic: một CLI (và IDE/Desktop/Web app) chạy model Claude
với quyền truy cập trực tiếp filesystem + terminal. Khác chatbot ở chỗ:

| Chatbot (claude.ai chat) | Claude Code (agentic loop) |
|---|---|
| Bạn paste code vào, nó trả lời text | Nó tự đọc file, sửa file, chạy lệnh, xem kết quả, lặp lại tới khi xong |
| 1 lượt request → 1 response | 1 task → N vòng: reasoning → tool_use → observation → reasoning tiếp |
| Không làm gì ngoài text | Có tools: Read, Edit, Write, Glob, Grep, Bash, WebSearch, WebFetch, Task (spawn subagent), MCP tools |
| Bạn là người làm việc nặng (copy/paste/chạy) | Agent làm việc nặng, bạn review + quyết định |

Vòng lặp agentic cốt lõi (giống nhau trên mọi surface — terminal, IDE, desktop, web):

```
Bạn prompt → Claude reasoning → gọi tools (đọc/sửa/chạy) → đọc kết quả trả về
→ reasoning tiếp → ... → khi đạt mục tiêu thì dừng, báo cáo + diff
```

### 1.1. Vì sao "agent" khác "autocomplete"?

Copilot/Tab-completion đoán **dòng tiếp theo** trong file bạn đang mở. Claude Code giải
**task đóng**: "fix failing tests", "thêm OAuth", "migrate table". Nó phải tự:

1. Khám phá repo (tìm file liên quan mà bạn không chỉ).
2. Lập kế hoạch nhiều bước.
3. Thực thi từng bước bằng tools.
4. Tự kiểm chứng (chạy test, đọc lỗi, sửa lại).

> Tư duy đúng: đừng prompt như hỏi Google ("làm sao fix lỗi X?"). Hãy giao việc như giao
> cho junior dev giỏi: cho mục tiêu + tiêu chí xong + quyền hạn, rồi để nó tự tìm đường.

Ví dụ prompt tệ vs tốt:

```text
# TỆ — hỏi như chatbot:
"lỗi TypeError: Cannot read properties of undefined nghĩa là gì?"

# TỐT — giao task như agent:
"Trong apps/api, endpoint POST /orders crash khi payload thiếu customerId.
Tìm root cause, fix, thêm regression test, chạy pnpm --filter @acme/api test.
Đừng sửa gì ngoài scope này."
```

---

## 2. Agentic loop deep-dive (why, không chỉ what)

### 2.1. Giải phẫu 1 vòng lặp

Mỗi vòng lặp gồm 4 pha:

```
┌─────────────────────────────────────────────────┐
│ 1. REASONING (model nghĩ)                        │
│    "Cần đọc file nào? Lệnh gì xác nhận giả thiết?"│
├─────────────────────────────────────────────────┤
│ 2. TOOL_USE (model gọi 1..n tools song song)      │
│    Read(auth.ts) + Grep("customerId") + Bash(...) │
├─────────────────────────────────────────────────┤
│ 3. OBSERVATION (harness trả kết quả về)           │
│    file content / stdout / stderr / exit code     │
├─────────────────────────────────────────────────┤
│ 4. ĐIỀU KIỆN DỪNG? (model tự đánh giá)            │
│    Chưa xong → quay lại (1). Xong → báo cáo.      │
└─────────────────────────────────────────────────┘
```

Điểm mấu chốt: **harness Claude Code không phải model**. Model chỉ sinh text + tool calls.
Harness (CLI binary) mới là thứ thực thi Read/Edit/Bash trên máy bạn, áp permission checks,
chạy hooks, rồi nhét kết quả lại vào context cho vòng tiếp theo.

Vì sao tách vậy? Để:

- Permission/hook enforce được **kể cả khi model muốn lách** (model không chạm disk trực tiếp).
- Cùng 1 model hành xử nhất quán trên terminal/IDE/cloud (chỉ đổi harness backend).
- Gắn được determinism (hooks, sandbox) vào vòng lặp xác suất (LLM).

### 2.2. Ví dụ trace 1 task thật

Task: *"Thêm rate-limit cho POST /login"*.

```
Turn 1: reasoning "tìm code login" → Glob(apps/api/**/login*) + Grep("POST.*login")
Turn 2: observation trả 3 files → reasoning "đọc route + middleware" → Read(route.ts) + Read(middleware.ts)
Turn 3: reasoning "chưa có limiter, check lib sẵn có" → Read(package.json) + Grep("rate-limit")
Turn 4: reasoning "dùng express-rate-limit, viết plan" → (plan mode) trình plan cho bạn duyệt
Turn 5: (duyệt xong) Edit(route.ts) + Edit(route.test.ts)
Turn 6: Bash(pnpm test) → FAIL (import sai) → reasoning đọc lỗi → Edit fix
Turn 7: Bash(pnpm test) → PASS → báo cáo diff + lệnh đã chạy
```

Tổng 7 turns, ~5 tool calls song song mỗi turn. Bạn chỉ gõ 1 prompt + 1 lần duyệt.

### 2.3. Khi nào loop thất bại? (3 nguyên nhân gốc)

| Nguyên nhân | Dấu hiệu | Thuộc về |
|---|---|---|
| Thiếu context (không tìm ra file đúng) | Đọc lung tung, sửa sai chỗ | Fix bằng CLAUDE.md + skills (bài 03, 05) |
| Thiếu verification (tự tin sai) | Báo "xong" nhưng test fail | Fix bằng hooks + reviewer subagent (bài 07, 06) |
| Loop quá dài (context đầy rác) | Càng sửa càng nát sau turn 15+ | Fix bằng /clear, /compact, subagent cô lập (bài 04, 06) |

> Quy tắc vàng: task >15 turns không tiến triển → dừng, `/clear`, chia nhỏ task, giao lại.
> Đừng "argue" với agent — rewind + re-prompt rẻ hơn (chi tiết bài 11).

### 2.4. Agentic loop vs workflow script

```text
Agentic loop  = model tự quyết định bước tiếp theo (linh hoạt, tốn token, đôi khi lạc).
Workflow      = script/skeleton cố định bước (vd skill /ship: merge→test→review→changelog),
                model chỉ điền nội dung từng bước (ổn định, rẻ, hợp việc lặp lại).
```

Kinh nghiệm: việc mới/lạ → để agent tự explore. Việc lặp >3 lần → đóng thành skill/workflow
để lần sau chạy deterministic (bài 05).

---

## 3. Tool categories toàn tập

Claude Code v2.1.x có 4 họ tool. Học thuộc để biết khi nào cái gì chạy:

### 3.1. Họ 1 — Filesystem & tìm kiếm (local, nhanh, rẻ)

| Tool | Việc | Ví dụ gọi |
|---|---|---|
| `Read` | Đọc file (có line numbers) | `Read apps/api/src/routes/login.ts` |
| `Edit` | Sửa string chính xác trong file | Thay `oldString` → `newString` |
| `Write` | Tạo/ghi đè file | Sinh file mới, test mới |
| `Glob` | Tìm file theo pattern | `**/*.test.ts`, `apps/**/login*` |
| `Grep` | Tìm nội dung regex cross-file | `Grep "customerId" --type ts` |
| `NotebookEdit` | Sửa Jupyter notebook cells | Sửa `.ipynb` |

Cơ chế sâu: `Read` trả về nội dung + line numbers để `Edit` neo chính xác. `Glob` rẻ hơn
`Grep` (chỉ match tên file, không đọc nội dung). Dạy Claude: **Glob trước, Grep sau, Read cuối**
để đỡ ngốn context. File >300 dòng → Claude nên đọc theo offset/limit, không đọc cả cục.

### 3.2. Họ 2 — Thực thi (quyền lực nhất, nguy hiểm nhất)

| Tool | Việc | Guardrail |
|---|---|---|
| `Bash` | Chạy shell command | Permission rules + PreToolUse hooks (bài 07, 10) |
| `BashOutput` | Đọc output của background shell | Theo dõi task dài |

`Bash` là cửa ngõ ra mọi thứ: `git`, `pnpm`, `docker`, `psql`, `curl`. Vì vậy mọi policy
quyền đều xoay quanh nó. Sai lầm phổ biến: allow `Bash` kiểu `Bash(*)` = đưa chìa khóa nhà.
Đúng: allow theo prefix hẹp (`Bash(pnpm test:*)`, `Bash(git diff:*)`) — chi tiết bài 10.

### 3.3. Họ 3 — Suy luận mở rộng (context multipliers)

| Tool | Việc | Khi dùng |
|---|---|---|
| `Task` | Spawn subagent (context riêng) | Research ồn, việc song song (bài 06) |
| `TodoWrite` | Lập checklist task nhiều bước | Task >3 bước để khỏi quên |
| `WebSearch` / `WebFetch` | Tìm/đọc web | Tra docs, GitHub issues (provider-dependent, bài 10) |
| `AskUserQuestion` | Hỏi bạn (multiple choice) | Khi có 2+ hướng đi, hỏi thay vì đoán |

### 3.4. Họ 4 — MCP tools (động, từ server ngoài)

Tên dạng `mcp__<server>__<tool>`, ví dụ `mcp__github__create_pr`, `mcp__postgres__query`.
Discover động lúc startup; gọi như tool built-in nhưng chạy qua MCP server (bài 08).
Càng nhiều MCP tools visible → model càng dễ chọn nhầm → giữ 3–6 servers thực dùng.

### 3.5. Ví dụ copy-paste: xem agent đang có tools gì

```bash
# Trong session, hỏi trực tiếp (Claude tự liệt kê tools khả dụng):
# > "liệt kê tất cả tools mày đang có + 1 câu mô tả mỗi tool"

# Ngoài session: kiểm tra MCP tools đang expose:
claude mcp list
```

```bash
# Test Glob vs Grep — tự cảm nhận chi phí:
# Trong session prompt:
# > "Dùng Glob tìm mọi file tên *login* trong apps/, rồi mới Grep 'rateLimit' trong số đó.
# >  Giải thích vì sao thứ tự này rẻ hơn Grep toàn repo trước."
```

```bash
# Test BashOutput với task nền:
# > "Chạy pnpm build ở background, báo tao khi xong"
# Claude sẽ dùng Bash (run_in_background) + BashOutput để poll.
# Kill nếu kẹt: Ctrl+X Ctrl+K hai lần trong 3 giây.
```

---

## 4. Token economics — tiền của bạn đi đâu?

### 4.1. Vì sao phải quan tâm?

Mỗi turn loop nạp lại **toàn bộ context** (CLAUDE.md + history + tool results) + sinh tokens mới.
Task 20 turns với CLAUDE.md 500 dòng = trả tiền cho 500 dòng đó 20 lần. Đó là lý do file
này nhấn mạnh "giữ CLAUDE.md <200 dòng" ở mọi bài.

### 4.2. Bảng chi phí context của từng thứ

| Feature | Load khi nào | Chi phí | Chiến lược |
|---|---|---|---|
| CLAUDE.md | Đầu session, giữ suốt (nạp lại mỗi turn + mỗi lần compact) | **Cao** | <200 dòng, chỉ pitfalls + rationale + conventions khác default |
| System prompt + tools defs | Luôn luôn | Cố định (không điều khiển được) | Bỏ qua |
| Skills | Start chỉ ~100 tokens (tên+desc); full body khi trigger | **Thấp tới khi dùng** | Tách checklist dài thành skill thay vì nhét CLAUDE.md |
| MCP servers | Lazy khi tool được gọi | Thấp, nhưng >10 tools visible giảm accuracy | 3–6 servers, prune định kỳ |
| Subagents | Mỗi lần spawn ~20k overhead (số liệu cộng đồng) | **Đắt**, multi-agent 3–4x single-thread | Chỉ khi xứng đáng (research ồn/song song) |
| Hooks (`command`) | Tại event, chạy ngoài model | **0 model tokens** | Rule quan trọng → nâng thành hook |
| Image/PDF attach | Khi paste | Cao (vision tokens) | Chỉ attach ảnh cần thiết |

> Hệ quả: CLAUDE.md phình = trả tiền mọi turn. Skill để không = rẻ. Subagent spawn bừa = đắt gấp 3–4x.
> Hooks là thứ duy nhất "miễn phí token + bắt buộc thực thi" — rule nào quan trọng thì nâng thành hook.

### 4.3. Ví dụ tính tiền nhẩm (copy-paste được)

```text
Giả định (làm tròn để nhẩm nhanh):
- CLAUDE.md 150 dòng ≈ 2.500 tokens.
- 1 task 10 turns → CLAUDE.md tốn 10 × 2.500 = 25.000 tokens input.
- Nếu CLAUDE.md phình 600 dòng (≈10.000 tokens) → 10 × 10.000 = 100.000 tokens.
- Chênh lệch 75.000 tokens/task × 20 tasks/tuần = 1,5M tokens/tuần vứt qua cửa sổ.

Kết luận: 1 giờ dọn CLAUDE.md (bài 03) tiết kiệm nhiều hơn 1 tuần tối ưu prompt.
Kiểm chứng thực tế: /cost (session hiện tại), /usage (breakdown theo category),
/context (grid visualize ai ngốn context).
```

```bash
# Trong session, sau 1 task dài, chạy tuần tự:
# > /context     # xem ai ngốn context nhất
# > /usage       # breakdown skills/subagents/plugins/MCP
# > /cost        # tiền session này
# Rồi hỏi: "đề xuất 3 thứ cắt giảm context mà không mất chất lượng"
```

### 4.4. Checklist tiết kiệm token (dán vào team wiki)

- [ ] CLAUDE.md <200 dòng (check: `wc -l CLAUDE.md .claude/CLAUDE.md ~/.claude/CLAUDE.md`).
- [ ] Checklist dài → skill (lazy-load), không nhét CLAUDE.md.
- [ ] MCP ≤6 servers, tools visible ≤10.
- [ ] Research rộng → subagent Explorer (trả summary 10 dòng, không đổ 50 files vào main).
- [ ] Task mới → `/clear` trước khi bắt đầu (đừng nối task mới vào context cũ).
- [ ] Context >80% → `/compact [focus]` hoặc `/clear` + tóm tắt tay.
- [ ] Rule bị miss 2 lần → nâng thành hook (0 token, enforce thật).

---

## 5. Claude Code làm được gì (thực tế)

- **Build feature / fix bug đa file**: mô tả ý định, nó tự tìm file liên quan, sửa, chạy test.
- **Việc nhàm chán**: viết test cho code chưa có test, fix lint toàn repo, resolve merge conflict,
  upgrade dependency, viết release notes.
- **Git/GitHub**: stage, commit message, tạo branch, mở PR, đọc PR comments (`/pr_comments`).
- **Kết nối công cụ ngoài qua MCP**: đọc Google Drive, Jira, Slack, DB, browser (Playwright).
- **Tự động hóa**: hooks (chạy eslint sau mỗi edit), routines (`/schedule` chạy định kỳ),
  CI/CD (GitHub Actions), Agent SDK (build agent riêng).

### 5.1. 3 ví dụ end-to-end (copy-paste prompt mẫu)

```text
# Ví dụ 1 — Fix bug đa file (10 phút):
"Trong packages/auth, test `pnpm --filter @acme/auth test` đang fail 2 cases.
Tìm root cause, fix source (không sửa test để cho pass ảo), chạy lại focused test,
rồi báo cáo: file nào đổi, vì sao, còn rủi ro gì."
```

```text
# Ví dụ 2 — Việc nhàm chán (viết test thiếu):
"Trong apps/api/src/routes/, file nào chưa có test tương ứng thì viết test mới
theo mẫu của login.test.ts. Chạy pnpm --filter @acme/api test sau mỗi file.
Dừng lại báo cáo sau 5 files đầu để tao review trước khi làm tiếp."
```

```text
# Ví dụ 3 — Git/GitHub:
"Review git diff hiện tại, stage từng hunk hợp lý, viết commit message theo
conventional commits (feat/fix/test), push branch feat/x và mở PR với mô tả +
checklist test đã chạy. Không merge."
```

---

## 6. Các bề mặt sử dụng (surfaces) — chọn cái nào?

| Surface | Code chạy ở đâu | Dùng local config? | Khi nào dùng |
|---|---|---|---|
| **Terminal CLI** (`claude`) | Máy bạn | Có | Mặc định, mạnh nhất, hỗ trợ mọi provider |
| **VS Code / JetBrains extension** | Máy bạn | Có | Cần inline diff, @-mention, plan review trong editor |
| **Desktop app** | Máy bạn hoặc cloud VM | Local: có / Cloud: không | Muốn review diff trực quan, multi-session side-by-side, lên lịch task |
| **Web** (`claude.ai/code`) | Anthropic cloud VM | Không (chỉ repo) | Task dài, không cần local setup, chạy song song, check từ điện thoại |
| **Mobile (iOS/Android) + Remote Control** | Máy bạn (qua remote) / cloud | Tùy loại session | Monitor session từ điện thoại, `/mobile` hiện QR |
| **Slack, CI/CD** | Cloud/CI runner | Tùy cấu hình | Team workflow, auto-fix PR |

> Hành vi agent **giống nhau mọi nơi** — chỉ khác nơi code chạy và config nào được dùng.

So sánh nhanh Web vs Remote vs CLI vs Desktop:

| Tiêu chí | Web | Remote Control | Terminal CLI | Desktop |
|---|---|---|---|---|
| Chạy trên | Cloud VM | Máy bạn | Máy bạn | Máy bạn hoặc cloud |
| Chat từ | Browser/mobile app | claude.ai/mobile | Terminal | Desktop UI |
| Cần GitHub | Có | Không | Không | Chỉ với cloud session |
| Chạy tiếp khi disconnect | Có | Khi terminal còn mở | Không | Tùy loại session |
| Dùng MCP/hook local | Không (cấu hình lại env) | Có | Có | Local: có / Cloud: không |

Chi tiết từng surface + CLI flags + cloud setup: xem bài 02.

---

## 7. Bản đồ extension: CLAUDE.md / Skills / Subagents / Hooks / MCP / Plugins

Đây là lớp mở rộng trên vòng lặp agentic. Học thuộc bảng này:

| Feature | Nó là gì | Khi nào dùng | Ví dụ |
|---|---|---|---|
| **CLAUDE.md** | Context nạp mỗi session | Quy ước "luôn luôn làm X" | "Dùng pnpm, không dùng npm. Chạy test trước khi commit." |
| **Skill** | Kiến thức + workflow tái dùng, gọi bằng `/ten` hoặc Claude tự load | Việc lặp lại, tài liệu tham khảo | `/deploy` chạy checklist deploy; skill API style-guide |
| **Subagent** | Worker chạy context riêng, trả về tóm tắt | Task ồn ào, task song song, chuyên gia hẹp | Research đọc 50 file nhưng chỉ trả về 10 dòng kết luận |
| **Agent teams** | Nhiều session phối hợp (lead + teammates) | Nghiên cứu song song, review đa góc | Reviewers check security + perf + tests cùng lúc |
| **Code intelligence** | Language-server: jump-to-def, type errors live | Ngôn ngữ typed, repo lớn grep chậm | Nhảy tới definition thay vì đọc cả file |
| **MCP** | Kết nối dịch vụ ngoài | Dữ liệu/hành động ngoài repo | Query DB, post Slack, điều khiển browser |
| **Hook** | Script chạy khi tới lifecycle event | Việc **phải** chạy mỗi lần, không được quên | Chạy ESLint sau mỗi lần edit file |
| **Plugin / Marketplace** | Đóng gói skills+hooks+subagents+MCP thành 1 unit cài được | Tái dùng cross-repo, share cho team | Plugin `security-review` cài 1 phát cho mọi repo |

Quy tắc chọn nhanh:

- Fact cần **mọi session** → `CLAUDE.md` (bài 03).
- Quy tắc cho **1 subtree** → `.claude/rules/` (có `paths` frontmatter) (bài 03).
- Kiến thức/workflow **tái dùng, load khi cần** → Skill (bài 05).
- Việc **cô lập context** → Subagent (bài 06).
- Hệ thống ngoài / tool custom → MCP (bài 08).
- Hành động **deterministic theo event** → Hook (bài 07).
- Phân phối cho team/nhiều repo → Plugin (bài 09).

### Chi phí context của từng thứ (quy hoạch token)

| Feature | Load khi nào | Chi phí |
|---|---|---|
| CLAUDE.md | Đầu session, giữ suốt | Cao (nạp lại mỗi turn/compaction) → giữ <200 dòng |
| Skills | Chỉ tên+description (~100 tokens) lúc start; full body khi trigger | Thấp tới khi dùng |
| MCP servers | Lazy, khi tool được gọi | Thấp tới khi dùng (nhưng >10 tools visible làm giảm accuracy chọn tool) |
| Subagents | Khi spawn | ~20k overhead mỗi lần spawn (số liệu cộng đồng) — chỉ dùng khi xứng đáng |
| Hooks | Tại event | **0 model tokens** (chạy ngoài model) |

## 8. Walkthrough step-by-step cho người mới (từ 0 tới task đầu tiên)

> Yêu cầu: đã cài xong (nếu chưa, xem bài 01). Dưới đây là 30 phút đầu chuẩn.

**Bước 1 — Mở session trong repo thật (2 phút):**

```bash
cd /path/to/repo-cua-ban
claude
# Lần đầu: Claude hỏi onboarding (theme, permissions) → chọn defaults.
```

**Bước 2 — Sinh CLAUDE.md nháp (5 phút):**

```text
Trong session gõ:
/init
# Claude quét repo, sinh CLAUDE.md nháp. Đọc file sinh ra, xóa 50% câu chung chung.
# Chỉ giữ lệnh verified + rules khác default (chi tiết bài 03).
```

**Bước 3 — Giao task nhỏ đầu tiên (10 phút):**

```text
Prompt mẫu:
"Đọc README + package.json, tóm tắt: project này là gì, chạy dev bằng lệnh nào,
test bằng lệnh nào. Không sửa gì, chỉ trả lời."
# Mục đích: kiểm tra Claude đọc đúng repo, bạn học cách nó explore.
```

**Bước 4 — Task sửa thật có verify (10 phút):**

```text
"Chạy linter của repo, fix 3 lỗi đầu tiên, chạy lại lint để xác nhận.
Chỉ sửa files liên quan, không đụng config."
# Quan sát: nó đọc file → sửa → chạy lệnh → đọc output → sửa tiếp (agentic loop).
```

**Bước 5 — Đóng session sạch (3 phút):**

```text
/cost     # xem tốn bao nhiêu
/export session-01.txt   # lưu lại nếu cần
# Rồi /clear nếu làm task mới, hoặc gõ exit để thoát.
```

Checklist bạn đã hiểu bài 00 khi:

- [ ] Giải thích được agentic loop cho đồng nghiệp trong 2 phút.
- [ ] Kể được 4 họ tools + ví dụ mỗi họ.
- [ ] Biết vì sao CLAUDE.md phình gây tốn tiền.
- [ ] Chạy xong 5 bước walkthrough trên và có 1 task pass thật.

---

## 9. Pitfalls + cách fix

| Pitfall | Vì sao xảy ra | Fix |
|---|---|---|
| Prompt như chatbot, agent làm sai scope | Không cho tiêu chí xong + ranh giới | Prompt luôn có: mục tiêu + files scope + lệnh verify + "đừng đụng X" |
| Giao task 50 bước 1 lúc, càng về sau càng nát | Context đầy, model quên đầu bài | Chia phase, mỗi phase 1 gate review; dùng TodoWrite |
| CLAUDE.md 500 dòng copy wiki | Nghĩ "càng nhiều càng tốt" | Cắt <200 dòng, checklist dài → skill, rule hay miss → hook |
| Spawn 10 subagents song song rồi cháy tiền | Không biết overhead 20k/spawn | Trần 3–5 concurrent; task 1 bước làm trực tiếp |
| MCP cài 15 servers "cho chắc" | Nghĩ thừa còn hơn thiếu | Giữ 3–6, prune cái 2 tuần không gọi; check `/usage` |
| Tin agent báo "xong" mà không verify | Thiếu gate | Mọi task code phải có lệnh verify chạy thật (test/lint/build) |
| Sửa 10 turns vẫn sai, càng sửa càng nát | Sunk-cost, không rewind | Quy tắc 2 lần: sai 2 lần → rewind + re-prompt sạch (bài 11) |
| Dùng `--dangerously-skip-permissions` trên máy dev | Tiện tay copy từ CI | Chỉ dùng trong sandbox/CI; máy dev dùng `auto` + rules hẹp (bài 10) |

---

## 10. Bài tập thực hành

**Bài 1 (15 phút) — Trace agentic loop:**
Giao 1 task nhỏ, sau khi xong hỏi Claude: *"liệt kê từng turn mày đã làm: reasoning gì,
tool gì, observation gì"*. So sánh với sơ đồ mục 2.1. Ghi lại số turns + số tool calls.

**Bài 2 (15 phút) — Đo token economics:**
Chạy `/context` + `/usage` + `/cost` sau 1 task dài. Tìm top-1 thứ ngốn context nhất.
Đề xuất 1 thay đổi (cắt CLAUDE.md / tách skill / bớt MCP) và đo lại ở task sau.

**Bài 3 (20 phút) — Phân loại extension:**
Lấy 5 nhu cầu thật của team bạn, điền vào bảng: mỗi nhu cầu thuộc CLAUDE.md / Skill /
Subagent / Hook / MCP / Plugin? Giải thích 1 câu mỗi ô. Đối chiếu với bảng mục 7.

**Bài 4 (20 phút) — Walkthrough chuẩn:**
Làm đủ 5 bước mục 8 trên 1 repo thật. Lưu output `/export` lại. Liệt kê 3 điều bạn
hiểu sai trước khi đọc bài này.

---

## 11. Đi tiếp tới đâu? (link chéo)

- **Bài 01 — Cài đặt + xác thực + `claude doctor`**: nếu bạn chưa cài được hoặc setup báo đỏ.
- **Bài 02 — Từng surface dùng sao cho đúng**: CLI flags, IDE inline diff, cloud env, mobile.
- **Bài 03 — CLAUDE.md + memory + rules**: file quan trọng nhất, quyết định 50% chất lượng agent.
- **Bài 04 — Slash commands toàn tập**: tra cứu `/clear /compact /model /review /batch...`.
- **Bài 05 — Skills**: đóng gói việc lặp lại thành `/deploy /review-pr...`.
- **Bài 06 — Subagents & agent teams**: khi nào spawn worker, orchestration patterns, cost math.
- **Bài 07 — Hooks**: biến rule hay bị quên thành luật enforce thật.
- **Bài 08 — MCP**: nối GitHub/DB/browser/Slack vào agent.
- **Bài 09 — Plugins**: đóng gói cho team/nhiều repo.
- **Bài 10 — Permissions & availability**: allow/ask/deny + khác biệt plan/provider.
- **Bài 11 — Worktrees & checkpoints**: song song không giẫm chân + undo cả conversation.
- **Bài 12 — SDK & CI/CD**: đưa agent vào pipeline, routines định kỳ.
