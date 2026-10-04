# Tips 05 — Parallel Agents: Nhân 3 Sức Mạnh Mà Không Loạn

> 1 subagent = 1 task hẹp. Fan-out đúng thì x3 tốc độ research/review/test. Fan-out bừa thì x3 tiền + loạn merge. Bài này: fan-out rules, 4 recipes chuẩn, pattern writer/reviewer, worktrees/batch, và kill switch.

## Mục lục

- [1. Vì sao parallel? (và vì sao loạn?)](#1-vì-sao-parallel-và-vì-sao-loạn)
- [2. Nguyên tắc fan-out](#2-nguyên-tắc-fan-out)
- [3. Bốn recipes chuẩn (copy-paste)](#3-bốn-recipes-chuẩn-copy-paste)
- [4. Writer/Reviewer tách context](#4-writerreviewer-tách-context)
- [5. Ví dụ: fan-out 3 explorers song song](#5-ví-dụ-fan-out-3-explorers-song-song)
- [6. Walkthrough: feature lớn với 5 agents](#6-walkthrough-feature-lớn-với-5-agents)
- [7. Worktrees + batch cho scale](#7-worktrees--batch-cho-scale)
- [8. Bảng: song song vs nối tiếp vs một mình](#8-bảng-song-song-vs-nối-tiếp-vs-một-mình)
- [9. Vận hành: theo dõi + kill switch + output contract](#9-vận-hành-theo-dõi--kill-switch--output-contract)
- [10. Pitfalls + fix](#10-pitfalls--fix)
- [11. Bài tập](#11-bài-tập)
- [12. Tham khảo chéo](#12-tham-khảo-chéo)

---

## 1. Vì sao parallel? (và vì sao loạn?)

### 1.1. Lợi ích: fresh context + song song thật

- **Fresh context:** mỗi subagent bắt đầu trắng → không mang rác của main, không rationalize code người khác.
- **Song song thật:** 3 explorers đọc 3 modules cùng lúc → wall-clock giảm 2–3x so với main đọc tuần tự.
- **Chuyên môn hóa:** explorer chỉ đọc, tester chỉ chạy test, reviewer chỉ soi — prompt hẹp → ít sai.

### 1.2. Giá phải trả: overhead + merge + token nhân

| Giá | Con số | Ý nghĩa |
|---|---|---|
| Overhead mỗi con | ~20K tokens | Spawn 5 con bừa = 100K bay hơi |
| Merge conflicts | Tăng theo số writer cùng repo | 2+ writers cùng branch = đau đầu |
| Token cộng dồn | Nhân theo cấp (subagent spawn subagent) | 1 → 3 → 9 nếu không tiết chế |
| Giám sát | `/agents`, `/tasks` | Quên là có con chạy nền đốt tiền |

> Kết luận: parallel là **đòn bẩy có giá**. Dùng cho việc độc lập + hẹp + đáng tiền. Không dùng "cho vui".

---

## 2. Nguyên tắc fan-out

1. **1 subagent = 1 task hẹp + output format.** Không có "QA agent chung chung", "helper agent đa năng".
2. **Trần 3–5 concurrent.** Hơn → cân nhắc worktrees + sessions riêng hoặc `/batch` (xem mục 7).
3. **Độc lập thật mới fan-out.** 3 explorers 3 modules khác nhau → fan-out. Explorer → planner → implementer (nối tiếp) → **chain**, đừng parallel bừa.
4. **Read-only trước, write sau.** Explorers/reviewers read-only. Chỉ 1 writer tại 1 thời điểm trên cùng branch (trừ khi worktrees).
5. **Luôn có output contract:** "trả quyết định + evidence, không dump 200 dòng log".

### Checklist trước khi fan-out

- [ ] Các task có độc lập thật không (không chờ nhau)?
- [ ] Mỗi task viết được trong 2 dòng + output format?
- [ ] Tổng concurrent ≤5?
- [ ] Writers có dẫm chân nhau không (cùng files)?
- [ ] Đã biết kill switch (`Ctrl+X Ctrl+K` ×2)?

---

## 3. Bốn recipes chuẩn (copy-paste)

Mỗi recipe: vai trò + tools + prompt mẫu + hook đi kèm (chi tiết hooks ở [Tips 06](./06-hooks-recipes.md)).

### Recipe 1 — Explorer (Read/Grep/Glob, read-only)

```text
Explorer payments: chỉ đọc src/payments/*.ts (không sửa, không chạy test nặng).
Trả về:
- Files liên quan (đường dẫn + 1 dòng vai trò, tối đa 8 files)
- Flow hiện tại (5-8 bullet)
- 2 phương án thay đổi (pros/cons 3 bullet mỗi cái)
- "Chỉ files mày sẽ sửa/đọc nếu làm change tiếp theo"
Không dump log dài, không đọc src/legacy/.
```

- Tools: `Read`, `Grep`, `Glob` (cấm `Edit`/`Write`).
- Hook bound: explorer + hook giới hạn scope (block đọc ngoài `src/payments/**`).

### Recipe 2 — Planner (Write scope plans/)

```text
Planner refund: đọc summary của 2 explorers (paste kèm) + docs/architecture.md.
Sinh plan markdown gồm: files sửa, steps, risks, verify từng phase, gate.
Lưu vào plans/refund-plan.md. Không đụng source, chỉ ghi file plan.
```

- Tools: `Read` + `Write` (chỉ `plans/`).
- Hook bound: block write ngoài `plans/`.

### Recipe 3 — Reviewer (Bash git-read-only + Read)

```text
Reviewer: review `git diff main...HEAD -- src/payments/`.
Rate: correctness, coverage, style, security (mỗi mảng 2-3 bullet).
Finding = bug/correctness/security/test-gap thực sự, bỏ qua style preferences.
Trả về: [SEVERITY: HIGH/MED/LOW] file:line — mô tả — gợi ý fix.
Cuối: verdict PASS / NEEDS-FIX.
```

- Tools: `Bash` (chỉ `git diff/log/show`, cấm `push`), `Read`.
- Hook bound: block `git push` + force-push (branch-protect).

### Recipe 4 — Tester (Bash test-runner + Read)

```text
Tester cart: chạy `pnpm --filter cart test` (focused, không full suite).
Trả về: PASS/FAIL + 10 dòng log cuối + 1-line guess (nếu fail).
Nếu pass/fail khác nhau giữa 3 lần chạy → ghi FLAKY và dừng đoán.
Không sửa code, chỉ chạy và báo.
```

- Tools: `Bash` (chỉ lệnh test), `Read` (đọc log).
- Hook bound: giới hạn test command (chỉ `pnpm --filter cart test*`, block `rm -rf`, block deploy).

### Bảng tóm tắt 4 recipes

| Recipe | Tools | Input | Output | Hook đi kèm |
|---|---|---|---|---|
| Explorer | Read/Grep/Glob | Phạm vi hẹp | Files + flow + 2 options | Giới hạn scope đọc |
| Planner | Read + Write plans/ | Summaries explorers | plan.md có gate | Block write ngoài plans/ |
| Reviewer | Bash git-read + Read | Diff + plan | Findings + verdict | Branch-protect |
| Tester | Bash test + Read | Scope test | PASS/FAIL + log | Giới hạn test command |

---

## 4. Writer/Reviewer tách context

Pattern đắt giá nhất trong bài này. Giữ cho mọi PR nontrivial.

```text
Main (writer) implement → xong → `git diff` →
spawn reviewer FRESH (chưa thấy reasoning của writer) →
reviewer trả gaps → writer fix → re-review nếu còn HIGH
```

### Vì sao tách?

- Writer nhớ "lúc đó nghĩ gì" → tự bao biện ("chỗ này chắc đúng vì...").
- Reviewer fresh chỉ thấy code + plan → soi như người ngoài, bắt nhiều hơn 30–50% (kinh nghiệm team).
- Chi tiết calibration ở [Tips 04](./04-verification-done-that.md).

### Copy-paste full vòng

```text
# Bước 1 (writer, main): xong code, chưa merge
git diff main...HEAD -- src/payments/ > /tmp/payments-diff.txt

# Bước 2: spawn reviewer fresh, đưa diff + plan
"Review diff trong /tmp/payments-diff.txt với plan.md.
Finding = bug/correctness/security/test-gap. Bỏ qua style.
Trả về [SEVERITY] file:line — mô tả — fix. Verdict PASS/NEEDS-FIX."

# Bước 3 (writer): fix HIGH trước, MED note lại
# Bước 4: re-review nếu còn HIGH. Không HIGH mới mở PR (/ship).
```

---

## 5. Ví dụ: fan-out 3 explorers song song

**Tình huống:** bug refund chưa rõ nằm ở API, service, hay webhook. Thay vì main đọc tuần tự 30 files, fan-out 3 explorers.

```text
Main prompt (1 message, 3 agents song song):

1. Explorer A: chỉ đọc src/payments/api/*.ts. Trả về endpoints refund + validation (5 bullet + file:line).
2. Explorer B: chỉ đọc src/payments/service/*.ts. Trả về flow trừ tiền/hoàn tiền + chỗ idempotency (5 bullet + file:line).
3. Explorer C: chỉ đọc src/payments/webhook/*.ts + docs/webhooks.md. Trả về retry/timeout behavior (5 bullet).

Mỗi explorer: không sửa code, không dump log, chỉ trả summary ≤15 bullet.
Main chỉ tổng hợp 3 summaries thành 1 table root-cause nghi ngờ.
```

Kết quả: 3 summaries ~1500 tokens về main, thay vì 30K raw reads. Main quyết định "nghi service nhất" → giao planner plan fix service (chain, không parallel tiếp).

---

## 6. Walkthrough: feature lớn với 5 agents

**Bối cảnh:** thêm refund (API + service + webhook + docs + tests). Dùng 5 agents qua 3 waves.

**Wave 1 — Explore song song (3 explorers):**

```text
Explorer A → api, Explorer B → service, Explorer C → webhook (như mục 5).
Main tổng hợp → quyết định scope 3 phases.
```

**Wave 2 — Plan (1 planner, nối tiếp sau Wave 1):**

```text
Planner đọc 3 summaries + architecture.md → sinh plans/refund-plan.md (3 phases + gate).
Human duyệt plan (sửa 2 vòng bằng chữ).
```

**Wave 3 — Implement + verify (writer main + reviewer/tester):**

```text
Main (writer) làm Phase 1 → tester chạy focused test → xanh →
làm Phase 2 → tester chạy → xanh →
xong hết → reviewer fresh soi diff → fix HIGH → /verify chạy thật.
```

Tổng concurrent tối đa 3 (Wave 1). Không bao giờ 5 cùng lúc. **Song song ở explore, nối tiếp ở implement.**

---

## 7. Worktrees + batch cho scale

### 7.1. 2+ streams sửa cùng repo → mỗi stream 1 worktree

2 writers cùng branch = conflict + context lẫn. Tách worktree là tách cả đĩa + context.

```bash
# Mỗi stream 1 worktree (copy-paste, đổi tên)
git worktree add ../myrepo-worktrees/stream-refund -b feat/refund
git worktree add ../myrepo-worktrees/stream-cart -b feat/cart-promo

# Mỗi stream 1 session Claude riêng, chạy song song, không dẫm nhau
# Xong thì remove:
git worktree remove ../myrepo-worktrees/stream-cart
```

> Xem [../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md](../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md) (nếu có) và [Tips 09](./09-teamwork-chuan-hoa.md).

### 7.2. 1 change lặp pattern → `/batch`

Migrate 20 files, thêm test toàn repo, đổi import 50 chỗ → 1 agent làm tuần tự thì lâu, 20 writers cùng repo thì loạn. `/batch` = 5–30 worktree-subagents, mỗi đứa 1 PR nhỏ.

```bash
/batch Migrate 20 files trong src/legacy/ sang src/new/: mỗi file 1 PR nhỏ, chạy focused test file đó, dán log. Tối đa 10 concurrent.
/batch Thêm missing tests cho src/utils/*.ts: mỗi file 1 subagent, chỉ thêm test, không sửa source.
```

> Xem [../01-huong-dan-su-dung/commands/batch/README.md](../01-huong-dan-su-dung/commands/batch/README.md).

### 7.3. Agent teams (experimental)

- Lead plan + teammates security/perf/tests song song.
- Chỉ bật khi task đủ lớn (multi-day, multi-module). Task nhỏ bật teams = overhead nuốt lợi ích.
- Đánh giá: nếu lead + 2 teammates mà tổng turns < 1.5x single-agent thì đáng.

### Bảng chọn scale

| Tình huống | Dùng gì | Vì sao |
|---|---|---|
| 3 explorers đọc 3 modules | Fan-out 3 subagents | Nhanh, rẻ, không conflict |
| 2 features sửa cùng repo | 2 worktrees + 2 sessions | Tách đĩa + context |
| Migrate 20 files lặp pattern | `/batch` 5–30 worktree-agents | Mỗi đứa 1 PR, dễ review |
| Task critical multi-module | Agent teams | Lead + teammates verify chéo |

---

## 8. Bảng: song song vs nối tiếp vs một mình

| Kiểu | Ví dụ | Khi dùng |
|---|---|---|
| Một mình (main) | Fix typo, đổi text | Task 1 file 1 bước |
| Nối tiếp (chain) | Explorer → planner → implementer | Việc sau cần kết quả việc trước |
| Song song (fan-out) | 3 explorers 3 modules | Việc độc lập, cùng cấp |
| Scale (worktrees/batch) | 2 streams / 20 files | Sửa song song cùng repo / lặp pattern |

> Sai lầm #1: chain mà fan-out (planner chưa có summary explorers đã chạy). Sai lầm #2: độc lập mà chain (đọc tuần tự 3 modules mất 3x thời gian).

---

## 9. Vận hành: theo dõi + kill switch + output contract

### Theo dõi

```bash
/agents
# → xem Running (đang chạy gì) + Library (agents khả dụng)
/tasks
# → xem tasks nền, tiến độ, con nào kẹt
```

- Đặt tên task rõ khi spawn ("explorer-payments-api", không "agent-1") để `/tasks` đọc được.
- Con nào >10 phút không trả → ping 1 lần, không trả nữa → kill + spawn lại với scope hẹp hơn.

### Kill switch

```text
Ctrl+X Ctrl+K ×2 trong 3s → kill all background subagents.
```

- Dùng khi: fan-out sai (5 con đọc cùng files), 1 con loop, thấy tiền chạy nhanh ([Tips 08](./08-tiet-kiem-cost-token.md)).
- Sau kill: `/clear` main nếu context đã nhiễm outputs dở, rồi fan-out lại hẹp hơn.

### Output contract (ép từ prompt, khỏi dọn rác)

```text
Thêm vào mọi prompt subagent:
"Trả về: quyết định + evidence (file:line, log 5 dòng). Không dump 200 dòng log.
Tối đa 15 bullet. Nếu không đủ info thì ghi BLOCKED + thiếu gì, đừng đoán."
```

### Subagent spawn subagent

- Cho phép nhưng tiết chế: token cộng dồn theo cấp số nhân (1→3→9).
- Rule: subagent cấp 2 phải read-only + hẹp hơn cấp 1. Cấm cấp 3 trừ khi agent teams.
- Nếu thấy `/usage` vọt sau fan-out → kiểm tra có spawn lồng không.

---

## 10. Pitfalls + fix

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| "QA agent chung chung" | Trả chung chung, không dùng được | 1 agent 1 task hẹp + output format (mục 3) |
| Fan-out 8 concurrent | Chậm, tốn, khó theo dõi | Trần 3–5; hơn thì worktrees/batch |
| Chain mà parallel | Planner plan thiếu vì explorers chưa xong | Chain: đợi summaries rồi mới plan |
| 2 writers cùng branch | Conflict, ghi đè nhau | Mỗi stream 1 worktree (mục 7) |
| Reviewer cùng context writer | Toàn PASS mù | Luôn fresh reviewer (mục 4) |
| Subagent dump 200 dòng log | Main nhiễm rác | Output contract: quyết định + evidence, ≤15 bullet |
| Subagent spawn lồng vô hạn | `/usage` vọt, tiền bay | Cấm cấp 3, cấp 2 read-only hẹp |
| Quên kill switch | 3 con nền chạy 1 tiếng không ai biết | `/agents` + `Ctrl+X Ctrl+K` ×2 |
| Dùng subagent cho việc skill làm được | Tốn 20K overhead cho việc 500 tokens | Skill trước, subagent sau (xem [Tips 07](./07-thiet-ke-skills.md)) |
| Không đặt tên task | `/tasks` toàn "agent-1..5" | Tên rõ: explorer-payments-api, tester-cart |

---

## 11. Bài tập

**Bài 1 (15 phút — viết lại 4 recipes):**

- Lấy repo bạn, viết 4 prompts explorer/planner/reviewer/tester cho 1 module thật (copy khung mục 3, điền paths + lệnh test).
- Chạy thử 1 explorer, chấm: summary có đủ "files + flow + options" không? Thiếu thì sửa prompt.

**Bài 2 (30 phút — writer/reviewer vòng kín):**

- Lấy 1 diff nhỏ, chạy vòng mục 4 (reviewer fresh → fix HIGH → re-review).
- Đếm HIGH/MED/LOW. So với tự review: bắt thêm mấy cái?

**Bài 3 (30 phút — worktree + batch):**

- Tạo 2 worktrees cho 2 streams nhỏ, mỗi stream 1 session, làm song song 20 phút.
- Thử `/batch` cho 1 việc lặp pattern (vd thêm test 5 files utils). Đo: thời gian vs làm tay + số PR sinh ra có review được không?

> Đạt: sau 1 tháng, mọi explore >3 files của bạn đều via subagent + mọi PR nontrivial đều qua reviewer fresh.

---

## 12. Tham khảo chéo

- Lệnh agents & scale:
  - [../01-huong-dan-su-dung/commands/agents/README.md](../01-huong-dan-su-dung/commands/agents/README.md) — xem Running/Library
  - [../01-huong-dan-su-dung/commands/tasks/README.md](../01-huong-dan-su-dung/commands/tasks/README.md) — theo dõi tasks nền
  - [../01-huong-dan-su-dung/commands/batch/README.md](../01-huong-dan-su-dung/commands/batch/README.md) — lặp pattern quy mô lớn
  - [../01-huong-dan-su-dung/commands/code-review/README.md](../01-huong-dan-su-dung/commands/code-review/README.md) — reviewer chuẩn
  - [../01-huong-dan-su-dung/commands/verify/README.md](../01-huong-dan-su-dung/commands/verify/README.md) — verify sau fan-out
- Bài tips liên quan:
  - [Tips 01](./01-context-hygiene.md) — vì sao đẩy explore sang subagent
  - [Tips 04](./04-verification-done-that.md) — reviewer calibration + tester flaky
  - [Tips 06](./06-hooks-recipes.md) — hooks bound từng recipe
  - [Tips 09](./09-teamwork-chuan-hoa.md) — PR flow team với reviewer fresh

> Mẹo 1 dòng: _fan-out việc độc lập + hẹp, chain việc nối tiếp, worktree khi writers dẫm chân nhau — và luôn biết kill switch._
