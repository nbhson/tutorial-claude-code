# FAQ 07 — Subagent, agent teams & quy trình làm việc

> **Bài này cho ai:** bạn đang phân vân khi nào nên tách việc sang subagent, và bối rối giữa fresh context, fork mode, agent teams, `/batch` và worktrees.
> **Cần gì trước:** đã chạy Claude Code vài session; đọc [FAQ 02](02-model-context-token.md) nếu chưa rõ overhead token.
> **Đọc xong bạn làm được:** quyết định đúng khi nào spawn subagent; phân biệt fresh/fork; chọn teams vs `/batch` vs worktrees; kill background agent loạn; chạy workflow research → implement → verify.
> **Thời gian:** ~12 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Subagent | Trợ lý con có context riêng, làm xong trả kết quả về main | "dùng subagent Explore quét auth flow, trả 10 dòng tóm tắt" |
| Main (thread) | Luồng chat chính của bạn, nơi giữ quyết định tổng | Bạn gõ prompt → main điều phối các worker |
| Fresh context | Subagent bắt đầu trắng, không thấy lịch sử chat chính | đặt `CLAUDE_CODE_FORK_SUBAGENT=0` rồi spawn |
| Fork mode | Subagent kế thừa nguyên context luồng chính, bật mặc định từ ≥2.1.232 | `CLAUDE_CODE_FORK_SUBAGENT=0` để tắt |
| `context: fork` | Khai trong frontmatter skill để skill chạy trong subagent cô lập | `context: fork` trong `SKILL.md` |
| Nested | Subagent gọi tiếp subagent con (agent đẻ agent) | trần 5 cấp (w24/2026) |
| Agent teams | Nhiều teammate + 1 lead điều phối (experimental, tắt mặc định) | lead chia feature auth cho 3 teammate |
| `/batch` | Biến 1 thay đổi lớn thành nhiều worktree + PR song song | `/batch` migrate 30 endpoints |
| Worktree | Bản checkout riêng của repo, để nhiều session không giẫm file | `git worktree add ../repo-wt/feat-auth -b feat/auth` |
| Overhead | Token tốn thêm chỉ vì công cụ, chưa tính việc thật | ~20k tokens mỗi lần spawn |

## Mục lục

- [Sơ đồ nhanh](#sơ-đồ-nhanh)
- [Bảng tổng hợp: gọi trực tiếp vs subagent vs teams vs batch](#bảng-tổng-hợp-gọi-trực-tiếp-vs-subagent-vs-teams-vs-batch)
- [1. Khi nào dùng subagent + gọi thế nào (auto/explicit/flags)?](#1-khi-nào-dùng-subagent--gọi-thế-nào-autoexplicitflags)
- [2. Subagent có thấy lịch sử chat chính không? (fresh vs forked)](#2-subagent-có-thấy-lịch-sử-chat-chính-không-fresh-vs-forked)
- [3. Skill `context: fork` là gì?](#3-skill-context-fork-là-gì)
- [4. Subagent spawn subagent (nested) — giới hạn thế nào?](#4-subagent-spawn-subagent-nested--giới-hạn-thế-nào)
- [5. Agent teams vs `/batch` — khác nhau ở đâu?](#5-agent-teams-vs-batch--khác-nhau-ở-đâu)
- [6. Theo dõi/kill background agent + worktrees chống giẫm file?](#6-theo-dõikill-background-agent--worktrees-chống-gẫm-file)
- [7. Workflow chuẩn: research song song → implement → verify?](#7-workflow-chuẩn-research-song-song--implement--verify)
- [Vẫn lỗi thì sao? (subagent/teams)](#vẫn-lỗi-thì-sao-subagentteams)

---

## Sơ đồ nhanh

```mermaid
flowchart TD
  M[Main thread<br/>giữ quyết định] --> E[Explorer<br/>chỉ đọc]
  M --> T[Tester<br/>chạy test focused]
  M --> S[Security reviewer<br/>soi auth/input]
  E --> M
  T --> M
  S --> M
```

## Bảng tổng hợp: gọi trực tiếp vs subagent vs teams vs batch

| Cách | Thấy history? | Overhead | Dùng khi nào |
|---|---|---|---|
| Làm trực tiếp (main) | Có (full) | 0 | Việc 1–3 file, 1–2 bước |
| Subagent fresh | Không (context mới + system prompt + tools riêng) | ~20k/spawn | Task phụ ồn, không cần nhớ |
| Subagent forked (mặc định ≥2.1.232) | Có (kế thừa full conversation) | ~20k + history | Tiếp mạch mà muốn cô lập rủi ro |
| Skill `context: fork` | Không | ~20k | Research ồn, trả tóm tắt |
| Nested (agent đẻ agent) | Cháu không thấy ông | Cộng dồn | Tiết chế + `maxTurns`, trần 5 cấp (w24/2026) |
| Agent teams (experimental) | Lead + teammates, supervise | Lớn | Feature lớn, debug đa giả thuyết |
| `/batch` (worktree-subagents) | Mỗi đứa 1 worktree + PR | Lớn nhưng có script giữ | Epic 5–30 PR, migrate lớn |
| Kill switch `Ctrl+X Ctrl+K` ×2 | — | — | Background chạy loạn |

> Con số gốc: **~20k overhead mỗi lần spawn, ~3–4× token khi multi-agent, trần thực tế 3–5 agent chạy song song.** Số ~20k là ước tính cộng đồng, không phải số chính thức của Anthropic.

---

## 1. Khi nào dùng subagent + gọi thế nào (auto/explicit/flags)?

> **Hỏi ngắn gọn:** Việc nào nên tách sang subagent, và gọi subagent có mấy cách?
> **Trả lời 1 câu:** Chỉ spawn khi việc vừa ỒN (đọc nhiều, chỉ cần ít) vừa ĐỘC LẬP (xong là xong); gọi bằng auto (description khớp), explicit (chỉ tên), hoặc flags `--agent`/`--agents`.

**Khi nào spawn** — hỏi 2 câu: (1) Việc có ỒN không (đọc >10 file mà chỉ cần tóm tắt)? (2) Có ĐỘC LẬP không (main không cần chi tiết)? Cả 2 Yes → subagent. Việc 1 bước ít file → main làm trực tiếp (đỡ ~20k). Việc phụ nhỏ mà không muốn cắt mạch chính → `/subtask` (≥2.1.212), nhẹ hơn cả subagent. Quy trình "làm theo từng bước" → **skill**, không phải worker.

```text
✅ Subagent: "quét 50 files auth, trả 10 dòng + 5 file chính"
❌ Trực tiếp rẻ hơn: "sửa 2 dòng file login.ts"
❌ Dùng skill: "deploy theo 12 bước chuẩn" (quy trình, không phải worker)
```

**Ba cách gọi:**

1. **Auto:** description khớp task → model tự spawn (cần description rõ, xem [FAQ 02 câu 4](02-model-context-token.md#4-subagent-tốn-bao-nhiều-token-overhead--trần-15k-descriptions)).
2. **Explicit:** bạn chỉ tên trong prompt — "dùng subagent security-reviewer soi diff này". Chắc ăn nhất.
3. **Flags:** `--agent <tên>` (ép cả session) và `--agents '{...}'` (inline JSON, khỏi tạo file — hợp CI/script chạy 1 lần).

```bash
claude --agent explore "quét auth flow"
claude --agents '{"reviewer":{"description":"review PR","tools":["Read","Grep","Glob"]}}' -p "review diff"
```

**Đào sâu:** [Bài 06 — subagent & agent teams](../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md) · [FAQ 02 — overhead token](02-model-context-token.md) · [lệnh `agents`](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md)

---

## 2. Subagent có thấy lịch sử chat chính không? (fresh vs forked)

> **Hỏi ngắn gọn:** Subagent có "nhớ" được chat mình đang làm không, hay phải giải thích lại từ đầu?
> **Trả lời 1 câu:** Từ ≥2.1.232 fork mode bật mặc định nên subagent kế thừa nguyên context của main; muốn bản thật sự trắng thì tắt bằng `CLAUDE_CODE_FORK_SUBAGENT=0`.

"Forked" là *cách spawn* (worker nhận full conversation), không phải surface riêng — đừng tìm nút "fork" trong UI.

```text
Fresh (đặt CLAUDE_CODE_FORK_SUBAGENT=0):  main 100 turns → subagent thấy 0 (sạch, rẻ, an toàn)
Forked (mặc định ≥2.1.232):              main 100 turns → subagent thấy 100 (hiểu mạch, đắt, dễ loãng)
```

```bash
export CLAUDE_CODE_FORK_SUBAGENT=0
# spawn subagent reviewer với câu hỏi nó CHƯA biết:
# "Review diff này, chỉ báo điểm security + bug"
# → reviewer không nhắc lại reasoning cũ của main = chạy đúng fresh
```

Research độc lập → fresh; tiếp mạch dở dang mà sợ làm bẩn main → forked (mặc định). Ví dụ: cần reviewer "mắt mới" cho diff → đặt `CLAUDE_CODE_FORK_SUBAGENT=0` rồi mới spawn, nếu không reviewer thấy luôn reasoning của người viết và dễ gật theo.

**Đào sâu:** [lệnh `fork`](../01-huong-dan-su-dung/commands/session-context/fork/README.md) · [FAQ 06 — `context: fork`](06-skills-commands-claude-md.md)

---

## 3. Skill `context: fork` là gì?

> **Hỏi ngắn gọn:** Dòng `context: fork` trong skill nghĩa là gì, khác subagent thường thế nào?
> **Trả lời 1 câu:** Skill gắn `context: fork` chạy trong subagent cô lập (không thấy history) — hợp việc research đọc nhiều trả ít; chạy background mặc định từ v2.1.218 (đặt `background: false` trong `SKILL.md` nếu muốn chờ trong turn).

Agent `Explore`/`Plan` khi fork còn skip CLAUDE.md + git status để gọn tối đa.

```markdown
---
name: explore-auth
description: Quét auth flow trả tóm tắt. Dùng khi cần hiểu auth mà không loãng context.
context: fork
agent: Explore
model: haiku
---
1. Quét, không sửa.
2. Trả: 10 dòng tóm tắt + 5 file chính + 3 hàm entry.
```

```bash
/explore-auth
# → subagent chạy riêng, main nhận ~15 dòng tóm tắt
# → context chính không bị phình bằng log quét 50 files
```

Skill quét/audit/khảo sát → fork; skill viết tiếp mạch → không fork. Chi tiết frontmatter xem [FAQ 06 câu 7](06-skills-commands-claude-md.md#7-context-fork-là-gì).

**Đào sâu:** [FAQ 06 — `context: fork`](06-skills-commands-claude-md.md) · [Bài 05 — skills](../01-huong-dan-su-dung/05-skills-custom-commands.md)

---

## 4. Subagent spawn subagent (nested) — giới hạn thế nào?

> **Hỏi ngắn gọn:** Subagent có được quyền tự sinh subagent con không, sâu nhất được bao nhiêu cấp?
> **Trả lời 1 câu:** Được, nhưng token CỘNG DỒN — depth mặc định 3, trần tối đa 5 cấp (w24/2026); hạ về 1 bằng `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`.

Không giới hạn → cháy bill + loãng. Quy tắc thực dụng: tiết chế, luôn đặt `maxTurns`, dặn con "không tự đẻ thêm". Từ ≥2.1.296, frontmatter subagent khai được `autoCompactWindow` để subagent tự compact sớm hơn cửa sổ chính — hữu ích cho agent research chạy dài.

```text
main → con (Explore, maxTurns 10) → hết. Con không đẻ cháu.
❌ main → con → cháu → chắt (bill ×4, không ai đọc hết output)
```

```markdown
---
name: researcher
description: Research độc lập, không đẻ thêm agents.
tools: Read, Glob, Grep
maxTurns: 10
---
1. Chỉ đọc, không sửa.
2. KHÔNG spawn thêm subagents.
3. Trả tối đa 20 dòng.
```

Check agent file đã chặn nested chưa: `git grep -n 'maxTurns\|KHÔNG spawn' -- .claude/agents/` → mọi agent đều có `maxTurns`.

**Đào sâu:** [Bài 06 — nested agents](../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md) · [FAQ 02 — token](02-model-context-token.md)

---

## 5. Agent teams vs `/batch` — khác nhau ở đâu?

> **Hỏi ngắn gọn:** Agent teams và `/batch` nghe giống nhau — chọn cái nào?
> **Trả lời 1 câu:** Teams để lead supervise linh hoạt (model giữ plan); `/batch` dùng script + worktree để mỗi worker ôm 1 PR riêng — khác ở cơ chế giữ mạch.

Agent teams: **lead plan + assign + supervise teammates** (experimental, tắt mặc định — phải bật mới có). Hợp cho feature lớn đa mảng, debug đa giả thuyết song song, review song song. Task 1 người làm 30 phút xong thì teams overhead lớn — chỉ đáng khi việc đủ lớn để chia, chấp nhận token ~3–4× (xem [FAQ 02 câu 4](02-model-context-token.md#4-subagent-tốn-bao-nhiều-token-overhead--trần-15k-descriptions)).

| | Agent teams | `/batch` |
|---|---|---|
| Giữ plan bằng | Lead supervise (model) | Script + worktree-subagents |
| Mỗi worker | Task trong session | 1 worktree + 1 PR riêng |
| Verify | Lead check | Verify chéo giữa workers |
| Quy mô | Vài teammates | 5–30 worktree-subagents |
| Dùng khi | Feature lớn cần supervise linh hoạt | Epic/migrate chia PR được |

```bash
# /batch: 1 change lớn → N PR
/batch
# → chia epic thành 5-30 worktree-subagents, mỗi đứa 1 PR, verify chéo
# → kiểm tra: git worktree list hiện mỗi PR một checkout riêng
```

Migrate 30 endpoints → `/batch` (mỗi endpoint 1 PR, review từng cái). Thiết kế lại auth (cần lead điều phối linh hoạt) → teams. Refactor 1 module nhỏ → đừng bật teams, main làm nhanh hơn.

**Đào sâu:** [Bài 06 — agent teams](../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md) · [lệnh `batch`](../01-huong-dan-su-dung/commands/code-repo/batch/README.md)

---

## 6. Theo dõi/kill background agent + worktrees chống giẫm file?

> **Hỏi ngắn gọn:** Spawn nhiều agent chạy nền không kiểm soát nổi, nhiều agent cùng sửa code thì làm sao?
> **Trả lời 1 câu:** Xem bằng `/agents` + `/tasks`, tắt tất cả bằng `Ctrl+X Ctrl+K` ×2 trong 3s; cứ >1 agent chạm code cùng lúc → mỗi session 1 worktree.

**Theo dõi & kill** — agents chạy nền cần quản lý như process:

```bash
/agents    # Running (đang chạy) + Library (có gì)
/tasks     # tasks đang chạy
```

Kill switch: `Ctrl+X Ctrl+K` **×2 trong 3s** → kill all background. Dấu hiệu kill: 3 agents cùng sửa 1 file / bill tăng mà không ra gì / output lạ → kill không tiếc, `/tasks` xác nhận sạch, spawn lại với scope hẹp hơn. Mỗi khi spawn >2 background → mở `/tasks` để mắt.

**Worktrees** — 3 agents cùng sửa 1 checkout → conflict. Fix: mỗi session 1 worktree (agent view/`/batch` tự tạo; làm tay thì):

```bash
git worktree add ../myrepo-worktrees/feat-auth -b feat/auth
git worktree list
# → thấy 2 dòng: checkout gốc + ../myrepo-worktrees/feat-auth (feature riêng)
git worktree remove ../myrepo-worktrees/feat-auth   # xong việc
```

VD: 3 việc song song — auth (worktree 1), payment (worktree 2), docs (worktree 3) → merge từng cái, không giẫm. 1 agent đọc-only → khỏi.

**Đào sâu:** [lệnh `tasks`](../01-huong-dan-su-dung/commands/session-context/tasks/README.md) · [Bài 11 — worktrees](../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md) · [lệnh `branch`](../01-huong-dan-su-dung/commands/session-context/branch/README.md)

---

## 7. Workflow chuẩn: research song song → implement → verify?

> **Hỏi ngắn gọn:** Làm một feature vừa-to thì nên chia phase theo thứ tự nào?
> **Trả lời 1 câu:** Công thức team hay dùng: research song song (rẻ) → implement ở main → verify bằng fresh-reviewer + `/verify`.

```text
Phase 1 — Research song song (Haiku, fresh, worktree riêng nếu cần):
  agent A: quét auth · agent B: quét payment · agent C: quét tests
  → mỗi đứa trả 15 dòng
Phase 2 — Implement (Sonnet, main): gắt từng file theo tóm tắt
Phase 3 — Verify (Opus): fresh-reviewer + /verify (chạy app thật) + tests xanh
```

```bash
# Phase 1: 3 research song song (rẻ)
/model haiku
# Phase 2: implement
/model sonnet
# Phase 3: review khó
/model opus
/verify
# → verify PASS + tests xanh = feature thực sự xong, không phải "model nói xong"
```

Muốn ép mọi workflow agent chạy chung một model thì đặt `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL=<model>` (≥2.1.296) thay vì sửa từng agent file. Chi tiết verify xem [Bài tips 04 — verification](../02-tips-thuc-chien/04-verification-done-that.md).

**Đào sâu:** [Bài tips 05 — parallel agents](../02-tips-thuc-chien/05-parallel-agents.md) · [lệnh `verify`](../01-huong-dan-su-dung/commands/code-repo/verify/README.md)

---

## Vẫn lỗi thì sao? (subagent/teams)

1. Subagent không trigger → description quá dài/mờ (xem [FAQ 02 câu 4](02-model-context-token.md#4-subagent-tốn-bao-nhiều-token-overhead--trần-15k-descriptions)) + `/agents` check library.
2. Kẹt deny headless → allowlist + `allowed-tools` (xem [FAQ 03 câu 5](03-permissions-modes.md#5-headless--p-bị-deny-hàng-loạt--fix--allowlist-thế-nào)).
3. Bill tăng → `/usage` xem subagent nào ngốn + `/tasks` kill thừa.
4. Giẫm file → worktrees (câu 6).
5. `/debug` → chẩn đoán; `/bug` nếu nghi core.

```bash
/agents
/tasks
/usage
```

---

**Tham khảo chéo:** [Bài 06 — subagent & agent teams](../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md) · [Bài 11 — worktrees & checkpoints](../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md) · [Bài tips 05 — parallel agents](../02-tips-thuc-chien/05-parallel-agents.md) · [Bài tips 04 — verification](../02-tips-thuc-chien/04-verification-done-that.md) · [FAQ 02](02-model-context-token.md) (overhead) · [FAQ 03](03-permissions-modes.md) (headless deny) · [FAQ 06](06-skills-commands-claude-md.md) (fork skill)

> Mẹo 1 dòng: _ồn + độc lập thì spawn, không thì main làm — và cứ >1 đứa chạm code là mỗi đứa 1 worktree._
