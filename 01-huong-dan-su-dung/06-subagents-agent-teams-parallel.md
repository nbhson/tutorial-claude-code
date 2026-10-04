# 06 — Subagents, Agent Teams & Parallel Work

> Bài 06 của series. Đọc xong bạn có 4 agent files mẫu, biết orchestration patterns,
> tính được cost math, và biết khi nào KHÔNG spawn subagent.
> Thời gian: ~40 phút.

## Mục lục

1. [Vì sao cần subagent? (why)](#1-vì-sao-cần-subagent-1-câu)
2. [So sánh 4 cách song song](#2-so-sánh-4-cách-song-song-chọn-sai-là-tốn-tiền)
3. [4 agent files mẫu hoàn chỉnh](#3-4-agent-files-mẫu-hoàn-chỉnh-copy-paste)
4. [Điều khiển capabilities](#4-điều-khiển-capabilities)
5. [Orchestration patterns + cost math](#5-orchestration-patterns--cost-math)
6. [Walkthrough + khi nào KHÔNG dùng + bài tập](#6-walkthrough-step-by-step)
7. [Link chéo](#7-link-chéo)

---

## 1. Vì sao cần subagent? (1 câu)

> Task phụ **đọc nhiều, ồn nhiều, không cần nhớ lâu** → ném sang subagent để main thread sạch.

Mỗi subagent: context window riêng + system prompt riêng + tool allowlist riêng + permissions riêng.
Xong việc trả về **tóm tắt**, transcript ồn ở lại bên nó.

Lợi ích: giữ context (không pollute main), enforce constraints (giới hạn tools), tái dùng cross-project
(user-level `~/.claude/agents/`), chuyên môn hóa (prompt hẹp), tiết kiệm cost (route việc dễ sang Haiku).

Giá: ~20k tokens overhead mỗi lần spawn; multi-agent tốn 3–4x single-thread (số liệu cộng đồng).
→ Chỉ spawn khi xứng đáng, trần thực tế **3–5 concurrent agents**.

### 1.1. Cơ chế sâu (why overhead 20k?)

Spawn = tạo conversation mới với: system prompt agent + CLAUDE.md project (trừ Explore/Plan) +
skills preload + tool defs. Tất cả nạp trước khi agent đọc dòng code đầu tiên. Vì vậy task 1 bước
("đọc file X") spawn subagent = trả 20k để làm việc 2k. Task research 50 files = trả 20k để
tiết kiệm 100k trong main → lời.

---

## 2. So sánh 4 cách song song (chọn sai là tốn tiền)

| Cách | Ai điều phối? | Khi nào | Ví dụ |
|---|---|---|---|
| **Subagents** | Claude delegate + gom kết quả trong 1 conversation | Offload research/verify, giữ main sạch | "Research auth module, trả summary" |
| **Agent view** | Bạn giao việc, check lại sau | Dispatch sessions, attach khi cần | 3 sessions song song 3 features |
| **Agent teams** (experimental, tắt mặc định) | Lead agent plan + assign + supervise teammates | Feature mới, debug đa giả thuyết, review song song | Lead + 3 teammates (security/perf/tests) |
| **Dynamic workflows** (`/batch`...) | Script giữ plan, bung N subagents + verify chéo | Việc lớn chia nhỏ có kiểm chứng | Migrate 50 files → 10 PRs |

Khác: `Bash` tool = 1 shell command non-blocking (không phải agent). Forked subagent = subagent kế thừa
full conversation (cách spawn, không phải surface riêng). Routine = session theo lịch trên cloud.
**Worktrees**: mỗi session 1 git checkout riêng → song song không giẫm file (`/batch`/agent view tự tạo — bài 11).

### 2.1. Bảng quyết định 30 giây

```text
Task ồn nhưng cần gom về 1 quyết định? → Subagents (Claude delegate).
Muốn tự tay giao + check từng đứa? → Agent view (/agents tab Running).
Task lớn, chia nhỏ có verify chéo? → /batch workflow.
Muốn nhiều góc nhìn độc lập cùng lúc? → Agent teams.
Chỉ là "làm theo chuẩn X"? → Skill, đừng spawn (bài 05).
Hỏi nhanh giữa task? → /btw (bài 04).
```

---

## 3. 4 agent files mẫu hoàn chỉnh (copy-paste)

> Đặt vào `.claude/agents/<ten>.md` (project) hoặc `~/.claude/agents/` (personal, mọi repo).
> Gọi: tự động (qua `description` khớp task) hoặc explicit: `"dùng subagent X làm Y"`.

### 3.1. Agent 1 — Explorer (read-only research)

```markdown
---
name: explorer
description: Research codebase read-only, trả summary gọn. Dùng proactively khi cần tìm files liên quan, hiểu module, map dependencies trước khi sửa.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
model: sonnet
permissionMode: plan
maxTurns: 25
effort: medium
---

Bạn là explorer. Chỉ đọc, KHÔNG sửa.

Nhiệm vụ: với yêu cầu của user, tìm TẤT CẢ files liên quan và trả summary.

Quy trình:
1. Bắt đầu bằng Glob (tên file) → Grep (nội dung) → Read (top 5-10 files liên quan nhất).
2. Không đọc cả file 1000 dòng — dùng offset/limit, đọc phần liên quan.
3. Ghi lại: mỗi file 1 dòng (path + vai trò + có cần sửa không).

Output (bắt buộc, tối đa 30 dòng):
- **Files sẽ sửa**: path + 1 câu vì sao
- **Files chỉ đọc tham khảo**: path + 1 câu
- **Không liên quan**: bỏ qua, đừng liệt kê
- **Rủi ro**: chỗ nào dễ vỡ nếu sửa

Cấm: lan man lịch sử, paste cả file vào report, đề xuất refactor ngoài scope.
```

```text
# Gọi mẫu:
"dùng subagent explorer tìm mọi file liên quan tới POST /login rate-limit, trả summary theo format của nó"
```

### 3.2. Agent 2 — Planner (viết plan, không đụng source)

```markdown
---
name: planner
description: Viết implementation plan chi tiết (goals/files/steps/verify). Dùng khi task multi-file cần duyệt trước khi code.
tools: Read, Grep, Glob, Write
disallowedTools: Edit, NotebookEdit
model: sonnet
permissionMode: plan
maxTurns: 20
effort: high
---

Bạn là planner. Viết plan, KHÔNG sửa source (chỉ được Write vào plans/).

Quy trình:
1. Đọc code liên quan (Glob → Grep → Read như explorer).
2. Viết plan vào `plans/<YYYYMMDD>-<ten-task>.md` theo khung:
   - Goals (đo được) / Non-goals (nói rõ không làm gì)
   - Files (sửa file nào, thêm file nào, mỗi file làm gì)
   - Steps (từng bước + lệnh verify sau mỗi bước)
   - Risks (chỗ dễ vỡ + rollback)
3. Trình plan, chờ duyệt. Không tự implement.

Output: path plan file + tóm tắt 10 dòng để main duyệt nhanh.
```

```text
# Gọi mẫu:
"dùng subagent planner viết plan migrate auth từ JWT sang session, ghi vào plans/, không code"
```

### 3.3. Agent 3 — Security reviewer (read-only + git diff)

```markdown
---
name: security-reviewer
description: Review code tìm lỗ hổng bảo mật. Dùng proactively khi có diff chạm auth/input/crypto/payment.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: opus
permissionMode: plan
maxTurns: 20
skills: secure-coding-guide
memory: project
effort: high
---

Bạn là security reviewer. Chỉ đọc, không sửa.
1. `git diff main...HEAD` → liệt kê thay đổi.
2. Check theo: injection, authZ, secrets, crypto, SSRF...
3. Trả về: [SEVERITY] file:line — mô tả — gợi ý fix. Không lan man.

Quy trình chi tiết:
1. `git diff main...HEAD --stat` → scope. Diff >20 files → báo quá lớn, review theo batch.
2. Đọc từng file đổi + file test kèm (có test cho path mới?).
3. Check OWASP-flavored: injection (SQL/command/LDAP), broken access control,
   secrets hardcode, crypto yếu, SSRF, mass assignment, rate-limit thiếu.
4. Calibration: so với 3 diffs lịch sử repo (nếu có) để bớt dễ dãi/khắt khe.

Output: tối đa 10 findings `[CRITICAL|HIGH|MED|LOW] file:line — mô tả — fix`.
Không finding = nói rõ "đã check X, Y, Z — không thấy issue" (đừng im lặng).
```

### 3.4. Agent 4 — Tester (chạy test, báo pass/fail)

```markdown
---
name: tester
description: Chạy tests liên quan, báo pass/fail + root-cause guess. Dùng sau mỗi change để verify.
tools: Read, Bash
disallowedTools: Write, Edit
model: haiku
maxTurns: 15
effort: low
---

Bạn là tester. Chạy test, báo cáo, không sửa source.

Quy trình:
1. Đọc CLAUDE.md lấy lệnh test focused (vd `pnpm --filter @acme/api test <path>`).
2. Chạy focused trước, full chỉ khi được yêu cầu rõ.
3. Test flaky (pass/fail ngẫu nhiên) → ghi "FLAKY" + dừng đoán, không argue.
4. Fail → báo: lệnh chạy, failures (tối đa 10 dòng log quan trọng), 1-line root-cause guess.

Output:
- `PASS (n/n)` hoặc `FAIL (x/y)` + failures gọn
- Root-cause guess 1 dòng (ghi rõ là guess, không chắc chắn)
- Lệnh đã chạy (để main reproduce)
```

```bash
# Cài 4 agents (copy-paste):
mkdir -p .claude/agents
# Tạo explorer.md, planner.md, security-reviewer.md, tester.md với nội dung trên.
# Verify: trong session gõ /agents → tab Library phải thấy 4 đứa.
```

> Descriptions cộng dồn >15.000 tokens → warning lúc startup. Giữ `description` ngắn, chi tiết dồn vào body.

---

## 4. Điều khiển capabilities

- **Tools allowlist** (`tools:`) là load-bearing: ngoài list không gọi được dù prompt bảo gì.
- **Permission modes** per-agent; **preload skills** (`skills:`); **hooks riêng** trong frontmatter
  (`PreToolUse`/`PostToolUse`/`Stop`→`SubagentStop`... chỉ chạy khi agent đó active; project-level cần trust workspace dialog).
- **Conditional rules**: `PreToolUse` hook validate trước khi tool chạy (allow 1 số op, block op khác).
- **SubagentStart/Stop** hooks ở `settings.json` (matcher = tên agent; tên có `:` là regex → anchor `^...$`).
- Plugin agents bị bỏ qua `hooks`/`mcpServers`/`permissionMode` (copy ra ngoài nếu cần).

### 4.1. Ví dụ capabilities thực tế

```markdown
# Explorer khóa Write (dù prompt dụ "sửa luôn giúp anh" cũng không sửa được):
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
permissionMode: plan   # belt + suspenders: plan mode đã read-only

# Tester chỉ được Bash test-runner + Read (không Grep lung tung):
tools: Read, Bash
# + PreToolUse hook: chỉ cho Bash matching "pnpm *test*|pytest*|go test*",
#   block "rm|push|deploy" (xem bài 07 mẫu conditional hook).

# Reviewer preload skill secure-coding-guide:
skills: secure-coding-guide
# → agent có knowledge chuẩn team mà không cần paste vào prompt mỗi lần.
```

```bash
# Chạy cả session dưới 1 persona (hữu ích khi debug/test persona mới):
claude --agent explorer "tìm mọi file liên quan tới billing"
claude --agent tester "chạy tests cho packages/auth"

# Inline agent (không cần file, test nhanh):
claude --agents '{"quick-review":{"prompt":"Bạn là reviewer, chỉ đọc không sửa.","tools":["Read","Grep"]}}'
```

---

## 5. Orchestration patterns + cost math

### 5.1. 4 recipes thực chiến

1. **Explorer** (`Read, Grep, Glob` only): "chỉ liệt kê file mày sẽ sửa/đọc để làm change" (chống over-report).
2. **Planner** (`Read, Write` scope `plans/` qua hook): viết markdown plan goals/files/steps, không đụng source.
3. **Reviewer** (`Bash` git-read-only qua hook + `Read`): rate diff theo correctness/coverage/style/security; calibration bằng 3 diffs lịch sử repo để bớt dễ dãi.
4. **Tester** (`Bash` test-runner + `Read`): chạy tests liên quan, báo pass/fail + 1-line root-cause guess; test flaky thì ghi "flaky" và dừng đoán.

Thêm: **isolation pattern** (test/log/doc fetching ồn → subagent giữ, main chỉ nhận summary),
**parallel research** (2–3 explorers cùng lúc), **chain** (explorer → planner → implementer),
**adversarial review** (`/code-review` hoặc prompt tự viết: diff + plan + định nghĩa "finding";
reviewer fresh-context không mang định kiến của người viết — reviewer quá khắt thì dặn "chỉ flag lỗi thực sự, đừng over-engineer").

Nâng cao: foreground/background subagents (`/agents` tab Running; kill switch Ctrl+X Ctrl+K ×2),
output scanning, subagents spawn subagents (dùng tiết chế — token cộng dồn), concurrent limit.
Xem `/agents`, worktrees (bài 11), `/batch`.

### 5.2. Orchestration patterns (khi nào xếp thế nào)

```text
Pattern A — Parallel research (nhanh nhất cho task mới):
main: "spawn 3 explorers song song: (1) auth flow, (2) DB schema, (3) API routes. Mỗi đứa trả 15 dòng."
→ gom 3 summaries → viết plan → implement.
Cost: 3 × 20k overhead + research. Lời khi research >60k tokens nếu làm trực tiếp.

Pattern B — Chain (chắc nhất cho task khó):
explorer → planner → (duyệt) → implementer → tester → reviewer
→ mỗi stage gate 1 lần. Chậm nhưng ít sai nhất.

Pattern C — Adversarial review (chất nhất cho PR quan trọng):
implementer (viết code) || reviewer fresh-context (review diff + plan, không biết implementer nghĩ gì)
→ reviewer không mang định kiến → bắt được lỗi implementer tự mù.

Pattern D — Isolation (sạch nhất cho task ồn):
"đọc toàn bộ logs CI 2000 dòng + tóm tắt 10 dòng" → subagent.
main chỉ nhận 10 dòng, không bao giờ thấy 2000 dòng gốc.
```

### 5.3. Cost math (tính trước khi fan-out)

```text
Công thức nhẩm:
  cost_spawn ≈ 20k tokens (system + CLAUDE.md + skills + tools defs)
  cost_task  ≈ tokens research/thực thi của agent đó
  total      ≈ N × (20k + cost_task) + cost_gom (main đọc N summaries)

Ví dụ 1 — 3 explorers song song:
  3 × (20k + 15k research) + 5k gom = ~110k tokens.
  Single-thread đọc 50 files trực tiếp: ~120k trong main (pollute main 120k).
  → Multi đắt tương đương nhưng main sạch (chỉ 5k summaries) → main còn chỗ implement.

Ví dụ 2 — Task 1 bước ("đọc file X"):
  spawn: 20k + 2k = 22k. Trực tiếp: 2k.
  → Spawn đắt 11x. ĐỪNG spawn.

Ví dụ 3 — /batch 10 subagents migrate:
  10 × (20k + 30k) = 500k. Đắt 3-4x single-thread nhưng 10 PRs song song trong 1 giờ
  vs single-thread 10 giờ. → Đắt tiền, rẻ thời gian. Đáng khi deadline dí.

Quy tắc:
- N ≤ 3-5 concurrent (trần thực tế, quá là main không gom nổi + bill nổ).
- Task <10k tokens → làm trực tiếp, đừng spawn.
- Luôn route việc dễ sang Haiku (tester → haiku, reviewer → opus).
```

```bash
# Kiểm tra bill sau fan-out (copy-paste):
# Trong session:
/usage    # breakdown: subagents ngốn bao nhiêu?
/cost     # tổng session
# Hỏi: "phân tích cost vừa rồi: spawn nào đáng, spawn nào phí?"
```

---

## 6. Walkthrough step-by-step

**Bước 1 — Tạo 4 agents (10 phút):**
Copy mục 3 vào `.claude/agents/`. Chạy `/agents` → Library phải thấy 4.

**Bước 2 — Test explorer (10 phút):**

```text
"dùng subagent explorer tìm mọi file liên quan tới [module bạn đang làm], trả summary"
# Kiểm tra: summary ≤30 dòng? Có files sẽ sửa + files tham khảo? Có lan man?
# Sửa agent file tới khi output đúng format 3 lần liên tiếp.
```

**Bước 3 — Test parallel research (10 phút):**

```text
"spawn 2 explorers song song: 1 đứa map auth flow, 1 đứa map DB schema. Gom lại cho tao."
# Quan sát /agents tab Running. Kill test: Ctrl+X Ctrl+K ×2.
```

**Bước 4 — Test chain + reviewer (15 phút):**

```text
"dùng planner viết plan cho [task], rồi dùng security-reviewer review plan đó"
# Duyệt plan. Rồi: "implement theo plan, xong dùng tester chạy focused tests"
```

### 6.1. Khi nào KHÔNG dùng subagent

- Việc chỉ là "làm theo chuẩn X" → viết **skill**, đừng spawn worker chỉ để đọc guidance.
- Task 1 bước, ít file → làm trực tiếp rẻ hơn overhead 20k.
- Muốn hỏi nhanh giữa task → `/btw` (full context, no tools, không pollute history).

| Tình huống | Chọn | Vì sao |
|---|---|---|
| "Deploy theo checklist" | Skill `/deploy` | Knowledge, không cần worker riêng |
| "Đọc file X giải thích" | Trực tiếp | 2k tokens, spawn phí 20k |
| "Hỏi nhanh giữa task" | `/btw` | Full context, no tools, no history |
| "Research 50 files" | Explorer subagent | Ồn, cần cô lập |
| "Review PR quan trọng" | Reviewer fresh-context | Không định kiến người viết |
| "Migrate 50 files" | `/batch` | Chia nhỏ + verify chéo |

### 6.2. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Spawn 10 agents → bill nổ | Không tính overhead | Trần 3-5, tính cost trước (mục 5.3) |
| Description dài → startup warning 15k | Chi tiết dồn sai chỗ | Description 1-2 câu, chi tiết vào body |
| Reviewer quá khắt (flag mọi thứ) | Không định nghĩa "finding" | Dặn "chỉ flag lỗi thực sự, đừng over-engineer" + calibration 3 diffs cũ |
| Agent sửa lung tung ngoài scope | Allowlist quá rộng | `disallowedTools: Write, Edit` cho read-only agents |
| Subagent spawn subagent vô hạn | Không giới hạn depth | Dặn "không spawn tiếp, tự làm"; kill switch Ctrl+X Ctrl+K |
| Plugin agent hooks không chạy | Bị bỏ qua theo thiết kế | Copy ra `.claude/agents/` nếu cần hooks |

### 6.3. Bài tập thực hành

**Bài 1 (20 phút):** Cài 4 agents mục 3. Test explorer + tester lên repo thật. Đo `/cost`
so với làm trực tiếp — khi nào spawn lời?

**Bài 2 (20 phút):** Chạy pattern B (chain) cho 1 task multi-file: explorer → planner → implement
→ tester. Ghi lại output mỗi stage. So với làm 1 phát không chain.

**Bài 3 (15 phút):** Chạy pattern C (adversarial): implementer viết, reviewer fresh-context review.
Đếm findings reviewer bắt được mà implementer tự miss. Tune prompt reviewer tới khi precision cao.

**Bài 4 (15 phút, cost):** Fan-out 3 explorers, ghi `/usage` + `/cost`. Tính theo công thức mục 5.3:
có đáng không? Thử lại với 1 explorer — chênh bao nhiêu?

---

## 7. Link chéo

- **Bài 00 — Tổng quan**: subagent overhead 20k, multi-agent 3-4x, trần 3-5.
- **Bài 04 — Slash commands**: `/agents /tasks /batch /btw`, foreground/background, kill switch.
- **Bài 05 — Skills**: fork skill, subagent preload skills, Explore/Plan skip CLAUDE.md.
- **Bài 07 — Hooks**: SubagentStart/Stop hooks, PreToolUse conditional rules, frontmatter hooks.
- **Bài 10 — Permissions**: permissionMode per-agent, allowlist tools.
- **Bài 11 — Worktrees**: mỗi session 1 checkout riêng, `/batch` worktree-isolated.
- **Bài 12 — SDK/CI**: Agent SDK orchestration custom, `canUseTool` callbacks.
