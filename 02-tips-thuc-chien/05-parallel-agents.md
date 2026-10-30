# Tips 05 — Parallel agents: nhân 3 sức mạnh mà không loạn

> **Bài này cho ai:** dev muốn chạy song song research/review/test với Claude Code, hoặc tech lead chuẩn hóa cách fan-out subagent cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 01 — Vệ sinh context](./01-context-hygiene.md) trước vì mục 4 nói vì sao phải tách context writer/reviewer.
> **Đọc xong bạn làm được:**
> - Chọn đúng việc để fan-out: 1 subagent = 1 task hẹp → đúng thì x3 tốc độ, bừa thì x3 tiền + loạn merge.
> - Chạy vòng writer → reviewer fresh, và scale bằng worktree / `/batch` khi 2+ writers cùng sửa 1 repo.
> **Thời gian:** ~45 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Subagent | Agent con do Claude Code sinh ra: có context + tools riêng, làm xong chỉ trả summary về main | Explorer đọc `src/payments/` trả 10 bullet, main nhận ~1.5K tokens |
| Fan-out | Chia 1 việc lớn thành 3–5 việc hẹp giao cùng lúc | 1 message spawn 3 explorer cho api/service/webhook |
| Chain (nối tiếp) | Việc sau phải đợi kết quả việc trước | explorer → planner → implementer |
| Fork | Subagent hưởng nguyên conversation của main thay vì bắt đầu trắng — bật mặc định từ w33/2026 | Tắt bằng `CLAUDE_CODE_FORK_SUBAGENT=0` khi muốn reviewer "mới" |
| Background subagent | Subagent chạy nền, main làm tiếp việc khác — mặc định từ w27/2026 | Spawn explorer xong main làm tiếp, kết quả về sau |
| Worktree | Bản sao repo ở thư mục khác để 2 luồng việc không đè nhau | `git worktree add ../wt/stream-refund -b feat/refund` |
| `/batch` | Chia 1 việc lặp thành nhiều worktree-subagent, mỗi con 1 PR nhỏ | `/batch Thêm missing tests cho src/utils/*.ts` |

---

## 1. Vì sao chạy song song? (và vì sao loạn?)

### 1.1. Lợi ích

- **Context sạch:** mỗi subagent có context riêng → raw reads/log không nhiễm main. Từ w27/2026 subagent chạy **background mặc định** — main spawn xong làm tiếp việc khác.
- **Song song thật:** 3 explorers đọc 3 modules cùng lúc → wall-clock giảm 2–3x so với main đọc tuần tự.
- **Chuyên môn hóa:** explorer chỉ đọc, tester chỉ chạy test, reviewer chỉ soi — prompt hẹp → ít sai. Chi tiết giá spawn lồng ở mục 9.

### 1.2. Giá phải trả

| Giá | Con số | Ý nghĩa |
|---|---|---|
| Overhead mỗi con | ~20K tokens | Spawn 5 con bừa = 100K bay hơi (ước tính cộng đồng); token cộng dồn 1→3→9 khi spawn lồng |
| Merge conflicts | Tăng theo số writer cùng repo | 2+ writers cùng branch = đau đầu |

> Kết luận: parallel là **đòn bẩy có giá**. Dùng cho việc độc lập + hẹp + đáng tiền. Không dùng "cho vui".

---

## 2. Nguyên tắc fan-out

1. **1 subagent = 1 task hẹp + output format.** Không có "QA agent chung chung", "helper agent đa năng".
2. **Trần khuyên dùng 3–5 concurrent.** Harness cho phép mặc định 20 (v2.1.217+, đổi bằng `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`) — nhưng quá 5 khó theo dõi; hơn thì worktrees + `/batch` (mục 7).
3. **Độc lập thật mới fan-out.** 3 explorers 3 modules khác nhau → fan-out. Explorer → planner → implementer → **chain**, đừng parallel bừa.
4. **Read-only trước, write sau.** Explorers/reviewers read-only. Chỉ 1 writer tại 1 thời điểm trên cùng branch (trừ khi worktrees).
5. **Luôn có output contract:** "trả quyết định + evidence, không dump 200 dòng log".

---

## 3. Bốn recipes chuẩn (copy-paste)

Hooks đi kèm chi tiết ở [Tips 06](./06-hooks-recipes.md).

### Recipe 1 — Explorer (Read/Grep/Glob, read-only)

```text
Explorer payments: chỉ đọc src/payments/*.ts (không sửa, không chạy test nặng).
Trả về:
- Files liên quan (đường dẫn + 1 dòng vai trò, tối đa 8 files)
- Flow hiện tại (5-8 bullet)
- 2 phương án thay đổi (pros/cons 3 bullet mỗi cái)
Không dump log dài, không đọc src/legacy/.
```

- Tools: `Read`, `Grep`, `Glob` (cấm `Edit`/`Write`). Hook bound: giới hạn scope đọc ngoài `src/payments/**`.

### Recipe 2 — Planner (Write scope plans/)

```text
Planner refund: đọc summary của 2 explorers (paste kèm) + docs/architecture.md.
Sinh plan markdown gồm: files sửa, steps, risks, verify từng phase, gate.
Lưu vào plans/refund-plan.md. Không đụng source, chỉ ghi file plan.
```

- Tools: `Read` + `Write` (chỉ `plans/`). Hook bound: block write ngoài `plans/`.

### Recipe 3 — Reviewer (Bash git-read-only + Read)

```text
Reviewer: review `git diff main...HEAD -- src/payments/`.
Finding = bug/correctness/security/test-gap thực sự, bỏ qua style preferences.
Trả về: [SEVERITY: HIGH/MED/LOW] file:line — mô tả — gợi ý fix.
Cuối: verdict PASS / NEEDS-FIX.
```

- Tools: `Bash` (chỉ `git diff/log/show`, cấm `push`), `Read`. Hook bound: block `git push` + force-push (branch-protect).

### Recipe 4 — Tester (Bash test-runner + Read)

```text
Tester cart: chạy `pnpm --filter cart test` (focused, không full suite).
Trả về: PASS/FAIL + 10 dòng log cuối + 1-line guess (nếu fail).
Nếu pass/fail khác nhau giữa 3 lần chạy → ghi FLAKY và dừng đoán.
Không sửa code, chỉ chạy và báo.
```

- Tools: `Bash` (chỉ lệnh test), `Read`. Hook bound: giới hạn test command, block `rm -rf`, block deploy.

---

## 4. Writer/Reviewer tách context

Pattern đắt giá nhất trong bài này. Giữ cho mọi PR nontrivial.

```text
Main (writer) implement → xong → `git diff` →
spawn reviewer FRESH (chưa thấy reasoning của writer) →
reviewer trả gaps → writer fix → re-review nếu còn HIGH
```

> **Lưu ý fork mode:** từ w33/2026 fork mode bật **mặc định** — subagent hưởng nguyên conversation của main. Muốn reviewer thật sự fresh: đặt `CLAUDE_CODE_FORK_SUBAGENT=0` trong `env` của `settings.json`, hoặc dùng `/subtask <task>` khi cần fork có chủ đích (fork thấy luôn reasoning của writer). `/fork` (w29/2026) thì copy cả session thành 1 background session riêng.

Vì sao tách? Writer nhớ "lúc đó nghĩ gì" → tự bao biện; reviewer fresh chỉ thấy code + plan → bắt nhiều hơn 30–50% (kinh nghiệm team). Chi tiết calibration ở [Tips 04](./04-verification-done-that.md).

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

- Nếu reviewer nhắc đúng reasoning của writer ("vì bạn bảo...") → reviewer đang hưởng context của writer: đặt `CLAUDE_CODE_FORK_SUBAGENT=0` rồi spawn lại.

---

## 5. Ví dụ: fan-out 3 explorers song song

**Tình huống:** bug refund chưa rõ nằm ở API, service, hay webhook. Thay vì main đọc tuần tự 30 files, fan-out 3 explorers.

```text
Main prompt (1 message, 3 agents song song):
1. Explorer A: chỉ đọc src/payments/api/*.ts. Trả endpoints refund + validation (5 bullet + file:line).
2. Explorer B: chỉ đọc src/payments/service/*.ts. Trả flow trừ/hoàn tiền + chỗ idempotency (5 bullet + file:line).
3. Explorer C: chỉ đọc src/payments/webhook/*.ts + docs/webhooks.md. Trả retry/timeout behavior (5 bullet).
Mỗi explorer: không sửa code, không dump log, summary ≤15 bullet.
Main chỉ tổng hợp 3 summaries thành 1 table root-cause nghi ngờ.
```

Kết quả: 3 summaries ~1500 tokens về main, thay vì 30K raw reads. Main "nghi service nhất" → giao planner plan fix service (chain, không parallel tiếp).

---

## 6. Walkthrough: feature lớn với 5 agents

**Bối cảnh:** thêm refund (API + service + webhook + docs + tests) qua 3 waves:

- **Wave 1 — Explore song song (~10 phút):** 3 explorers → api/service/webhook (như mục 5). Main tổng hợp → scope 3 phases.
- **Wave 2 — Plan (nối tiếp, ~15 phút):** planner đọc 3 summaries + architecture.md → `plans/refund-plan.md` (3 phases + gate). Human duyệt plan.
- **Wave 3 — Implement + verify (~45–60 phút):** main (writer) làm từng phase → tester chạy focused test → xanh; xong hết → reviewer fresh soi diff → fix HIGH → `/verify` chạy thật.

Tổng concurrent tối đa 3 (Wave 1). **Song song ở explore, nối tiếp ở implement.**

---

## 7. Worktrees + batch cho scale

### 7.1. 2+ streams sửa cùng repo → mỗi stream 1 worktree

```bash
# Mỗi stream 1 worktree (copy-paste, đổi tên)
git worktree add ../myrepo-worktrees/stream-refund -b feat/refund
git worktree add ../myrepo-worktrees/stream-cart -b feat/cart-promo
git worktree remove ../myrepo-worktrees/stream-cart  # mỗi stream 1 session riêng; xong thì remove
```

> Xem [../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md](../01-huong-dan-su-dung/11-git-worktrees-checkpoints.md) và [Tips 09](./09-teamwork-chuan-hoa.md).

### 7.2. 1 change lặp pattern → `/batch`

Migrate 20 files, thêm test toàn repo → `/batch` = 5–30 worktree-subagents, mỗi đứa 1 PR nhỏ.

```bash
/batch Migrate 20 files trong src/legacy/ sang src/new/: mỗi file 1 PR nhỏ, chạy focused test file đó, dán log. Tối đa 10 concurrent.
```

> Xem [../01-huong-dan-su-dung/commands/code-repo/batch/README.md](../01-huong-dan-su-dung/commands/code-repo/batch/README.md).

Lead plan + teammates security/perf/tests song song — chỉ bật khi task đủ lớn (multi-day, multi-module). Nếu lead + 2 teammates mà tổng turns < 1.5x single-agent thì đáng.

| Tình huống | Dùng gì | Vì sao |
|---|---|---|
| 3 explorers đọc 3 modules | Fan-out 3 subagents | Nhanh, rẻ, không conflict |
| 2 features sửa cùng repo | 2 worktrees + 2 sessions | Tách đĩa + context |
| Migrate 20 files lặp pattern | `/batch` 5–30 worktree-agents | Mỗi đứa 1 PR, dễ review |

---

## 8. Bảng: song song vs nối tiếp vs một mình

| Kiểu | Ví dụ | Khi dùng |
|---|---|---|
| Nối tiếp (chain) | Explorer → planner → implementer | Việc sau cần kết quả việc trước |
| Song song (fan-out) | 3 explorers 3 modules | Việc độc lập, cùng cấp |
| Scale (worktrees/batch) | 2 streams / 20 files | Sửa song song cùng repo / lặp pattern |

---

## 9. Vận hành: theo dõi + kill + output contract

```bash
/agents   # xem Running (đang chạy gì) + Library (agents khả dụng)
/tasks    # xem tasks nền, tiến độ, model mỗi con đang chạy (v2.1.242+)
```

- Đặt tên task rõ khi spawn ("explorer-payments-api", không "agent-1"). Con nào >10 phút không trả → ping 1 lần, không trả nữa → stop (phím `x` trên row trong panel subagent) + spawn lại hẹp hơn.
- Output contract ép từ prompt: `"Trả về: quyết định + evidence (file:line, log 5 dòng). Không dump 200 dòng log. Tối đa 15 bullet. Không đủ info thì ghi BLOCKED + thiếu gì, đừng đoán."`
- Spawn lồng: mặc định tối đa **3 tầng dưới main** (đổi bằng `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`); token cộng dồn 1→3→9 nên rule của bài: cấp 2 read-only + hẹp hơn cấp 1, cấm cấp 3.

---

## 10. Pitfalls + fix

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| "QA agent chung chung" | Trả chung chung, không dùng được | 1 agent 1 task hẹp + output format (mục 3) |
| Chain mà parallel | Planner plan thiếu vì explorers chưa xong | Chain: đợi summaries rồi mới plan |
| 2 writers cùng branch | Conflict, ghi đè nhau | Mỗi stream 1 worktree (mục 7) |
| Reviewer cùng context writer | Toàn PASS mù | Tắt fork mode cho reviewer (mục 4) |
| Subagent dump 200 dòng log | Main nhiễm rác | Output contract: quyết định + evidence, ≤15 bullet |

---

## 11. Bài tập

- **Bài 1 (15 phút):** viết 4 prompts explorer/planner/reviewer/tester cho 1 module thật (copy khung mục 3), chạy 1 explorer, chấm summary có đủ "files + flow + options" không.
- **Bài 2 (30 phút):** lấy 1 diff nhỏ, chạy vòng mục 4 (reviewer fresh → fix HIGH → re-review). Đếm HIGH/MED/LOW, so với tự review.
- **Bài 3 (30 phút):** tạo 2 worktrees cho 2 streams nhỏ làm song song 20 phút; thử `/batch` cho 1 việc lặp (thêm test 5 files utils), đo thời gian vs làm tay.

---

## 12. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md) — xem Running/Library · [../01-huong-dan-su-dung/commands/session-context/tasks/README.md](../01-huong-dan-su-dung/commands/session-context/tasks/README.md) — theo dõi tasks nền
- [../01-huong-dan-su-dung/commands/code-repo/batch/README.md](../01-huong-dan-su-dung/commands/code-repo/batch/README.md) — lặp pattern quy mô lớn
- [Tips 01](./01-context-hygiene.md) — vì sao đẩy explore sang subagent · [Tips 04](./04-verification-done-that.md) — reviewer calibration + tester flaky
- [Tips 06](./06-hooks-recipes.md) — hooks bound từng recipe · [Tips 09](./09-teamwork-chuan-hoa.md) — PR flow team với reviewer fresh

> Mẹo 1 dòng: _fan-out việc độc lập + hẹp, chain việc nối tiếp, worktree khi writers dẫm chân nhau — và luôn biết cách stop task nền._
