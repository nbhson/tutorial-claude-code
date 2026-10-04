# FAQ 07 — Subagents, Agent Teams & Workflows

> Nhóm Parallel & Workflows · 10 câu hỏi deep-dive · Đọc xong biết khi nào spawn, fresh vs fork, teams vs batch, worktrees không giẫm file

Mỗi câu có giải thích + lệnh/config copy-paste + ví dụ + khi nào áp dụng. Nhớ con số gốc: **~20k overhead/spawn, ~3–4x multi-agent, trần 3–5 concurrent.**

---

## Bảng tổng hợp: gọi trực tiếp vs subagent vs teams vs batch

| Cách | Thấy history? | Overhead | Dùng khi nào |
|---|---|---|---|
| Làm trực tiếp (main) | Có (full) | 0 | Việc 1-3 files, 1-2 bước |
| Subagent fresh (mặc định) | Không (context mới + system prompt + tools riêng) | ~20k/spawn | Task phụ ồn, không cần nhớ |
| Forked subagent | Có (kế thừa full conversation) | ~20k + history | Tiếp mạch mà muốn cô lập rủi ro |
| Skill `context: fork` | Không | ~20k | Research ồn, trả tóm tắt |
| 3 cách gọi: auto / explicit / flags | Tùy loại | Tùy | Auto (khớp desc), explicit (chỉ tên), flags (ép cả session) |
| Nested (agent đẻ agent) | Cháu không thấy ông | Cộng dồn | Tiết chế + `maxTurns` |
| Agent teams (experimental) | Lead + teammates, supervise | Lớn | Feature lớn, debug đa giả thuyết |
| `/batch` (worktree-subagents) | Mỗi đứa 1 worktree + PR | Lớn nhưng có script giữ | Epic 5–30 PR, migrate lớn |
| Kill switch `Ctrl+X Ctrl+K` ×2 | — | — | Background chạy loạn |

---

## 1. Khi nào dùng subagent vs làm trực tiếp? (~20k đáng không?)

**Giải thích.** Hỏi 2 câu: (1) Việc có ỒN không (đọc >10 files mà chỉ cần tóm tắt)? (2) Có ĐỘC LẬP không (xong việc là xong, main không cần chi tiết)? Cả 2 Yes → subagent. Việc 1 bước ít file → trực tiếp (đỡ ~20k). Chuẩn "làm theo từng bước" → **skill**, không phải worker.

```text
✅ Subagent: "quét 50 files auth, trả 10 dòng + 5 file chính"
❌ Trực tiếp rẻ hơn: "sửa 2 dòng file login.ts"
❌ Dùng skill: "deploy theo 12 bước chuẩn" (quy trình, không phải worker)
```

**Lệnh copy-paste (explicit):**

```bash
# Trong session: chỉ tên + việc + output mong muốn
# "Dùng subagent Explore quét auth flow, trả về 10 dòng tóm tắt + 5 file chính"
```

**Khi nào áp dụng:** trước mỗi spawn — việc không đủ ồn/độc lập thì main làm, 20k để dành.

---

## 2. Subagent có thấy history không? (fresh mặc định vs forked)

**Giải thích.** Mặc định **fresh**: context mới + system prompt + tools riêng, KHÔNG thấy history main. Muốn nó thấy → **forked**: kế thừa full conversation (đây là *cách spawn*, không phải surface riêng — đừng tìm nút "fork" trong UI).

```text
Fresh (mặc định):  main 100 turns → subagent thấy 0 (sạch, rẻ, an toàn)
Forked:           main 100 turns → subagent thấy 100 (hiểu mạch, đắt, dễ loãng)
Skill fork:       Explore/Plan khi fork còn skip CLAUDE.md + git status (gọn hơn nữa)
```

**Khi nào áp dụng:** research độc lập → fresh. Tiếp mạch dở dang mà sợ làm bẩn main → forked. Mặc định luôn là fresh trừ khi bạn chủ ý fork.

---

## 3. Skill `context: fork` là gì? (research ồn → cô lập)

**Giải thích.** Skill gắn `context: fork` chạy trong subagent cô lập (không thấy history). Agent `Explore`/`Plan` khi fork còn skip CLAUDE.md + git status để gọn tối đa. Hợp cho skill đọc nhiều-trả ít.

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

**Ví dụ:** main đang implement dở (context 60%), cần hiểu thêm payment flow → gọi skill fork → main vẫn sạch, nhận tóm tắt 15 dòng.

**Khi nào áp dụng:** skill quét/audit/khảo sát → fork. Skill viết tiếp mạch → không fork.

---

## 4. 3 cách gọi subagent: auto / explicit / flags (`--agent`, `--agents`)?

**Giải thích.**

1. **Tự động (auto):** description khớp task → model tự spawn. Cần description rõ (xem FAQ 02 câu 4).
2. **Explicit:** bạn chỉ tên trong prompt — "dùng subagent X làm Y". Chắc ăn nhất.
3. **Flags:** `--agent <tên>` (ép cả session dùng agent đó) và `--agents '{...}'` (inline JSON định nghĩa agent tại chỗ, khỏi tạo file).

**Lệnh copy-paste:**

```bash
# 1. Auto: chỉ mô tả việc, model tự chọn
# "quét codebase tìm chỗ xử lý retry"

# 2. Explicit: chỉ tên
# "dùng subagent security-reviewer soi diff này"

# 3. Flags (ngoài terminal):
claude --agent explore "quét auth flow"
claude --agents '{"reviewer":{"description":"review PR","tools":["Read","Grep","Glob"]}}' -p "review diff"
```

**Khi nào áp dụng:** hàng ngày → auto + explicit. CI/script 1 lần → `--agents` inline (khỏi tạo file rác).

---

## 5. Subagent spawn subagent (nested) — giới hạn sao?

**Giải thích.** Được, nhưng token CỘNG DỒN (cháu 20k + con 20k + main...). Không giới hạn → cháy bill + loãng. Quy tắc: nested tối đa 1 tầng, luôn đặt `maxTurns`, dặn con "không tự đẻ thêm".

```text
main → con (Explore, maxTurns 10) → hết. Con không đẻ cháu.
❌ main → con → cháu → chắt (bill ×4, không ai đọc hết output)
```

**Config copy-paste (agent file):**

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

**Khi nào áp dụng:** mọi agent file team dùng chung — luôn có `maxTurns` + "trả tối đa N dòng".

---

## 6. Agent teams là gì? (lead + teammates, experimental, tắt mặc định)

**Giải thích.** Agent teams: **lead plan + assign + supervise teammates** (experimental, tắt mặc định — phải bật mới có). Hợp cho: feature lớn đa mảng, debug đa giả thuyết song song, review song song (security/perf/tests mỗi đứa 1 góc).

```text
Lead: chia feature auth thành 3 mảnh → assign 3 teammates
Teammate 1: implement login
Teammate 2: implement refresh-token
Teammate 3: review security cả 2
Lead: gộp + verify cuối
```

**Khi nào KHÔNG dùng:** task 1 người làm 30 phút xong → teams overhead lớn, chậm hơn. Teams chỉ đáng cho việc đủ lớn để chia.

**Khi nào áp dụng:** epic/feature đa mảng + đã bật experimental + chấp nhận token ~3–4x (xem FAQ 02 câu 5).

---

## 7. Teams vs `/batch` — khác nhau gì? (supervise vs script giữ plan + verify chéo)

**Giải thích.** Dễ nhầm vì cả 2 đều "nhiều agents". Khác ở cơ chế giữ mạch:

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
```

**Ví dụ:** migrate 30 endpoints → `/batch` (mỗi endpoint 1 PR, review từng cái). Thiết kế lại auth (cần lead điều phối linh hoạt) → teams.

**Khi nào áp dụng:** chia PR được → batch. Cần supervise linh hoạt → teams.

---

## 8. Theo dõi / kill background agents (`/agents`, `/tasks`, kill switch)?

**Giải thích.** Agents chạy nền cần quản lý như process:

```bash
/agents    # Running (đang chạy) + Library (có gì)
/tasks     # tasks đang chạy
```

**Kill switch:** `Ctrl+X Ctrl+K` **×2 trong 3s** → kill all background. Dùng khi agents chạy loạn (sửa lung tung, bill tăng).

```text
Dấu hiệu kill: 3 agents cùng sửa 1 file / bill tăng mà không ra gì / output lạ
→ Ctrl+X Ctrl+K ×2 → /tasks xác nhận sạch → spawn lại với scope hẹp hơn
```

**Khi nào áp dụng:** mỗi khi spawn >2 background → mở `/tasks` để mắt. Thấy loạn → kill không tiếc (rẻ hơn để nó chạy tiếp).

---

## 9. Worktrees để làm gì? (mỗi session 1 checkout, song song không giẫm)

**Giải thích.** Vấn đề: 3 agents cùng sửa 1 checkout → conflict/giẫm file. Fix: mỗi session 1 worktree (checkout riêng). Agent view/`/batch` tự tạo; làm tay thì:

```bash
git worktree add ../myrepo-worktrees/feat-auth -b feat/auth
git worktree list
# Xong việc:
git worktree remove ../myrepo-worktrees/feat-auth
```

**Ví dụ:** 3 song song — auth (worktree 1), payment (worktree 2), docs (worktree 3) → merge từng cái, không giẫm.

**Khi nào áp dụng:** cứ >1 agent chạm code cùng lúc → worktrees. 1 agent đọc-only → khỏi.

---

## 10. Workflow chuẩn: research song song → implement → verify?

**Giải thích.** Công thức team hay dùng (rẻ + an toàn):

```text
Phase 1 — Research song song (Haiku, fresh, worktree riêng nếu cần):
  agent A: quét auth · agent B: quét payment · agent C: quét tests
  → mỗi đứa trả 15 dòng
Phase 2 — Implement (Sonnet, main): gắt từng file theo tóm tắt
Phase 3 — Verify: fresh-reviewer + /verify (chạy app thật) + tests xanh
```

```bash
# Phase 1: 3 research song song (rẻ)
/model haiku
# Phase 2: implement
/model sonnet
# Phase 3: review khó
/model opus
/verify
```

Chi tiết verify xem [../02-tips-thuc-chien/04-verification-done-that.md](../02-tips-thuc-chien/04-verification-done-that.md).

**Khi nào áp dụng:** mọi feature vừa-trở-lên. Task 5 phút thì khỏi (overhead không đáng).

---

## Vẫn lỗi thì sao? (subagents/teams)

1. Subagent không trigger → description quá dài/mờ (FAQ 02 câu 4) + `/agents` check library.
2. Kẹt deny headless → allowlist + `allowed-tools` (FAQ 03 câu 6).
3. Bill tăng → `/usage` xem subagents nào ngốn + `/tasks` kill thừa.
4. Giẫm file → worktrees (câu 9).
5. `/debug` → chẩn đoán; `/bug` nếu nghi core.

```bash
/agents
/tasks
/usage
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md) — quản lý Running/Library
  - [../01-huong-dan-su-dung/commands/session-context/tasks/README.md](../01-huong-dan-su-dung/commands/session-context/tasks/README.md) — theo dõi tasks nền
  - [../01-huong-dan-su-dung/commands/code-repo/batch/README.md](../01-huong-dan-su-dung/commands/code-repo/batch/README.md) — chia epic thành worktree-subagents
  - [../01-huong-dan-su-dung/commands/session-context/branch/README.md](../01-huong-dan-su-dung/commands/session-context/branch/README.md) — worktrees song song
  - [../01-huong-dan-su-dung/commands/model-mode/model/README.md](../01-huong-dan-su-dung/commands/model-mode/model/README.md) — route Haiku/Sonnet/Opus theo phase
  - [../01-huong-dan-su-dung/commands/code-repo/verify/README.md](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) — verify sau implement
  - [../01-huong-dan-su-dung/commands/session-context/fork/README.md](../01-huong-dan-su-dung/commands/session-context/fork/README.md) — fork cô lập
- Bài tổng quan:
  - [../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md](../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md) — subagents + teams chi tiết
  - [../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md](../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md) — worktrees + checkpoints
  - [../02-tips-thuc-chien/05-parallel-agents.md](../02-tips-thuc-chien/05-parallel-agents.md) — chạy song song hiệu quả
  - [../02-tips-thuc-chien/04-verification-done-that.md](../02-tips-thuc-chien/04-verification-done-that.md) — verify sau implement
- FAQ liên quan: [FAQ 02](02-model-context-token.md) (overhead), [FAQ 03](03-permissions-modes.md) (headless deny), [FAQ 06](06-skills-commands-claude-md.md) (fork skill).

> Mẹo 1 dòng: _ồn + độc lập thì spawn, không thì main làm — và cứ >1 đứa chạm code là mỗi đứa 1 worktree._
