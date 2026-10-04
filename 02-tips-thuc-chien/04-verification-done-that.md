# Tips 04 — Verification: Bắt Claude Chứng Minh "Done Thật"

## 1. Thang verification (rẻ → đắt, chọn theo task)

| Level | Cách | Khi dùng |
|---|---|---|
| 1. Prompt | "Chạy check X và iterate trong message này" | Mọi task, hôm nay dùng được ngay |
| 2. `/goal` | Đặt completion condition, evaluator check sau mỗi turn tới khi đạt | Session dài không giám sát |
| 3. Stop hook | Script gate, block turn-end tới khi pass (tối đa 8 blocks) | Rule phải đúng 100%, không tin LLM |
| 4. Fresh reviewer | Subagent/`/code-review` review diff ở context mới | Trước khi merge, chống định kiến người viết |
| 5. `/verify` | Build + **chạy app thật, quan sát** (không chỉ test/typecheck) | Thay đổi hành vi user-visible |
| 6. Dynamic workflow | Nhiều agents verify chéo findings | Task critical, cần đồng thuận |

## 2. Viết "done criteria" sao cho check được

```
TỆ:  "làm cho sạch, đảm bảo không lỗi"
TỐT: "Done = `pnpm --filter auth test` xanh + `pnpm lint` 0 error +
      `git diff --stat` chỉ chạm apps/auth/** + demo log của flow Y paste ở cuối."
```

## 3. Adversarial review đúng cách

```text
"Review diff này với plan trong plan.md. Định nghĩa finding = bug/correctness/security/test-gap thực sự.
Bỏ qua style preferences. Trả về: [SEVERITY] file:line — mô tả — gợi ý fix."
```

- Reviewer = subagent fresh (không viết code đó) → bắt nhiều hơn self-review cùng context.
- Reviewer quá dễ dãi? Calibration: bắt rate 3 diffs lịch sử repo + giải thích pass/fail.
- Reviewer quá khắt (flag mọi thứ → over-engineer)? Dặn explicit cái gì **không** tính là finding.

## 4. Bằng chứng > lời hứa

- Chấp nhận: test xanh log, diff cụ thể, screenshot/log chạy thật (`/verify`).
- Không chấp nhận: "it should work", "logic có vẻ đúng".
- Flaky test: dặn tester subagent *"nếu flaky thì ghi flaky và dừng đoán"* — root-cause guess của nó
  cho flaky thường confidently-wrong.

## 5. Loops (lặp tới khi đúng) — dùng có ý thức

`/loop` + `/goal` + Stop-hook-gate đều "làm tới khi đạt". Luôn kèm: điều kiện dừng rõ ràng,
giới hạn vòng (maxTurns), và 1 reviewer độc lập cuối cùng — tránh infinite loop đốt tiền.
