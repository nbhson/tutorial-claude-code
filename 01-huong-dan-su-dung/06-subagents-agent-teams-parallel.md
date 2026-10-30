# 06 — Subagents, agent teams và chạy song song

> **Bài này cho ai:** bạn đang giao việc cho Claude mà context nhanh đầy, muốn tách bớt việc ồn sang worker riêng và biết lúc nào thì đừng tách.
> **Cần gì trước:** đã cài và đăng nhập (bài 01); nên đọc [05-skills-custom-commands.md](./05-skills-custom-commands.md) để phân biệt skill với subagent.
> **Đọc xong bạn làm được:** chọn đúng 1 trong 4 cách chạy song song; cài 4 agent mẫu (`explorer`, `planner`, `security-reviewer`, `tester`); tính chi phí 1 lần spawn trước khi chia việc; kể được 4 mẫu điều phối.
> **Thời gian:** ~35 phút đọc + ~45 phút walkthrough

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Subagent (worker) | Trợ lý con có bộ nhớ riêng, làm xong trả tóm tắt 10–30 dòng | Explorer đọc 50 file, luồng chính chỉ nhận danh sách file |
| Chi phí spawn | Tokens nạp sẵn mỗi lần mở worker (system prompt + CLAUDE.md + tools) | ~20k tokens — **ước tính cộng đồng**, không phải số chính thức |
| Agent view (`claude agents` / `/agents`) | Màn hình danh sách mọi session đang chạy (w20/2026) — bạn giao việc rồi check sau | 3 session song song 3 feature, tab Running |
| Agent teams | Lead + teammates phối hợp (experimental, tắt mặc định) | Bật `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (≥2.1.32) |
| Fork | Chạy trong bộ nhớ riêng, không dính lịch sử chính | Fork skill chạy nền từ v2.1.218; fork mode cho subagent hưởng nguyên context luồng chính từ ≥2.1.232 (tắt `CLAUDE_CODE_FORK_SUBAGENT=0`) |
| Worktree | Mỗi session 1 bản sao repo riêng, không giẫm chân | `/batch` tự tạo (bài 11) |
| `/batch` | Chạy nền 1 loạt việc theo plan, kiểm tra chéo giữa các worker | Migrate 50 files → 10 PRs |
| Explore / Plan | 2 agent có sẵn: 1 chỉ đọc, 1 chỉ lên kế hoạch | Khi chạy qua 2 agent này, CLAUDE.md project bị bỏ qua |

## Mục lục

1. [Vì sao cần subagent?](#1-vì-sao-cần-subagent)
2. [4 cách chạy song song — chọn sai là tốn tiền](#2-4-cách-chạy-song-song--chọn-sai-là-tốn-tiền)
3. [4 file agent mẫu (copy-paste)](#3-4-file-agent-mẫu-copy-paste)
4. [Giới hạn worker được làm gì](#4-giới-hạn-worker-được-làm-gì)
5. [Mẫu điều phối + cách tính chi phí](#5-mẫu-điều-phối--cách-tính-chi-phí)
6. [Walkthrough 45 phút + khi nào KHÔNG dùng](#6-walkthrough-45-phút--khi-nào-không-dùng)
7. [Bẫy, hiểu nhầm, bài tập, link](#7-bẫy-hiểu-nhầm-bài-tập-link)

---

## 1. Vì sao cần subagent?

**Nôm na 1 câu:** Subagent là *đệ tử đi chợ hộ* — việc đọc nhiều ồn nhiều (50 files, 2000 dòng log) sai đệ đi, bạn ở nhà chỉ nhận tờ giấy tóm tắt 10 dòng.

```text
# Gọi nhanh không cần file:
"dùng subagent explorer tìm mọi file liên quan tới POST /login rate-limit, trả tóm tắt ≤30 dòng"
```

**Cơ chế:** spawn worker = mở conversation mới với system prompt agent + CLAUDE.md project (trừ Explore/Plan) + skills nạp sẵn + tool defs — tất cả nạp trước khi đọc dòng code đầu tiên (~20k overhead, ước tính cộng đồng). Task 1 bước ("đọc file X" = 2k tokens) mà spawn = trả 20k để làm việc 2k. Task research 50 files = trả 20k để tiết kiệm 100k trong luồng chính → lời.

- **Lợi ích:** giữ context luồng chính sạch, ép đúng toolset/quyền, tái dùng cross-project (`~/.claude/agents/`), chuyên môn hóa, việc dễ giao Haiku.
- **Chi phí:** nhiều worker tốn 3–4x single-thread (số liệu cộng đồng) → trần thực tế **3–5 worker song song**.
- Từ w27/2026, **subagents chạy background mặc định** — spawn xong làm việc khác được, check bằng `/tasks` (hoặc `/agents`), dừng bằng `Ctrl+X Ctrl+K ×2`.

---

## 2. 4 cách chạy song song — chọn sai là tốn tiền

| Cách | Ai điều phối? | Khi nào | Ví dụ |
|---|---|---|---|
| **Subagents** | Claude tự chia + gom trong 1 conversation | Đẩy research/kiểm chứng sang worker, giữ luồng chính sạch | "Nghiên cứu module auth, trả tóm tắt" |
| **Agent view** | Bạn giao việc, check lại sau | Nhiều session độc lập, attach khi cần | 3 sessions song song 3 features |
| **Agent teams** (experimental, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) | Lead lập kế hoạch, giao việc, giám sát | Feature mới, debug đa giả thuyết, review song song | Lead + 3 teammates (security/perf/tests) |
| **Dynamic workflows** (`/batch`...) | Script giữ plan, bung N worker + kiểm tra chéo | Việc lớn chia nhỏ có kiểm chứng | Migrate 50 files → 10 PRs |

Bảng quyết định 30 giây:

```text
Task ồn nhưng cần gom về 1 quyết định?        → Subagents (Claude tự chia)
Muốn tự tay giao + check từng đứa?            → Agent view (/agents tab Running)
Task lớn, chia nhỏ có kiểm tra chéo?          → /batch
Muốn nhiều góc nhìn độc lập cùng lúc?         → Agent teams
Chỉ là "làm theo chuẩn X"?                    → Skill, đừng tạo worker (bài 05)
Hỏi nhanh giữa task?                          → /btw (bài 04)
```

Đừng nhầm: `Bash` tool = 1 lệnh shell không chặn (không phải agent); worker từ fork = cách tạo kế thừa conversation, không phải bề mặt riêng; routine = session theo lịch trên cloud. Chạy nhiều session độc lập mà cần trao đổi trực tiếp → cross-session messaging + `@` mention session khác (macOS/Linux, w32-33/2026).

---

## 3. 4 file agent mẫu (copy-paste)

> Đặt vào `.claude/agents/<ten>.md` (project) hoặc `~/.claude/agents/` (personal). Gọi: tự động qua `description`, hoặc tường minh `"dùng subagent X làm Y"`.

### 3.1. Agent 1 — Explorer (nghiên cứu chỉ đọc)

```markdown
---
name: explorer
description: Nghiên cứu codebase chỉ đọc, trả tóm tắt gọn. Dùng chủ động khi cần tìm files liên quan, hiểu module, map dependencies trước khi sửa.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit, NotebookEdit
model: sonnet
permissionMode: plan
maxTurns: 25
---

Bạn là explorer. Chỉ đọc, KHÔNG sửa. Quy trình: Glob (tên file) → Grep (nội dung)
→ Read top 5-10 files (file dài đọc theo offset/limit). Mỗi file ghi 1 dòng
(path + vai trò + có cần sửa không).

Output (bắt buộc, tối đa 30 dòng):
- **Files sẽ sửa**: path + 1 câu vì sao
- **Files chỉ đọc tham khảo**: path + 1 câu
- **Rủi ro**: chỗ nào dễ vỡ nếu sửa
Cấm: lan man, dán cả file vào báo cáo, đề xuất refactor ngoài phạm vi.
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
---

Bạn là planner. Viết plan vào `plans/<YYYYMMDD>-<ten-task>.md` theo khung:
Goals (đo được) / Non-goals / Files (sửa gì, thêm gì) / Steps (từng bước + lệnh
kiểm chứng sau mỗi bước) / Risks (chỗ dễ vỡ + rollback).
Trình plan + tóm tắt 10 dòng, chờ duyệt. Không tự implement.
```

### 3.3. Agent 3 — Security reviewer (chỉ đọc + git diff)

```markdown
---
name: security-reviewer
description: Review code tìm lỗ hổng bảo mật. Dùng chủ động khi có diff chạm auth/input/crypto/payment.
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
model: opus
permissionMode: plan
skills: secure-coding-guide
memory: project
maxTurns: 20
---

Bạn là security reviewer. Chỉ đọc, không sửa.
1. `git diff main...HEAD --stat` → phạm vi (diff >20 files → review theo lô).
2. Đọc từng file + test kèm. Check OWASP: injection, broken access control,
   secrets hardcode, crypto yếu, SSRF, mass assignment, rate-limit thiếu.
3. Calibration: so với 3 diffs lịch sử repo để bớt dễ dãi/khắt khe.
Output: tối đa 10 findings `[CRITICAL|HIGH|MED|LOW] file:line — mô tả — fix`.
Không finding → nói rõ "đã check X, Y, Z" (đừng im lặng).
```

### 3.4. Agent 4 — Tester (chạy test, báo pass/fail)

```markdown
---
name: tester
description: Chạy tests liên quan, báo pass/fail + đoán nguyên nhân gốc. Dùng sau mỗi thay đổi để kiểm chứng.
tools: Read, Bash
disallowedTools: Write, Edit
model: haiku
maxTurns: 15
---

Bạn là tester. Đọc CLAUDE.md lấy lệnh focused test; chạy focused trước, full chỉ
khi được yêu cầu. Test flaky → ghi "FLAKY" + dừng đoán, không argue.
Output: `PASS (n/n)` hoặc `FAIL (x/y)` + tối đa 10 dòng log quan trọng + đoán
nguyên nhân 1 dòng (ghi rõ là đoán) + lệnh đã chạy để luồng chính reproduce.
```

> Mô tả cộng dồn các agent vượt 15.000 tokens sẽ bị cảnh báo lúc khởi động — giữ `description` ngắn, chi tiết dồn vào body. Chạy cả session dưới 1 persona: `claude --agent explorer "tìm mọi file liên quan tới billing"`; khai agent inline JSON không cần file: `claude --agents '{"quick-review":{"prompt":"...","tools":["Read","Grep"]}}'`.

---

## 4. Giới hạn worker được làm gì

- **`tools:`** là then chốt — ngoài list không gọi được dù prompt dụ gì. Kèm `disallowedTools: Write, Edit` cho agent chỉ đọc + `permissionMode: plan` làm lớp dự phòng.
- **Hooks riêng trong frontmatter** (`PreToolUse`/`PostToolUse`/`Stop`→`SubagentStop`...) chỉ chạy khi agent đó active; project-level cần trust workspace dialog. `SubagentStart/Stop` ở settings.json, matcher = tên agent (tên có `:` là regex → anchor `^...$`).
- **Conditional rules**: PreToolUse hook chỉ cho Bash matching `pnpm *test*|pytest*|go test*`, block `rm|push|deploy` (bài 07).
- **Skill nạp sẵn** (`skills: secure-coding-guide`) — knowledge chuẩn team không cần paste vào prompt.
- Lưu ý: plugin agents bị bỏ qua `hooks`/`mcpServers`/`permissionMode` — copy ra `.claude/agents/` nếu cần.

Cấu hình nâng cao: subagent spawn subagent — giới hạn depth mặc định **3**, trần tối đa **5 cấp** (w24/2026); hạ về 1 bằng `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`; ngoài ra có giới hạn số worker song song. Tự compact sớm: `autoCompactWindow` trong frontmatter (≥2.1.296). Ép workflow agent chạy 1 model: `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` (≥2.1.296). Hiện text của worker ở luồng chính: `--forward-subagent-text`.

---

## 5. Mẫu điều phối + cách tính chi phí

### 4 mẫu điều phối

```text
A — Nghiên cứu song song (nhanh nhất cho task mới):
    "tạo 3 explorers song song: (1) auth flow, (2) DB schema, (3) API routes. Mỗi explorer trả 15 dòng."
    → gom 3 bản tóm tắt → viết plan → triển khai.

B — Chuỗi (chắc nhất cho task khó):
    explorer → planner → (duyệt) → implementer → tester → reviewer. Chậm nhưng ít sai nhất.

C — Review phản biện (chất nhất cho PR quan trọng):
    implementer viết code || reviewer ngữ cảnh mới review diff + plan (không biết implementer nghĩ gì)
    → reviewer không mang định kiến. Dùng /code-review hoặc prompt tự viết;
    reviewer quá khắt → dặn "chỉ đánh dấu lỗi thực sự, đừng thổi phồng".

D — Cô lập (sạch nhất cho task ồn):
    "đọc toàn bộ logs CI 2000 dòng + tóm tắt 10 dòng" → luồng chính chỉ nhận 10 dòng.
```

### Cách tính chi phí trước khi chia việc

```text
chi_phi ≈ N × (20k spawn + tokens_viec) + tokens_gom (luồng chính đọc N tóm tắt)

Ví dụ 1 — 3 explorers song song: 3 × (20k + 15k) + 5k ≈ 110k.
  Làm một luồng: ~120k nằm phình trong luồng chính → song song đắt tương đương
  nhưng luồng chính sạch (chỉ 5k tóm tắt).

Ví dụ 2 — Task 1 bước ("đọc file X"): spawn 22k vs trực tiếp 2k → ĐỪNG spawn.

Ví dụ 3 — /batch 10 subagents migrate: 10 × (20k + 30k) = 500k, đắt 3-4x
  nhưng 10 PRs song song trong 1 giờ vs 10 giờ một luồng → đắt tiền, rẻ thời gian.

Quy tắc: N ≤ 3-5 worker cùng lúc; task <10k tokens → làm trực tiếp;
việc dễ giao Haiku (tester → haiku, reviewer → opus).
```

```bash
# Kiểm tra bill sau khi chia việc:
/usage    # breakdown subagents ngốn bao nhiêu
/cost     # tổng session
# Hỏi: "phân tích cost vừa rồi: lần spawn nào đáng, lần nào phí?"
```

---

## 6. Walkthrough 45 phút + khi nào KHÔNG dùng

**Walkthrough:**

1. (10') Copy mục 3 vào `.claude/agents/` → `/agents` tab Library thấy đủ 4.
2. (10') `"dùng subagent explorer tìm mọi file liên quan tới [module], trả tóm tắt"` → output ≤30 dòng đúng khung; chưa đúng → sửa agent file lặp tới khi 3 lần liên tiếp ra đúng định dạng.
3. (10') `"tạo 2 explorers song song: 1 map auth flow, 1 map DB schema. Gom lại."` → `/agents` tab Running thấy 2 worker; kill test `Ctrl+X Ctrl+K ×2`.
4. (15') `"dùng planner viết plan cho [task], rồi dùng security-reviewer review plan đó"` → duyệt → `"implement theo plan, xong dùng tester chạy focused tests"` → tester báo `PASS (n/n)` + lệnh chạy.

**Khi nào KHÔNG dùng subagent:**

| Tình huống | Chọn | Vì sao |
|---|---|---|
| "Deploy theo checklist" | Skill `/deploy` | Knowledge, không cần worker riêng |
| "Đọc file X giải thích" | Trực tiếp | 2k tokens, spawn phí 20k |
| "Hỏi nhanh giữa task" | `/btw` | Đủ context, không tool, không lưu history |
| "Research 50 files" | Explorer subagent | Ồn, cần cô lập |
| "Review PR quan trọng" | Reviewer ngữ cảnh mới | Không định kiến người viết |
| "Migrate 50 files" | `/batch` | Chia nhỏ + kiểm tra chéo |

---

## 7. Bẫy, hiểu nhầm, bài tập, link

### Bẫy + fix

| Bẫy | Fix |
|---|---|
| Tạo 10 agent một lần → bill nổ | Trần 3-5, tính chi phí trước (mục 5) |
| Mô tả dài → cảnh báo 15k lúc khởi động | Mô tả 1-2 câu, chi tiết vào body |
| Reviewer quá khắt (đánh dấu mọi thứ) | Định nghĩa "finding"; dặn đừng thổi phồng; làm chuẩn bằng 3 diffs cũ |
| Agent sửa lung tung ngoài phạm vi | `disallowedTools: Write, Edit` cho agent chỉ đọc |
| Worker tạo worker không điểm dừng | Depth mặc định 3 / trần 5 (w24/2026), hạ `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`; dặn "không spawn tiếp, tự làm" |
| Plugin agent hooks không chạy | Bị bỏ qua theo thiết kế — copy ra `.claude/agents/` |

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| "Subagent nhớ mọi thứ luồng chính biết" | Mỗi subagent có context riêng khi spawn; từ ≥2.1.232 fork mode bật mặc định nên hưởng nguyên context luồng chính (tắt `CLAUDE_CODE_FORK_SUBAGENT=0`). Muốn worker biết gì vẫn ghi rõ trong prompt |
| "Càng nhiều agent càng nhanh" | ~20k/spawn, 3–4x tổng; trần 3–5 — quá là luồng chính gom không nổi + bill nổ |
| "Agent Teams bật mặc định" | Experimental, tắt mặc định — bật `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| "Việc gì cũng nên tạo worker" | Chuẩn X → Skill; hỏi nhanh → `/btw`; đọc 1 file → trực tiếp. Chỉ spawn khi ồn + cần cô lập |

### Bài tập

1. (20') Cài 4 agents; test explorer + tester trên repo thật; đo `/cost` so với làm trực tiếp.
2. (20') Mẫu B (chuỗi) cho 1 task multi-file: explorer → planner → implement → tester; ghi output từng chặng.
3. (15') Mẫu C (phản biện): đếm findings reviewer bắt được mà implementer miss; sửa prompt reviewer.
4. (15', cost) Tạo 3 explorers song song, ghi `/usage` + `/cost`; so với 1 explorer — kết luận task nào của team nên spawn, task nào không.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: chi phí spawn, trần 3-5; **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/agents /tasks /batch /btw /fork`, cách dừng worker.
- **[05 — Skills](./05-skills-custom-commands.md)**: fork skill, subagent nạp sẵn skill; **[07 — Hooks](./07-hooks-tu-dong-hoa.md)**: SubagentStart/Stop hooks, conditional rules.
- **[10 — Permissions](./10-permissions-modes-availability.md)**: permissionMode per-agent; **[11 — Worktrees](./11-git-worktrees-checkpoints.md)**: mỗi session 1 checkout riêng; **[12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md)**: tự viết orchestration bằng Agent SDK.
