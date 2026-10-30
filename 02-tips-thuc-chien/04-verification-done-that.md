# Tips 04 — Verification: bắt Claude chứng minh "done thật"

> **Bài này cho ai:** dev hay nhận câu "xong rồi" của Claude rồi để QA bắt bug sau merge, hoặc tech lead chuẩn hóa done criteria + vòng review cho team.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 03 — Plan trước khi code](./03-plan-first-workflow.md) trước vì walkthrough ở mục 7 xây trên flow plan 3 phases của Tips 03.
> **Đọc xong bạn làm được:** chọn đúng 1 trong 6 mức verify theo mức quan trọng của task; viết done criteria check được; chạy review phản biện bằng reviewer fresh và chỉnh độ khó reviewer.
> **Thời gian:** ~45 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Done criteria | Định nghĩa "xong" bằng lệnh + con số, không bằng cảm giác | `Done = pnpm test auth xanh + lint 0 error` |
| Adversarial review | Review phản biện: nhiệm vụ tìm lỗi, không phải khen | `Finding = bug/correctness/security/test-gap` |
| Stop hook | Script chặn lượt kết thúc tới khi test xanh (tối đa 8 lần) | `hooks/test-gate.sh` chạy `pnpm test` mỗi turn-end |
| `/verify` | Build + chạy app thật + quan sát, không chỉ chạy test/typecheck | Gọi refund 2 lần cùng idempotency-key |
| Flaky test | Test lúc xanh lúc đỏ — đoán bừa càng làm code bẩn | Chạy 3 lần ra kết quả khác → ghi `FLAKY` và dừng |
| Calibration | Chỉnh độ khó reviewer: không quá dễ, không quá khắt | Ép reviewer chấm 3 diff lịch sử trước khi tin verdict |

---

## 1. Vì sao phải verify?

Ba câu nói dối kinh điển của LLM:

| Câu Claude nói | Sự thật | Cần đòi |
|---|---|---|
| "It should work" | Chưa chạy gì cả | Log chạy thật |
| "Logic có vẻ đúng" | Mới đọc, chưa test | Test xanh + diff |
| "Đã fix hết edge cases" | Mới fix 1 case bạn báo | Liệt kê cases + evidence từng cái |

Không phải model cố tình nói dối — model được train để "nghe có lý". Việc của bạn là **đổi hợp đồng từ "nghe có lý" sang "chứng minh được"**. Cơ chế: prompt verify (L1) vẫn tin LLM tự báo cáo → rẻ nhưng gian lận được; Stop hook (L3) + chạy app thật (L5) là gate **ngoài model** — script/test báo pass mới cho qua. Rule: **cái gì càng quan trọng (tiền, auth, migrate) thì gate càng phải ngoài model.** Verify sớm rẻ: +30 giây ở prompt, +15 phút ở reviewer; lọt production (bug tiền/auth) x100 + mất niềm tin.

---

## 2. Thang verification 6 levels

| Level | Cách | Tốn gì | Khi dùng | Lệnh/config |
|---|---|---|---|---|
| 1. Prompt | "Chạy check X và iterate trong message này" | Vài K tokens | Mọi task, dùng ngay hôm nay | Prompt kèm lệnh test |
| 2. `/goal` | Đặt completion condition, evaluator check sau mỗi turn | Evaluator mỗi turn | Session dài không giám sát | `/goal` (từ w20/2026) |
| 3. Stop hook | Script gate, block turn-end tới khi pass (tối đa 8 blocks) | 0 tokens LLM | Rule phải đúng 100% | `Stop` hook, xem [Tips 06](./06-hooks-recipes.md) |
| 4. Fresh reviewer | Subagent/`/code-review` review diff ở context mới | 1 subagent (~20K overhead — ước tính cộng đồng) | Trước merge, chống định kiến | `/code-review` (từ w21/2026) |
| 5. `/verify` | Build + **chạy app thật, quan sát** | Thời gian chạy thật | Thay đổi user-visible (UI, API, refund) | `/verify` |
| 6. Nhiều agent chéo | Nhiều agent verify chéo findings | 3–4 agents | Task critical, cần đồng thuận | `/ultrareview` (public preview từ w17/2026) |

**L1 — Prompt (nền của mọi thứ):** thêm 1 câu vào mọi prompt code — `"Sau khi sửa, chạy \`pnpm --filter <pkg> test\` và dán log pass/fail. Nếu đỏ, fix tiếp trong message này tới khi xanh hoặc dừng sau 3 lần và báo blocker."` 0 setup, dùng ngay — nhưng vẫn tin LLM báo cáo; không dùng cho tiền/auth/migrate.

**L2 — `/goal` (người gác không ngủ):** `/goal Done khi \`pnpm --filter payments test\` xanh + git diff chỉ chạm src/payments/**` → evaluator check sau mỗi turn, chưa đạt thì bắt làm tiếp. Dùng cho session dài không ngồi canh (overnight, batch); luôn kèm maxTurns / điều kiện dừng (mục 9), không thả trôi.

**L3 — Stop hook (luật sắt):** script chạy mỗi turn-end, fail → block, bắt làm tiếp (tối đa 8 lần). Dùng khi rule phải đúng 100% (lint, typecheck, test payments) — config + script copy-paste xem [Tips 06](./06-hooks-recipes.md).

**L4 — Fresh reviewer (chống thiên vị):** spawn reviewer subagent chưa thấy reasoning của writer, review `git diff` với plan.md (prompt đầy đủ ở mục 5). Writer tự bao biện code của mình ("chỗ này chắc đúng"); reviewer fresh không có ký ức đó → bắt nhiều hơn. Mọi PR không đơn giản đều qua vòng này.

**L5 — `/verify` (chạy thật, không chỉ test):** `/verify` → build + chạy app thật, quan sát hành vi (click, gọi API, đọc log runtime). Test xanh nhưng app vẫn có thể gãy (env, migrate, webhook, CORS) — bắt buộc cho thay đổi user-visible. Bonus (từ w34/2026, v2.1.286+): viết 1 skill tên đúng `verify` → Claude tự chạy skill đó trước mỗi commit.

**L6 — Nhiều agent verify chéo:** 1 tester chạy, 1 reviewer đọc diff, 1 security soi, lead tổng hợp. Dùng cho migrate tiền/auth/infra — đắt nên chỉ dùng khi đáng (xem [Tips 08](./08-tiet-kiem-cost-token.md)).

---

## 3. Viết done criteria sao cho check được

Công thức: **lệnh + phạm vi diff + bằng chứng (evidence).**

```text
TỆ:  "làm cho sạch, đảm bảo không lỗi" → không check được
TỐT: "Done = `pnpm --filter auth test` xanh + `pnpm lint` 0 error +
      `git diff --stat` chỉ chạm apps/auth/** + demo log của flow Y paste ở cuối."
→ 4 checks, mỗi cái 10 giây là biết pass/fail.
```

Checklist: có lệnh cụ thể? có phạm vi diff? có bằng chứng paste kèm? có cấm (không đụng ..., không thêm dep)? có giới hạn (tối đa N lần, đỏ thì dừng báo)?

---

## 4. Ba done criteria chuẩn (copy-paste)

```text
Bug auth (nhẹ, L1+L4):
Done = `pnpm --filter auth test login` xanh (dán log 10 dòng cuối)
+ `git diff --stat` chỉ chạm src/auth/** + 1 regression test mới cover email có dấu.
Sau đó spawn reviewer fresh review diff 1 vòng.

Feature payments (nặng, L1+L4+L5):
Done = `pnpm --filter payments test` xanh + `pnpm lint` 0 error
+ `git diff --stat` chỉ chạm src/payments/**
+ demo log gọi POST /api/payments/:id/refund (idempotency-key trùng trả cùng kết quả)
+ `/verify` pass (app chạy thật, refund hiện trong dashboard).

Session dài không giám sát (L2+L3):
/goal Done khi pnpm --filter cart test xanh + git diff chỉ chạm src/cart/**,
tối đa 15 turns, quá thì dừng và báo blocker.
# + Stop hook test-gate.sh block turn-end tới khi xanh
```

---

## 5. Review phản biện đúng cách

Adversarial review = reviewer có nhiệm vụ **tìm lỗi**, không phải khen.

**Prompt reviewer chuẩn (copy-paste):**

```text
Review diff này với plan trong plan.md.
Định nghĩa finding = bug/correctness/security/test-gap thực sự.
Bỏ qua style preferences (tên biến, format, import order không tính).
Trả về: [SEVERITY: HIGH/MED/LOW] file:line — mô tả 1 dòng — gợi ý fix 1 dòng.
Cuối cùng: verdict PASS / NEEDS-FIX + 3 gaps ưu tiên cao nhất.
Scope: chỉ review files trong `git diff --name-only`, không lan sang file khác.
```

**Quy trình writer/reviewer tách context:**

```text
1. Main (writer) implement → xong → `git diff > /tmp/diff.txt`
2. Spawn reviewer FRESH (chưa thấy reasoning của writer), đưa diff + plan.md
3. Reviewer trả gaps → writer fix → re-review nếu HIGH còn sót
4. Không HIGH mới merge (xem [Tips 09](./09-teamwork-chuan-hoa.md))
```

Vì sao phải fresh? Tự review cùng context → writer nhớ "lúc đó nghĩ gì" và tự bao biện; reviewer fresh chỉ thấy code + plan → soi như người ngoài. Giữ vòng này cho mọi PR không đơn giản; fan-out ở [Tips 05](./05-parallel-agents.md).

---

## 6. Chỉnh độ khó reviewer

**Reviewer quá dễ dãi (toàn PASS)** — chỉnh bằng lịch sử repo:

```text
"Rate 3 diffs lịch sử này (đính kèm diff + biết trước 2 PASS 1 FAIL nhưng không nói cái nào).
Giải thích pass/fail từng cái. Sau đó review diff hiện tại với cùng độ khó tính."
```

**Reviewer quá khắt (flag mọi thứ → thiết kế thừa)** — dặn explicit cái gì **không** tính:

```text
"Không tính là finding: style, tên biến, micro-perf (<5%), refactor 'cho đẹp',
thiếu comment ở code tự giải thích, test thiếu cho code 1 dòng log."
"Chỉ flag nếu: sai logic, mất tiền, lộ secret, gãy API, test-gap ở flow tiền/auth."
```

---

## 7. Walkthrough: verify feature refund từ đầu tới cuối

**Bối cảnh:** vừa implement `POST /api/payments/:id/refund` (plan 3 phases ở [Tips 03](./03-plan-first-workflow.md)).

```text
Bước 1 — L1 (mỗi phase):
"Xong Phase 2a chưa? Chạy `pnpm --filter payments test service` và dán log. Đỏ thì fix tiếp."
→ nhận log xanh 12 passed.

Bước 2 — L3 (cả session): hooks/test-gate.sh cài từ đầu session → mỗi turn-end tự chạy test,
turn nào quên cũng bị chặn (tối đa 8 blocks rồi nhường human).

Bước 3 — L4 (trước PR):
"Spawn reviewer fresh. Diff: `git diff main...HEAD -- src/payments/`. Đối chiếu plan.md.
Trả về [SEVERITY] file:line — mô tả — fix."
→ 1 HIGH (thiếu idempotency check khi retry), 2 MED. Fix HIGH, note MED.

Bước 4 — L5 (trước merge):
/verify
# → build staging, gọi refund thật 2 lần cùng idempotency-key, quan sát:
# lần 2 trả cùng kết quả, không trừ tiền 2 lần. Paste demo log vào PR.

Bước 5 — Ghi done vào PR: checklist tick (test xanh + log đính kèm, reviewer 1 HIGH fix/2 MED noted,
/verify pass, diff chỉ chạm src/payments/**) — lần sau khỏi cãi "hôm đó test chưa?".
```

---

## 8. Flaky test và bằng chứng hơn lời hứa

| Chấp nhận (bằng chứng) | Không chấp nhận (lời hứa) |
|---|---|
| Log test xanh paste kèm (10–20 dòng cuối) | "it should work" |
| Screenshot/log chạy thật (`/verify`) | "đã fix hết edge cases" (liệt kê đâu?) |

**Flaky test: dặn tester dừng đoán** — lời đoán root cause của model thường tự tin nhưng sai:

```text
Prompt tester subagent (copy-paste):
"Chạy `pnpm --filter <pkg> test <file>` 3 lần. Nếu pass/fail khác nhau giữa các lần,
ghi `FLAKY: <test name>` và dừng, không đoán root cause.
Chỉ báo: lần nào pass, lần nào fail, log khác nhau ở dòng nào."
```

→ Flaky thì người thật xem (timing, parallel, external service), không để model vá bừa làm bẩn code.

## 9. Loops dùng có ý thức (loop/goal/stop-hook)

`/loop` + `/goal` + Stop-hook-gate đều "làm tới khi đạt". Không guard = vòng lặp vô hạn đốt tiền.

```bash
/loop "Chạy pnpm --filter cart test, fix tới khi xanh" --max-turns 10
/goal Done khi pnpm --filter cart test xanh, tối đa 10 turns, quá thì dừng và báo blocker + dán log cuối.
```

Ba guard bắt buộc: **(1) điều kiện dừng rõ ràng** (test nào xanh? log nào là pass?); **(2) giới hạn vòng** (`maxTurns`, Stop hook tối đa 8 blocks); **(3) reviewer độc lập cuối cùng** — loop chỉ đảm bảo "xanh", không đảm bảo "đúng". Loop hợp với fix test đỏ rõ ràng, lặp pattern (lint 20 files), chạy overnight; làm tay hợp với debug chưa rõ root cause, quyết định kiến trúc, task tiền/auth cần mắt human.

---

## 10. Chọn level theo task + checklist trước khi báo done

| Task | Levels | Ví dụ done |
|---|---|---|
| Đổi text, thêm log | L1 | Chạy 1 lệnh + dán log |
| Bug 1 module | L1 + L4 | Test xanh + reviewer fresh 1 vòng |
| Feature payments/auth | L1 + L3 + L4 + L5 | Test-gate + reviewer + `/verify` chạy thật |
| Migrate/schema/tiền | L1–L6 full | Thêm multi-agent + human review bắt buộc |
| Session overnight | L2 + L3 + L4 cuối | Goal + gate + sáng dậy review diff |

- [ ] Done criteria viết bằng lệnh + phạm vi diff + bằng chứng? Đã chạy và dán log?
- [ ] Diff không lan ngoài phạm vi (`git diff --stat`)?
- [ ] Reviewer fresh đã soi (task không đơn giản)? User-visible → đã `/verify`?
- [ ] Flaky → ghi FLAKY và dừng đoán? Loop có maxTurns + reviewer cuối?

---

## 11. Pitfalls + hiểu nhầm thường gặp

| Pitfall / Hiểu nhầm | Fix / Sự thật |
|---|---|
| Tin "should work" | Đòi log/diff/`/verify`, không nhận lời hứa |
| Done criteria mơ hồ ("cho sạch") | Viết lại bằng lệnh + diff + bằng chứng (mục 3) |
| Reviewer = writer | Luôn fresh reviewer, chưa thấy reasoning |
| Reviewer không định nghĩa finding | Paste prompt mục 5, liệt kê cái gì KHÔNG tính |
| Flaky bắt model đoán | Dặn ghi FLAKY và dừng (mục 8) |
| Chỉ test, không chạy thật | Test xanh mà prod gãy env/webhook; user-visible → `/verify` |
| Verify xong không ghi vào PR | Template Done 5 dòng (mục 7, bước 5) |
| Gate quá chặt cho task nhỏ | Task nhỏ chỉ L1; hook/gate để task tiền/auth |

---

## 12. Bài tập

1. **Viết done criteria (10p):** lấy 1 task đang làm, viết lại criteria cũ thành bản check được (lệnh + diff + bằng chứng); hỏi Claude "criteria này còn lỗ hổng verify nào?".
2. **Review phản biện (25p):** chạy prompt reviewer mục 5 bằng subagent fresh trên 1 diff gần nhất; đếm HIGH/MED/LOW, fix HIGH — so với tự review trước đây bắt thêm được mấy cái?
3. **Calibration + flaky (20p):** 3 diffs lịch sử (1 có bug đã biết) → bắt reviewer rate + giải thích (mục 6); 1 test hay flaky → dặn tester theo mẫu mục 8.

> Đạt: sau 2 tuần, 100% PR không đơn giản của bạn có log xanh + reviewer fresh + phạm vi diff trong mô tả PR.

---

## 13. Tham khảo chéo

- Lệnh: [goal](../01-huong-dan-su-dung/commands/model-mode/goal/README.md) · [loop](../01-huong-dan-su-dung/commands/code-repo/loop/README.md) · [verify](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) · [code-review](../01-huong-dan-su-dung/commands/code-repo/code-review/README.md) · [ultrareview](../01-huong-dan-su-dung/commands/code-repo/ultrareview/README.md) · [hooks](../01-huong-dan-su-dung/commands/knowledge-system/hooks/README.md)
- Bài tips: [Tips 02](./02-prompt-engineering.md) (verify trong prompt) · [Tips 03](./03-plan-first-workflow.md) (phase-gate) · [Tips 05](./05-parallel-agents.md) (reviewer/tester subagents) · [Tips 06](./06-hooks-recipes.md) (Stop test-gate) · [Tips 09](./09-teamwork-chuan-hoa.md) (PR flow)
