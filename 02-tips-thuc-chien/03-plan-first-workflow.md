# Tips 03 — Plan-First: Explore → Plan → Implement (Không Code Ngay)

> Nguyên nhân #1 của output sprawling/sai: **nhảy thẳng vào implement ở task phức tạp.** Plan mode rẻ (chỉ tokens suy nghĩ), code sai đắt (sửa + test + rewind). Bài này deep-dive plan mode, checklist plan tốt, flow 2 sessions, phase-gate, và khi nào được skip.

## Mục lục

- [1. Vì sao plan-first thắng?](#1-vì-sao-plan-first-thắng)
- [2. Cơ chế plan mode](#2-cơ-chế-plan-mode)
- [3. Vào plan mode: 3 cách + Shift+Tab deep-dive](#3-vào-plan-mode-3-cách--shifttab-deep-dive)
- [4. Plan tốt gồm gì (checklist)](#4-plan-tốt-gồm-gì-checklist)
- [5. Ví dụ: prompt plan chuẩn copy-paste](#5-ví-dụ-prompt-plan-chuẩn-copy-paste)
- [6. Plan-then-execute 2 sessions (task lớn)](#6-plan-then-execute-2-sessions-task-lớn)
- [7. Walkthrough step-by-step: feature payments 2 ngày](#7-walkthrough-step-by-step-feature-payments-2-ngày)
- [8. Phase-gate chống drift](#8-phase-gate-chống-drift)
- [9. Bảng so sánh: khi nào plan vs làm luôn](#9-bảng-so-sánh-khi-nào-plan-vs-làm-luôn)
- [10. Pitfalls + fix](#10-pitfalls--fix)
- [11. Bài tập](#11-bài-tập)
- [12. Tham khảo chéo](#12-tham-khảo-chéo)

---

## 1. Vì sao plan-first thắng?

### 1.1. Toán chi phí: plan rẻ, code sai đắt

| Lựa chọn | Tốn gì | Rủi ro |
|---|---|---|
| Plan 1 turn (500–2000 tokens suy nghĩ) | Vài xu, 2 phút đọc | Thấp: sai thì sửa chữ |
| Code ngay 5 files sai | 20K+ tokens + 5 turns sửa + rewind + test đỏ | Cao: lan sang file khác, gãy API |

Thực tế team: task >1 file mà không plan → 60% phải rewind ít nhất 1 lần. Task có plan duyệt → rewind giảm còn ~15%.

### 1.2. Ba lợi ích ngoài "đỡ sai"

1. **Ép scope rõ:** plan bắt liệt kê files đụng/không đụng → chống sprawl từ gốc.
2. **Chia verify được:** mỗi phase có gate test → bắt drift sớm (xem mục 8).
3. **Lưu được:** plan là file (`plan.md`) — session implement fresh vẫn có bản đồ, không phụ thuộc trí nhớ hội thoại ([Tips 01](./01-context-hygiene.md)).

### 1.3. Khi nào plan-first KHÔNG thắng?

Task 1 file, 1 bước, rõ ràng (đổi text, thêm log, sửa typo) → plan tốn hơn lợi. Xem mục 9 để biết khi nào skip.

---

## 2. Cơ chế plan mode

### 2.1. Plan mode là gì?

Plan mode = Claude **read-only**:

- Được: đọc file, grep, glob, outline thay đổi, hỏi ngược lại, sinh plan markdown.
- Không được: `Edit` / `Write` source, chạy lệnh đổi trạng thái (migrate, deploy), commit.

> Hiểu nôm na: cho kiến trúc sư đi đo đạc, cấm thợ đụng búa.

### 2.2. Under-the-hood

1. **Permissions siết:** tool `Edit`/`Write` bị chặn hoặc yêu cầu duyệt; `Bash` chỉ cho read-only (tùy config).
2. **Output là artifact:** plan thường là markdown có cấu trúc (files, steps, risks, verify) — có thể save ra `plan.md` để session sau dùng.
3. **Vòng refine rẻ:** bạn chê plan → Claude sửa chữ (không sửa code) → 2–3 vòng là chốt, mỗi vòng vài trăm tokens.
4. **Thoát plan = duyệt:** bạn gõ "ok, implement" hoặc `Shift+Tab` về default → mới được code.

### 2.3. Sơ đồ Explore → Plan → Implement

```text
[Explore: đọc + subagents] --> [Plan: outline + risks + verify, chờ duyệt]
        |                                                        |
   rẻ, read-only                                          bạn duyệt / sửa chữ
        |                                                        v
        +-------------> [Implement: code + test từng phase] <----+
                           |                 |
                        gate xanh         gate đỏ → dừng, rewind phase
```

---

## 3. Vào plan mode: 3 cách + Shift+Tab deep-dive

### Cách 1 — `Shift+Tab` xoay modes

Nhấn `Shift+Tab` lặp để xoay:

```text
default → acceptEdits → plan → auto → bypass → (quay về default)
```

- Màn hình hiện chữ `plan` là đang ở plan mode.
- `Shift+Tab` tiếp để thoát khi muốn implement.
- Dùng `/terminal-setup` nếu `Shift+Tab` không ăn (iTerm2/VSCode/Kitty/Alacritty/Zed/Warp/WezTerm) — xem [Tips 10](./10-debugging-power-moves.md).

**Copy-paste kiểm tra:**

```bash
# Nhấn Shift+Tab tới khi thấy `plan`, rồi gõ:
Đọc src/auth/ và trình plan refactor, không code trong message này.
```

### Cách 2 — Gõ `/plan` trong session

```bash
/plan
# → ép vào plan mode ngay, khỏi xoay Shift+Tab
```

> Xem [../01-huong-dan-su-dung/commands/plan/README.md](../01-huong-dan-su-dung/commands/plan/README.md).

### Cách 3 — Dặn bằng lời (không cần nhớ phím)

```text
"Trước khi làm gì, trình plan chi tiết và chờ duyệt. Không sửa code trong message này."
"Vào plan mode: chỉ đọc, outline thay đổi, hỏi tôi nếu thiếu thông tin."
```

Cách này hợp cho người mới + non-coder (xem [Tips 02](./02-prompt-engineering.md)).

### Bảng so sánh 3 cách

| Cách | Ưu | Nhược | Dùng khi nào |
|---|---|---|---|
| `Shift+Tab` | Nhanh, không tốn turn | Phải nhớ vòng xoay, terminal kén phím | Power-user hàng ngày |
| `/plan` | Rõ ràng, 1 lệnh | Phải nhớ tên lệnh | Khi đang chat muốn ép plan giữa chừng |
| Dặn bằng lời | Không cần nhớ gì | Tốn 1 câu, model đôi khi "ngứa tay" code lén | Người mới, non-coder, task giao cho người khác đọc |

> Mẹo: kết hợp — `Shift+Tab` vào plan + câu dặn "không code, chỉ plan" để khóa 2 lớp.

---

## 4. Plan tốt gồm gì (checklist)

Plan duyệt được phải trả lời 7 câu hỏi. Thiếu 1 là lúc implement phải đoán.

- [ ] **1. Đọc gì:** files đã đọc + files sẽ đọc (đường dẫn cụ thể, không "vài files auth").
- [ ] **2. Sửa gì:** files sẽ sửa/tạo/xóa (đường dẫn + hàm chính mỗi file).
- [ ] **3. Thứ tự steps:** step 1→2→3, mỗi step 1 việc, ước lượng rủi ro từng step.
- [ ] **4. Không đụng gì:** liệt kê cấm địa (`generated/`, schema, `main`, dep mới).
- [ ] **5. Risks/edge cases:** top 3 rủi ro + case biên (null, empty, unicode, concurrent, migrate cũ).
- [ ] **6. Verify từng phase:** lệnh test/lint/log nào, log trông thế nào là pass.
- [ ] **7. Cửa chia phase + gate:** xong phase N + test xanh mới sang N+1. Đỏ thì dừng.

### Template plan chuẩn (bảo Claude trả đúng khung này)

```markdown
# Plan: <tên task 1 dòng>

## Mục tiêu
- <end-state 2 dòng>

## Files đọc (đã đọc)
- `src/...` — vai trò 1 dòng

## Files sửa (dự kiến)
| File | Việc | Rủi ro |
|---|---|---|
| `src/...` | ... | ... |

## Steps
1. Step 1 — ... — verify: `...`
2. Step 2 — ... — verify: `...`

## Không đụng
- ...

## Risks / Edge cases
- ...

## Verify tổng
- `pnpm ...` xanh + `git diff --stat` chỉ chạm ...
```

---

## 5. Ví dụ: prompt plan chuẩn copy-paste

### Ví dụ 1 — Feature payments (đủ 7 checklist)

```text
Tôi muốn thêm refund cho POST /api/payments.

Trước khi code, trình plan gồm:
- Code nào sẽ đọc (liệt kê đường dẫn), files nào sẽ sửa (đường dẫn + hàm)
- Steps theo thứ tự + risks/edge cases (idempotency, partial refund, webhook)
- Cái gì KHÔNG đụng (schema? API cũ? generated/?)
- Output format + cách verify chính xác từng phase (lệnh test nào, log nào là pass)
Chờ tôi duyệt mới implement. Không sửa code trong message này.
Output plan dạng markdown, lưu vào plan.md.
```

### Ví dụ 2 — Refactor file to (ép chia phase)

```text
Tôi muốn tách src/auth.ts (~800 dòng) thành login/session/types, giữ public API.

Vào plan mode. Trình plan gồm 3 phases, mỗi phase có verify gate
(`pnpm --filter auth test` xanh mới sang phase tiếp).
Liệt kê hàm nào di chuyển đi đâu + 3 risks lớn nhất.
Chờ duyệt. Không code.
```

### Ví dụ 3 — Research khó (ép 2 phương án)

```text
Trước khi làm gì, explore src/queue/worker.ts + docs/queue.md rồi trình plan:
- Flow hiện tại (5 bullet) + root cause nghi ngờ (2 giả thuyết + evidence)
- 2 phương án fix (pros/cons 3 bullet mỗi cái) + đề xuất 1 cái
- Cách verify (test nào, log nào chứng minh hết race)
Chờ tôi chọn phương án mới implement.
```

---

## 6. Plan-then-execute 2 sessions (task lớn)

Vì sao 2 sessions? Vì **context degradation** ([Tips 01](./01-context-hygiene.md)): session research mang 30K rác explore → session implement ngáo. Tách ra là sạch.

```text
Session A (plan, 20-30 phút):
1. Shift+Tab vào plan (hoặc /plan).
2. Paste 1 trong 3 ví dụ mục 5.
3. Refine 2-3 vòng bằng chữ (không code): "phase 2 tách nhỏ hơn", "thêm edge unicode", "bỏ phương án 2".
4. Chốt → save plan.md (commit hoặc copy clipboard).

Session B (fresh, implement):
1. /clear hoặc terminal mới.
2. Paste plan.md + câu lệnh implement (copy-paste dưới).
3. Làm phase-by-phase, verify từng phase, dừng khi đỏ.
```

**Câu lệnh mở Session B (copy-paste):**

```text
Đọc plan.md. Chỉ làm Phase 1 (ghi tên phase).
Thực hiện step-by-step, chạy lệnh verify của phase và dán log pass/fail.
Xong phase 1 + test xanh mới hỏi tôi có sang phase 2 không. Không đụng phase khác.
```

**Biến thể cho team (async):**

```bash
# Người A (senior) làm Session A, commit plan.md, mở PR draft "plan: refund"
# Người B (junior/agent) làm Session B từ plan.md, không cần họp lại
git add plan.md && git commit -m "plan: refund payments (3 phases)" && git push
```

---

## 7. Walkthrough step-by-step: feature payments 2 ngày

**Bối cảnh:** thêm `POST /api/payments/:id/refund`, repo Node + pnpm, có test payments sẵn.

**Ngày 1 sáng — Explore (15 phút):**

```text
Prompt: "Dùng subagent explore src/payments/*.ts. Trả về files liên quan refund (nếu có),
flow charge hiện tại 6 bullet + 2 chỗ dễ gãy khi thêm refund. Không code."
→ Lưu summary vào plan.md (phần "Bối cảnh").
```

**Ngày 1 chiều — Plan (25 phút, Session A):**

```bash
# Shift+Tab tới `plan`, paste Ví dụ 1 (mục 5)
# Claude trả plan 3 phases:
#   P1: types + validator, P2: endpoint + service, P3: webhook + e2e
# Bạn refine 2 vòng:
Vòng 1: "Thêm edge idempotency-key + partial refund vào risks."
Vòng 2: "Phase 2 tách thành 2a (service) + 2b (endpoint). Mỗi phase có verify riêng."
# Chốt → save plan.md → commit
```

**Ngày 2 sáng — Implement P1+P2a (Session B fresh):**

```text
"Đọc plan.md. Chỉ làm Phase 1. Verify bằng pnpm --filter payments test rồi dán log. Dừng sau phase 1."
→ Xanh → /clear → "Đọc plan.md. Chỉ làm Phase 2a..." (session fresh nữa)
```

**Ngày 2 chiều — P2b+P3 + review:**

```text
# Mỗi phase 1 session fresh, tương tự. Xong P3:
/clear
"Spawn reviewer subagent fresh. Review git diff với plan.md.
Finding = bug/correctness/security/test-gap. Trả về [SEVERITY] file:line — mô tả — fix."
→ Fix gaps → /verify (chạy app thật) → /ship mở PR.
```

Tổng: 5–6 sessions gọn thay vì 1 session 90% đầy rác. Chi tiết verify ở [Tips 04](./04-verification-done-that.md), review ở [Tips 05](./05-parallel-agents.md).

---

## 8. Phase-gate chống drift

Đừng duyệt 1 plan khổng lồ 15 steps rồi thả model chạy 1 mạch. Nó sẽ drift (tự chế thêm, bỏ verify, sửa lan).

### Công thức gate

```text
Mỗi phase có: việc + verify lệnh + điều kiện sang phase tiếp.
Claude xong + verify phase N (dán log xanh) mới được đụng phase N+1.
Phase nào đỏ → dừng toàn bộ, báo blocker, không vá lén sang phase khác.
```

### Ví dụ gate trong plan.md

```markdown
## Phase 1 — Types + validator
- Việc: thêm RefundRequest/RefundResult trong src/payments/types.ts
- Verify: `pnpm --filter payments test types` xanh
- Gate: xanh mới sang Phase 2. Đỏ → dừng, dán log.

## Phase 2a — Service refund()
- Việc: implement refund() idempotent trong src/payments/service.ts
- Verify: `pnpm --filter payments test service` xanh (gồm 2 cases mới)
- Gate: tương tự.
```

### Bảng: có gate vs không gate

| Không gate | Có gate |
|---|---|
| Chạy 1 mạch 10 steps, hỏng ở step 3 nhưng tới step 9 mới biết | Hỏng step 3 dừng ngay, rewind 1 phase |
| Không log từng phase, cuối mới "chắc xanh" | Mỗi phase có log xanh dán kèm |
| Drift: tự thêm feature "cho tiện" | Mọi thêm ngoài plan phải hỏi trước |

---

## 9. Bảng so sánh: khi nào plan vs làm luôn

| Tín hiệu | Plan-first | Làm luôn |
|---|---|---|
| Số files | >1 file | 1 file |
| Số steps | >2 steps | 1–2 steps rõ ràng |
| Rủi ro | Đụng API/schema/migrate/auth/money | Đổi text, thêm log, typo, style |
| Độ mờ | Chưa rõ làm thế nào (cần explore) | Biết chính xác sửa dòng nào |
| Review | Cần người duyệt trước khi code | Tự làm tự chịu được |
| Ví dụ | Refund payments, tách file 800 dòng, fix race | Sửa label button, thêm `console.log`, bump version docs |

> Quy tắc ngón tay: **>1 file hoặc >2 steps → plan mode reflex.** Không cần nghĩ, cứ plan trước.

### Khi skip plan nhưng vẫn an toàn (3 điều kiện đủ)

1. Lệnh verify 1 dòng (`pnpm test <1 file>` xanh là xong).
2. Ràng buộc NEVER viết được trong 1 dòng.
3. Rewind được trong 10 giây nếu sai (chưa push, chưa migrate).

Thiếu 1 trong 3 → quay lại plan.

---

## 10. Pitfalls + fix

| Pitfall | Triệu chứng | Fix |
|---|---|---|
| Plan chung chung ("sửa vài files auth") | Implement đoán, sprawl | Ép template 7 mục (mục 4), đường dẫn đầy đủ |
| Plan 15 steps không gate | Drift, hỏng giữa không biết | Chia ≤3–4 phases, mỗi phase có verify + gate |
| Plan trong session bẩn (70% rác) | Plan quên constraints, thiếu files | `/clear` rồi mới plan; nạp `CLAUDE.md` + spec gọn |
| Duyệt plan vội (ok luôn) | Plan sai lọt xuống code | Refine ít nhất 1 vòng: hỏi "risks? edge? verify?" |
| Code lén trong plan mode | Plan kèm luôn diff 5 files | Dặn explicit "không sửa code message này"; check `git status` sau plan |
| Plan xong không lưu file | Session implement quên nửa plan | Save `plan.md` + commit; Session B paste plan |
| 1 session làm hết plan 3 ngày | Context 90%, implement ngáo | Mỗi phase 1 session fresh (mục 6) |
| Không định nghĩa NEVER trong plan | Implement đụng cấm địa | Mọi plan đều có mục "Không đụng" |
| Tin plan là đúng tuyệt đối | Plan sai hướng vẫn code theo | Coi plan là giả thuyết: phase 1 là rẻ nhất để kiểm chứng, sai thì sửa plan |

---

## 11. Bài tập

**Bài 1 (15 phút — xoay modes):**

1. Nhấn `Shift+Tab` xoay hết vòng `default → acceptEdits → plan → auto → bypass`, chụp nhớ vị trí `plan`.
2. Gõ `/plan` rồi thoát. Nếu `Shift+Tab` không ăn, chạy `/terminal-setup` theo [Tips 10](./10-debugging-power-moves.md).
3. Dặn bằng lời "trình plan, chờ duyệt" cho 1 task nhỏ — so sánh 3 cách vào plan, cái nào hợp bạn nhất?

**Bài 2 (30 phút — plan 1 feature thật):**

1. Lấy 1 task >1 file trong backlog.
2. Viết prompt plan theo Ví dụ 1 (mục 5), ép template 7 mục.
3. Refine 2 vòng (thêm risks + tách phase). Save `plan.md`. Đếm: có bao nhiêu files/risks bạn chưa nghĩ ra trước khi plan?

**Bài 3 (45 phút — 2-session flow):**

1. Session A: plan + save `plan.md` + commit.
2. Session B fresh (`/clear`): paste plan + "chỉ làm Phase 1, verify rồi dừng".
3. Đo: số turns tới xong Phase 1, số lần rewind. So với cách code ngay trước đây của bạn.

> Đạt: sau 2 tuần, mọi task >1 file của bạn đều có `plan.md` trước khi có diff.

---

## 12. Tham khảo chéo

- Lệnh plan & sessions:
  - [../01-huong-dan-su-dung/commands/plan/README.md](../01-huong-dan-su-dung/commands/plan/README.md) — vào plan mode bằng lệnh
  - [../01-huong-dan-su-dung/commands/clear/README.md](../01-huong-dan-su-dung/commands/clear/README.md) — tách sessions sạch
  - [../01-huong-dan-su-dung/commands/compact/README.md](../01-huong-dan-su-dung/commands/compact/README.md) — nén khi cùng task
  - [../01-huong-dan-su-dung/commands/goal/README.md](../01-huong-dan-su-dung/commands/goal/README.md) — đặt completion condition cho plan dài
  - [../01-huong-dan-su-dung/commands/verify/README.md](../01-huong-dan-su-dung/commands/verify/README.md) — verify bằng app thật
  - [../01-huong-dan-su-dung/commands/terminal-setup/README.md](../01-huong-dan-su-dung/commands/terminal-setup/README.md) — fix Shift+Tab
- Bài tips liên quan:
  - [Tips 01](./01-context-hygiene.md) — vì sao tách sessions
  - [Tips 02](./02-prompt-engineering.md) — viết prompt plan chuẩn
  - [Tips 04](./04-verification-done-that.md) — verify từng phase + reviewer
  - [Tips 05](./05-parallel-agents.md) — planner agent + reviewer fresh

> Mẹo 1 dòng: _task nào >1 file hoặc >2 steps thì tay tự `Shift+Tab` vào plan trước khi não kịp bảo "code luôn cho nhanh"._
