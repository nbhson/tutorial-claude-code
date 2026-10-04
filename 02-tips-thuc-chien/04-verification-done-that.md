# Tips 04 — Verification: Bắt Claude Chứng Minh "Done Thật"

> "Xong rồi" của LLM mặc định là lời hứa, không phải bằng chứng. Bài này dựng thang verification 6 levels (rẻ→đắt), cách viết done criteria check được, adversarial review, calibration, flaky, và loops guard.

## Mục lục

- [1. Vì sao phải verify?](#1-vì-sao-phải-verify)
- [2. Thang verification 6 levels](#2-thang-verification-6-levels)
- [3. Viết done criteria sao cho check được](#3-viết-done-criteria-sao-cho-check-được)
- [4. Ví dụ copy-paste: 3 done criteria chuẩn](#4-ví-dụ-copy-paste-3-done-criteria-chuẩn)
- [5. Adversarial review đúng cách](#5-adversarial-review-đúng-cách)
- [6. Calibration: khi reviewer quá dễ/quá khó](#6-calibration-khi-reviewer-quá-dễquá-khó)
- [7. Walkthrough: verify feature refund end-to-end](#7-walkthrough-verify-feature-refund-end-to-end)
- [8. Flaky test + bằng chứng > lời hứa](#8-flaky-test--bằng-chứng--lời-hứa)
- [9. Loops dùng có ý thức (loop/goal/stop-hook)](#9-loops-dùng-có-ý-thức-loopgoalstop-hook)
- [10. Bảng chọn level theo task + checklist](#10-bảng-chọn-level-theo-task--checklist)
- [11. Pitfalls + fix](#11-pitfalls--fix)
- [12. Bài tập](#12-bài-tập)
- [13. Tham khảo chéo](#13-tham-khảo-chéo)

---

## 1. Vì sao phải verify?

### 1.1. Ba câu nói dối kinh điển của LLM

| Câu Claude nói | Sự thật | Cần đòi |
|---|---|---|
| "It should work" | Chưa chạy gì cả | Log chạy thật |
| "Logic có vẻ đúng" | Mới đọc, chưa test | Test xanh + diff |
| "Đã fix hết edge cases" | Mới fix 1 case bạn báo | Liệt kê cases + evidence từng cái |

Không phải model điêu — nó được train để "nghe có lý". Việc của bạn là **đổi hợp đồng từ "nghe có lý" sang "chứng minh được"**.

### 1.2. Cơ chế: verification là gate ngoài model

- Prompt verify (Level 1) vẫn tin LLM tự báo cáo → rẻ nhưng gian lận được.
- Stop hook (Level 3) + chạy app thật (Level 5) là gate **ngoài model**: script/test báo pass mới cho qua, model không tự "cho mình đậu".
- Rule: **cái gì càng quan trọng (tiền, auth, migrate) thì gate càng phải ngoài model.**

### 1.3. Verify sớm rẻ, verify muộn đắt

```text
Bắt ở prompt (thêm 1 câu verify): +30 giây
Bắt ở reviewer fresh (trước merge): +15 phút
Lọt ra production (bug tiền/auth): x100 lần + mất niềm tin
```

---

## 2. Thang verification 6 levels

| Level | Cách | Tốn gì | Khi dùng | Lệnh/config liên quan |
|---|---|---|---|---|
| 1. Prompt | "Chạy check X và iterate trong message này" | Vài K tokens | Mọi task, dùng ngay hôm nay | Prompt kèm lệnh test |
| 2. `/goal` | Đặt completion condition, evaluator check sau mỗi turn | Evaluator mỗi turn | Session dài không giám sát | `/goal`, xem commands/goal |
| 3. Stop hook | Script gate, block turn-end tới khi pass (tối đa 8 blocks) | 0 tokens LLM, chỉ CPU chạy script | Rule phải đúng 100%, không tin LLM | `Stop` hook, xem [Tips 06](./06-hooks-recipes.md) |
| 4. Fresh reviewer | Subagent/`/code-review` review diff ở context mới | 1 subagent (~20K overhead) | Trước khi merge, chống định kiến | `/code-review`, subagent reviewer |
| 5. `/verify` | Build + **chạy app thật, quan sát** (không chỉ test/typecheck) | Thời gian chạy thật | Thay đổi user-visible (UI, API, refund) | `/verify` |
| 6. Dynamic workflow | Nhiều agents verify chéo findings | 3–4 agents | Task critical, cần đồng thuận | Agent teams, `/ultrareview` |

### 2.1. Level 1 — Prompt (nền của mọi thứ)

Thêm 1 câu vào mọi prompt code:

```text
"Sau khi sửa, chạy `pnpm --filter <pkg> test` và dán log pass/fail.
Nếu đỏ, fix tiếp trong message này tới khi xanh hoặc dừng sau 3 lần và báo blocker."
```

- Ưu: 0 setup, dùng ngay.
- Nhược: vẫn tin LLM báo cáo. Dùng cho task thường, không dùng cho tiền/auth/migrate.

### 2.2. Level 2 — `/goal` (người gác không ngủ)

```bash
/goal Done khi `pnpm --filter payments test` xanh + git diff chỉ chạm src/payments/**
# → evaluator check sau mỗi turn, chưa đạt thì bắt làm tiếp
```

- Dùng cho session dài không ngồi canh (overnight, batch).
- Luôn kèm maxTurns / điều kiện dừng (xem mục 9), không thả trôi.

### 2.3. Level 3 — Stop hook (luật sắt)

Script chạy mỗi lần turn định kết thúc. Fail → block, bắt làm tiếp (tối đa 8 lần).

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/hooks/test-gate.sh" }]
      }
    ]
  }
}
```

```bash
#!/usr/bin/env bash
# hooks/test-gate.sh — copy-paste, sửa lệnh test cho repo bạn
set -euo pipefail
pnpm --filter payments test 2>&1 | tail -n 30
```

- Dùng khi rule phải đúng 100% (lint, typecheck, test payments). Chi tiết ở [Tips 06](./06-hooks-recipes.md).

### 2.4. Level 4 — Fresh reviewer (chống thiên vị)

```text
Spawn reviewer subagent fresh (chưa thấy reasoning của writer).
Review git diff với plan.md. Finding = bug/correctness/security/test-gap.
Bỏ qua style. Trả về [SEVERITY] file:line — mô tả — gợi ý fix.
```

- Vì sao fresh? Writer rationalize code của chính nó ("chỗ này chắc đúng"). Reviewer fresh không có ký ức đó → bắt nhiều hơn.
- Mọi PR nontrivial đều qua vòng này trước human.

### 2.5. Level 5 — `/verify` (chạy thật, không chỉ test)

```bash
/verify
# → build + chạy app thật, quan sát hành vi (click, gọi API, đọc log runtime)
```

- Test xanh nhưng app vẫn có thể gãy (env, migrate, webhook, CORS). `/verify` bắt chứng minh bằng runtime.
- Bắt buộc cho thay đổi user-visible: UI, API, payments, auth flow.

### 2.6. Level 6 — Dynamic workflow (đồng thuận)

- 3+ agents verify chéo: 1 tester chạy, 1 reviewer đọc diff, 1 security soi, lead tổng hợp.
- Dùng cho task critical (migrate tiền, auth, infra). Đắt nên chỉ dùng khi đáng (xem [Tips 08](./08-tiet-kiem-cost-token.md)).

---

## 3. Viết done criteria sao cho check được

Công thức: **lệnh + phạm vi diff + evidence.**

```text
TỆ:  "làm cho sạch, đảm bảo không lỗi"
→ Không check được. "Sạch" là gì? "Không lỗi" đo bằng gì?

TỐT: "Done = `pnpm --filter auth test` xanh + `pnpm lint` 0 error +
      `git diff --stat` chỉ chạm apps/auth/** + demo log của flow Y paste ở cuối."
→ 4 checks, mỗi cái 10 giây là biết pass/fail.
```

Checklist done criteria:

- [ ] Có **lệnh** cụ thể (test/lint/typecheck/build)?
- [ ] Có **phạm vi diff** (`git diff --stat` chỉ chạm ...)?
- [ ] Có **evidence** (log xanh, screenshot, demo log paste kèm)?
- [ ] Có **cấm** (không đụng ..., không thêm dep, không commit main)?
- [ ] Có **giới hạn** (thử tối đa N lần, đỏ thì dừng báo)?

---

## 4. Ví dụ copy-paste: 3 done criteria chuẩn

### Ví dụ 1 — Bug auth (nhẹ, Level 1+4)

```text
Done = `pnpm --filter auth test login` xanh (dán log 10 dòng cuối)
+ `git diff --stat` chỉ chạm src/auth/**
+ 1 regression test mới cover email có dấu.
Sau đó spawn reviewer fresh review diff 1 vòng.
```

### Ví dụ 2 — Feature payments (nặng, Level 1+4+5)

```text
Done = `pnpm --filter payments test` xanh + `pnpm lint` 0 error
+ `git diff --stat` chỉ chạm src/payments/**
+ demo log gọi POST /api/payments/:id/refund (idempotency-key trùng trả cùng kết quả) paste ở cuối
+ `/verify` pass (app chạy thật, refund hiện trong dashboard).
```

### Ví dụ 3 — Session dài không giám sát (Level 2+3)

```bash
/goal Done khi pnpm --filter cart test xanh + git diff chỉ chạm src/cart/**, tối đa 15 turns, quá thì dừng và báo blocker.
```

```bash
# Kèm Stop hook test-gate.sh (mục 2.3) để block turn-end tới khi xanh (tối đa 8 blocks)
```

---

## 5. Adversarial review đúng cách

"Adversarial" = reviewer có nhiệm vụ **tìm lỗi**, không phải khen.

### Prompt reviewer chuẩn (copy-paste)

```text
Review diff này với plan trong plan.md.
Định nghĩa finding = bug/correctness/security/test-gap thực sự.
Bỏ qua style preferences (tên biến, format, import order không tính).
Trả về: [SEVERITY: HIGH/MED/LOW] file:line — mô tả 1 dòng — gợi ý fix 1 dòng.
Cuối cùng: verdict PASS / NEEDS-FIX + 3 gaps ưu tiên cao nhất.
Scope: chỉ review files trong `git diff --name-only`, không lan sang file khác.
```

### Quy trình writer/reviewer tách context

```text
1. Main (writer) implement → xong → `git diff > /tmp/diff.txt`
2. Spawn reviewer FRESH (chưa thấy reasoning của writer), đưa diff + plan.md
3. Reviewer trả gaps → writer fix → re-review nếu HIGH còn sót
4. Không HIGH mới merge (xem [Tips 09](./09-teamwork-chuan-hoa.md))
```

### Vì sao phải fresh?

- Self-review cùng context: writer nhớ "lúc đó nghĩ gì" → tự bao biện.
- Fresh reviewer: chỉ thấy code + plan → soi như người ngoài.
- Giữ vòng này cho mọi PR nontrivial. Chi tiết fan-out ở [Tips 05](./05-parallel-agents.md).

---

## 6. Calibration: khi reviewer quá dễ/quá khó

### Reviewer quá dễ dãi (toàn PASS)

Calibration bằng lịch sử repo:

```text
"Rate 3 diffs lịch sử này (đính kèm diff + biết trước 2 PASS 1 FAIL nhưng không nói cái nào).
Giải thích pass/fail từng cái. Sau đó review diff hiện tại với cùng độ khó tính."
```

→ Ép reviewer chứng minh nó phân biệt được tốt/xấu trước khi tin verdict.

### Reviewer quá khắt (flag mọi thứ → over-engineer)

Dặn explicit cái gì **không** tính:

```text
"Không tính là finding: style, tên biến, micro-perf (<5%), refactor 'cho đẹp',
thiếu comment ở code tự giải thích, test thiếu cho code 1 dòng log."
"Chỉ flag nếu: sai logic, mất tiền, lộ secret, gãy API, test-gap ở flow tiền/auth."
```

> Chuẩn team: false-positive ~15% là ok cho self-review (thà ồn còn hơn lọt HIGH). Human review cuối sẽ lọc nốt.

---

## 7. Walkthrough: verify feature refund end-to-end

**Bối cảnh:** vừa implement `POST /api/payments/:id/refund` (theo plan 3 phases ở [Tips 03](./03-plan-first-workflow.md)).

**Bước 1 — Level 1 (prompt, mỗi phase):**

```text
"Xong Phase 2a chưa? Chạy `pnpm --filter payments test service` và dán log.
Đỏ thì fix tiếp trong message này."
→ Nhận log xanh 12 passed, dán kèm.
```

**Bước 2 — Level 3 (Stop hook, cả session):**

```bash
# hooks/test-gate.sh đã cài từ đầu session → mỗi turn-end tự chạy test
# Turn nào quên chạy test cũng bị hook chặn lại. Tối đa 8 blocks rồi cho dừng để human xem.
```

**Bước 3 — Level 4 (fresh reviewer, trước PR):**

```text
"Spawn reviewer fresh. Diff: `git diff main...HEAD -- src/payments/`.
Đối chiếu plan.md. Trả về [SEVERITY] file:line — mô tả — fix."
→ Nhận 1 HIGH (thiếu idempotency check khi retry), 2 MED. Fix HIGH, note MED.
```

**Bước 4 — Level 5 (`/verify`, trước merge):**

```bash
/verify
# → build staging, gọi refund thật 2 lần cùng idempotency-key, quan sát:
# lần 2 trả cùng kết quả lần 1, không trừ tiền 2 lần, dashboard hiện 1 refund.
# Paste demo log vào PR.
```

**Bước 5 — Ghi done vào PR:**

```markdown
## Done
- [x] `pnpm --filter payments test` xanh (log đính kèm)
- [x] Reviewer fresh: 1 HIGH đã fix, 2 MED noted
- [x] `/verify`: refund idempotent thật, log demo đính kèm
- [x] `git diff --stat` chỉ chạm src/payments/**
```

---

## 8. Flaky test + bằng chứng > lời hứa

### Chấp nhận vs không chấp nhận

| Chấp nhận (evidence) | Không chấp nhận (lời hứa) |
|---|---|
| Log test xanh paste kèm (10–20 dòng cuối) | "it should work" |
| `git diff --stat` cụ thể | "logic có vẻ đúng" |
| Screenshot/log chạy thật (`/verify`) | "đã fix hết edge cases" (liệt kê đâu?) |
| File:line + repro steps | "chỗ này chắc không ai đụng" |

### Flaky test: dặn tester dừng đoán

Root-cause guess của LLM cho flaky thường **confidently-wrong** (đoán chắc như đinh nhưng sai).

```text
Prompt tester subagent (copy-paste):
"Chạy `pnpm --filter <pkg> test <file>` 3 lần. Nếu pass/fail khác nhau giữa các lần,
ghi `FLAKY: <test name>` và dừng, không đoán root cause.
Chỉ báo: lần nào pass, lần nào fail, log khác nhau ở dòng nào."
```

→ Flaky thì human xem (timing, parallel, external service), không để model vá bừa làm bẩn code.

---

## 9. Loops dùng có ý thức (loop/goal/stop-hook)

`/loop` + `/goal` + Stop-hook-gate đều "làm tới khi đạt". Không guard = infinite loop đốt tiền.

### Công thức loop an toàn (copy-paste)

```bash
/loop "Chạy pnpm --filter cart test, fix tới khi xanh" --max-turns 10
/goal Done khi pnpm --filter cart test xanh, tối đa 10 turns, quá thì dừng và báo blocker + dán log cuối.
```

Luôn có 3 guard:

1. **Điều kiện dừng rõ ràng:** test nào xanh? diff chạm đâu? log nào là pass?
2. **Giới hạn vòng:** `maxTurns` (vd 10), Stop hook tối đa 8 blocks.
3. **Reviewer độc lập cuối cùng:** loop xong vẫn qua reviewer fresh 1 vòng (loop chỉ đảm bảo "xanh", không đảm bảo "đúng").

### Bảng: khi nào loop vs làm tay

| Loop (`/loop`, `/goal`, Stop-gate) | Làm tay từng turn |
|---|---|
| Fix test đỏ rõ ràng, chạy lại là biết | Debug chưa rõ root cause |
| Lặp pattern (lint 20 files, migrate) | Quyết định kiến trúc, tradeoff |
| Chạy overnight không canh | Task tiền/auth cần mắt human mỗi bước |

---

## 10. Bảng chọn level theo task + checklist

### Bảng chọn nhanh

| Task | Levels dùng | Ví dụ done |
|---|---|---|
| Đổi text, thêm log | L1 | Chạy 1 lệnh + dán log |
| Bug 1 module | L1 + L4 | Test xanh + reviewer fresh 1 vòng |
| Feature payments/auth | L1 + L3 + L4 + L5 | Test-gate + reviewer + `/verify` chạy thật |
| Migrate/schema/tiền | L1–L6 full | Thêm multi-agent + human review bắt buộc |
| Session overnight | L2 + L3 + L4 cuối | Goal + gate + sáng dậy review diff |

### Checklist verify trước khi báo done

- [ ] Done criteria viết bằng lệnh + diff scope + evidence?
- [ ] Đã chạy (không phải "chắc chạy được") và dán log?
- [ ] Diff có lan ngoài scope không (`git diff --stat`)?
- [ ] Reviewer fresh đã soi (nếu nontrivial)?
- [ ] User-visible → đã `/verify` chạy thật?
- [ ] Flaky → đã ghi FLAKY và dừng đoán?
- [ ] Loop có maxTurns + reviewer cuối?

---

## 11. Pitfalls + fix

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| Tin "should work" | Merge xong QA bắt 3 bugs | Đòi log/diff/`/verify`, không nhận lời hứa |
| Done criteria mơ hồ ("cho sạch") | Cãi nhau "thế nào là xong" | Viết lại bằng lệnh + diff + evidence (mục 3) |
| Reviewer = writer | Toàn PASS mù | Luôn fresh reviewer, chưa thấy reasoning |
| Reviewer không định nghĩa finding | Flag style, bỏ sót security | Paste prompt mục 5, liệt kê cái gì KHÔNG tính |
| Loop không giới hạn | Chạy 50 turns đốt tiền | maxTurns + Stop 8 blocks + reviewer cuối |
| Flaky bắt model đoán | Vá bừa, bẩn code, vẫn flaky | Dặn ghi FLAKY và dừng (mục 8) |
| Chỉ test, không chạy thật | Test xanh, production gãy env/webhook | User-visible → `/verify` bắt buộc |
| Verify xong không ghi vào PR | Lần sau lại cãi "hôm đó test chưa?" | Template Done 5 dòng (mục 7, bước 5) |
| Gate quá chặt cho task nhỏ | Mất 30 phút setup hook cho việc 5 phút | Task nhỏ chỉ L1; hook/gate để task tiền/auth |

---

## 12. Bài tập

**Bài 1 (10 phút — viết done criteria):**

- Lấy 1 task đang làm, viết done criteria cũ ("cho xong") thành bản check được (lệnh + diff + evidence).
- Hỏi Claude: "done criteria này còn lỗ hổng verify nào?" — bổ sung 1 ý.

**Bài 2 (25 phút — adversarial review):**

- Lấy 1 diff gần nhất, chạy prompt reviewer mục 5 bằng subagent fresh.
- Đếm findings HIGH/MED/LOW. Fix HIGH, note MED. So với self-review trước đây: bắt thêm được mấy cái?

**Bài 3 (20 phút — calibration + flaky):**

- Lấy 3 diffs lịch sử (1 có bug đã biết), bắt reviewer rate + giải thích (mục 6).
- Tìm 1 test hay flaky trong repo, dặn tester theo mẫu mục 8 (chạy 3 lần, ghi FLAKY). Ghi lại: model có còn đoán bừa không?

> Đạt: sau 2 tuần, 100% PR nontrivial của bạn có log xanh + reviewer fresh + diff scope trong mô tả PR.

---

## 13. Tham khảo chéo

- Lệnh verify:
  - [../01-huong-dan-su-dung/commands/model-mode/goal/README.md](../01-huong-dan-su-dung/commands/model-mode/goal/README.md) — đặt completion condition
  - [../01-huong-dan-su-dung/commands/code-repo/loop/README.md](../01-huong-dan-su-dung/commands/code-repo/loop/README.md) — lặp tới khi đúng
  - [../01-huong-dan-su-dung/commands/code-repo/verify/README.md](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) — chạy app thật
  - [../01-huong-dan-su-dung/commands/code-repo/code-review/README.md](../01-huong-dan-su-dung/commands/code-repo/code-review/README.md) — review diff
  - [../01-huong-dan-su-dung/commands/code-repo/ultrareview/README.md](../01-huong-dan-su-dung/commands/code-repo/ultrareview/README.md) — multi-agent review nặng
  - [../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md) — kiểm tra Stop gate
- Bài tips liên quan:
  - [Tips 02](./02-prompt-engineering.md) — viết verify ngay trong prompt
  - [Tips 03](./03-plan-first-workflow.md) — phase-gate từng phase
  - [Tips 05](./05-parallel-agents.md) — reviewer/tester subagents
  - [Tips 06](./06-hooks-recipes.md) — code Stop test-gate + lint/branch-protect
  - [Tips 09](./09-teamwork-chuan-hoa.md) — PR flow + review chuẩn team

> Mẹo 1 dòng: _không nhận "should work" — nhận log xanh, diff gọn, và app chạy thật._
