# 06 — Subagents, Agent Teams & Parallel Work

## 1. Vì sao cần subagent? (1 câu)

> Task phụ **đọc nhiều, ồn nhiều, không cần nhớ lâu** → ném sang subagent để main thread sạch.

Mỗi subagent: context window riêng + system prompt riêng + tool allowlist riêng + permissions riêng.
Xong việc trả về **tóm tắt**, transcript ồn ở lại bên nó.

Lợi ích: giữ context (không pollute main), enforce constraints (giới hạn tools), tái dùng cross-project
(user-level `~/.claude/agents/`), chuyên môn hóa (prompt hẹp), tiết kiệm cost (route việc dễ sang Haiku).

Giá: ~20k tokens overhead mỗi lần spawn; multi-agent tốn 3–4x single-thread (số liệu cộng đồng).
→ Chỉ spawn khi xứng đáng, trần thực tế **3–5 concurrent agents**.

## 2. So sánh 4 cách song song (chọn sai là tốn tiền)

| Cách | Ai điều phối? | Khi nào |
|---|---|---|
| **Subagents** | Claude delegate + gom kết quả trong 1 conversation | Offload research/verify, giữ main sạch |
| **Agent view** | Bạn giao việc, check lại sau | Dispatch sessions, attach khi cần |
| **Agent teams** (experimental, tắt mặc định) | Lead agent plan + assign + supervise teammates | Feature mới, debug đa giả thuyết, review song song |
| **Dynamic workflows** (`/batch`...) | Script giữ plan, bung N subagents + verify chéo | Việc lớn chia nhỏ có kiểm chứng |

Khác: `Bash` tool = 1 shell command non-blocking (không phải agent). Forked subagent = subagent kế thừa
full conversation (cách spawn, không phải surface riêng). Routine = session theo lịch trên cloud.
**Worktrees**: mỗi session 1 git checkout riêng → song song không giẫm file (`/batch`/agent view tự tạo).

## 3. Tạo custom subagent

File `.claude/agents/<ten>.md`:

```markdown
---
name: security-reviewer
description: Review code tìm lỗ hổng bảo mật. Dùng proactively khi có diff chạm auth/input/crypto.
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
```

Gọi: tự động (qua `description` khớp task) hoặc explicit: `"dùng subagent security-reviewer review diff này"`,
`--agent <ten>` (chạy cả session dưới persona đó), `--agents '{...}'` (inline JSON: `prompt` + frontmatter fields).

> Descriptions cộng dồn >15.000 tokens → warning lúc startup. Giữ `description` ngắn, chi tiết dồn vào body.

## 4. Điều khiển capabilities

- **Tools allowlist** (`tools:`) là load-bearing: ngoài list không gọi được dù prompt bảo gì.
- **Permission modes** per-agent; **preload skills** (`skills:`); **hooks riêng** trong frontmatter
  (`PreToolUse`/`PostToolUse`/`Stop`→`SubagentStop`... chỉ chạy khi agent đó active; project-level cần trust workspace dialog).
- **Conditional rules**: `PreToolUse` hook validate trước khi tool chạy (allow 1 số op, block op khác).
- **SubagentStart/Stop** hooks ở `settings.json` (matcher = tên agent; tên có `:` là regex → anchor `^...$`).
- Plugin agents bị bỏ qua `hooks`/`mcpServers`/`permissionMode` (copy ra ngoài nếu cần).

## 5. Patterns thực chiến (4 recipes)

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

## 6. Khi nào KHÔNG dùng subagent

- Việc chỉ là "làm theo chuẩn X" → viết **skill**, đừng spawn worker chỉ để đọc guidance.
- Task 1 bước, ít file → làm trực tiếp rẻ hơn overhead 20k.
- Muốn hỏi nhanh giữa task → `/btw` (full context, no tools, không pollute history).
