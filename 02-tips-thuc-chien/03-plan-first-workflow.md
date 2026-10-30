# Tips 03 — Plan trước khi code: Explore → Plan → Implement

> **Bài này cho ai:** dev hay nhảy thẳng vào code ở task phức tạp nên ra kết quả lan man/sai, hoặc tech lead chuẩn hóa flow plan → duyệt → implement cho team.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 01 — Vệ sinh context](./01-context-hygiene.md) để hiểu vì sao phải tách session plan và session implement.
> **Đọc xong bạn làm được:** vào plan mode bằng 3 cách; viết plan đủ 7 mục theo template; chạy flow 2 sessions (plan + implement) với phase-gate chống drift.
> **Thời gian:** ~40 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Plan mode | Chế độ read-only: được đọc/grep/đề xuất outline, không được sửa file hay chạy lệnh đổi trạng thái | `Shift+Tab` tới khi màn hình hiện chữ `plan` |
| `plan.md` | Bản đồ task lưu ra file — session sau mở lại là có ngay phương hướng | `plan.md` commit cùng code |
| Phase-gate | Cửa kiểm tra: phase xanh mới được sang phase tiếp | `pnpm --filter payments test types` xanh mới sang Phase 2 |

---

## 1. Vì sao plan-first thắng?

Plan mode rẻ (chỉ tokens suy nghĩ), code sai đắt (sửa + test + rewind): plan 1 turn (500–2000 tokens, 2 phút đọc, sai thì sửa chữ) vs code ngay 5 files sai (20K+ tokens + 5 turns sửa + rewind + test đỏ). Số liệu nội bộ team (không phải số chính thức): task >1 file mà không plan → 60% phải rewind ít nhất 1 lần; có plan duyệt → còn ~15%.

Ba lợi ích ngoài "đỡ sai": **(1) ép scope rõ** — plan bắt liệt kê files đụng/không đụng; **(2) chia verify được** — mỗi phase có gate test, bắt lệch sớm (mục 7); **(3) lưu được** — plan là file, session implement fresh vẫn có bản đồ, không phụ thuộc trí nhớ hội thoại ([Tips 01](./01-context-hygiene.md)).

Task 1 file, 1 bước, rõ ràng (đổi text, thêm log, sửa typo) → plan tốn hơn lợi. Xem mục 8.

---

## 2. Cơ chế plan mode

Plan mode = Claude **read-only**: được đọc file, grep, outline thay đổi, hỏi ngược, sinh plan markdown; không được `Edit`/`Write` source, chạy lệnh đổi trạng thái (migrate, deploy), commit. Hiểu nôm na: cho kiến trúc sư đi đo đạc, cấm thợ đụng búa. Bên trong: permissions siết (Edit/Write bị chặn, Bash read-only tùy config); plan là markdown có cấu trúc, save được ra `plan.md`; vòng sửa chữ rẻ — bạn chê → Claude sửa chữ 2–3 vòng, mỗi vòng vài trăm tokens; thoát plan = duyệt ("ok, implement" hoặc `Shift+Tab` về default) → mới được code.

> Dòng chảy: **Explore read-only** (rẻ) → **Plan chờ duyệt** (sửa chữ 2–3 vòng) → save `plan.md` → `/clear` → **Implement từng phase có gate** (đỏ thì dừng, rewind 1 phase).

---

## 3. Vào plan mode: 3 cách

### Cách 1 — `Shift+Tab` xoay chế độ

```text
default → acceptEdits → plan → auto → bypass → (quay về default)
```

- Màn hình hiện chữ `plan` là đang ở plan mode; `Shift+Tab` tiếp để thoát khi muốn implement.
- Lưu ý mới (từ w32/2026): **auto mode là permission mode mặc định cho session mới** trên Pro/Max/Team — nên vòng xoay của bạn thường bắt đầu từ `auto` chứ không phải `default`.
- `Shift+Tab` không ăn → chạy `/terminal-setup` (iTerm2/VSCode/Kitty/...), xem [Tips 10](./10-debugging-power-moves.md).

### Cách 2 — Gõ `/plan`

```bash
/plan
# → ép vào plan mode ngay, khỏi xoay Shift+Tab
```

### Cách 3 — Dặn bằng lời (không cần nhớ phím)

```text
"Trước khi làm gì, trình plan chi tiết và chờ duyệt. Không sửa code trong message này."
```

Hợp cho người mới và người không viết code (xem [Tips 02](./02-prompt-engineering.md)). Mẹo: kết hợp `Shift+Tab` vào plan + câu dặn "không code, chỉ plan" để khóa 2 lớp; sau plan, `git status` phải sạch (không diff lén).

---

## 4. Plan tốt gồm gì (7 mục + template)

Thiếu 1 mục là lúc implement phải đoán.

- [ ] **1. Đọc gì:** files đã đọc + sẽ đọc (đường dẫn cụ thể, không "vài files auth").
- [ ] **2. Sửa gì:** files sẽ sửa/tạo/xóa (đường dẫn + hàm chính mỗi file).
- [ ] **3. Thứ tự steps:** mỗi step 1 việc + ước lượng rủi ro.
- [ ] **4. Không đụng gì:** cấm địa (`generated/`, schema, `main`, dep mới).
- [ ] **5. Risks/edge cases:** top 3 rủi ro + case biên (null, empty, unicode, concurrent).
- [ ] **6. Verify từng phase:** lệnh test/lint nào, log thế nào là pass. **7. Cửa chia phase + gate:** xong phase N + test xanh mới sang N+1.

**Template plan chuẩn (bảo Claude trả đúng khung này):**

```markdown
# Plan: <tên task 1 dòng>

## Mục tiêu
- <end-state 2 dòng>

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

### Ví dụ 1 — Feature payments (đủ 7 mục)

```text
Tôi muốn thêm refund cho POST /api/payments.

Trước khi code, trình plan gồm:
- Code nào sẽ đọc (liệt kê đường dẫn), files nào sẽ sửa (đường dẫn + hàm)
- Steps theo thứ tự + risks/edge cases (idempotency, partial refund, webhook)
- Cái gì KHÔNG đụng (schema? API cũ? generated/?)
- Cách verify chính xác từng phase (lệnh test nào, log nào là pass)
Chờ tôi duyệt mới implement. Không sửa code trong message này.
```

### Ví dụ 2 — Refactor tách file lớn (ép chia phase)

```text
Tôi muốn tách src/auth.ts (~800 dòng) thành login/session/types, giữ public API.

Vào plan mode. Trình plan gồm 3 phases, mỗi phase có verify gate
(`pnpm --filter auth test` xanh mới sang phase tiếp).
Liệt kê hàm nào di chuyển đi đâu + 3 risks lớn nhất.
Chờ duyệt. Không code.
```

### Ví dụ 3 — Khảo sát khó + prompt ngắn khi đã quen

```text
Trước khi làm gì, explore src/queue/worker.ts + docs/queue.md rồi trình plan:
- Flow hiện tại (5 bullet) + root cause nghi ngờ (2 giả thuyết + evidence)
- 2 phương án fix (pros/cons 3 bullet mỗi cái) + đề xuất 1 cái + cách verify
Chờ tôi chọn phương án mới implement.
```

Khi đã quen, chỉ cần 1 dòng: `"Vào plan mode. Trình plan 3 phases refund, mỗi phase có verify gate. Chờ duyệt. Không code."`

---

## 6. Tách 2 sessions cho task lớn (plan-then-execute)

Vì sao 2 sessions? Vì **context xuống cấp** ([Tips 01](./01-context-hygiene.md)): session research mang 30K rác explore vào người → session implement ngáo. Tách ra là sạch.

```text
Session A (plan, 20-30 phút):
1. Shift+Tab vào plan (hoặc /plan), paste 1 trong 4 ví dụ mục 5.
2. Sửa plan 2-3 vòng bằng chữ (không code): "phase 2 tách nhỏ hơn", "thêm edge unicode".
3. Chốt → save plan.md (commit hoặc copy clipboard).

Session B (fresh, implement):
1. /clear hoặc terminal mới, paste plan.md + câu lệnh implement (dưới).
2. Làm phase-by-phase, verify từng phase, dừng khi đỏ.
```

**Câu lệnh mở Session B (copy-paste):**

```text
Đọc plan.md. Chỉ làm Phase 1 (ghi tên phase).
Thực hiện step-by-step, chạy lệnh verify của phase và dán log pass/fail.
Xong phase 1 + test xanh mới hỏi tôi có sang phase 2 không. Không đụng phase khác.
```

**Biến thể cho team (không đồng bộ):** người A (senior) làm Session A, `git add plan.md && git commit -m "plan: refund payments (3 phases)" && git push` + PR draft; người B (junior/agent) làm Session B từ plan.md, không cần họp lại.

---

## 7. Walkthrough: feature payments 2 ngày

**Bối cảnh:** thêm `POST /api/payments/:id/refund`, repo Node + pnpm.

| Lúc | Session | Làm gì (prompt copy-paste) |
|---|---|---|
| Ngày 1 sáng | Explore (15p) | `"Dùng subagent explore src/payments/*.ts. Trả files liên quan refund, flow charge 6 bullet + 2 chỗ dễ gãy khi thêm refund. Không code."` → lưu vào plan.md |
| Ngày 1 chiều | Plan (25p) | Shift+Tab tới `plan` → paste Ví dụ 1 → sửa 2 vòng (`"Thêm edge idempotency-key + partial refund"`, `"Phase 2 tách 2a service + 2b endpoint"`) → save + commit plan.md |
| Ngày 2 sáng | Implement P1+P2a | `/clear` → `"Đọc plan.md. Chỉ làm Phase 1. Verify bằng pnpm --filter payments test rồi dán log. Dừng sau phase 1."` → xanh → `/clear` → P2a |
| Ngày 2 chiều | P2b+P3 + review | Mỗi phase 1 session fresh. Xong P3: `"Spawn reviewer subagent fresh. Review git diff với plan.md. Finding = bug/security/test-gap. [SEVERITY] file:line — fix."` → `/verify` → mở PR |

Tổng: 5–6 sessions gọn thay vì 1 session 90% đầy rác.

---

## 8. Phase-gate chống lệch plan (drift)

Đừng duyệt 1 plan khổng lồ 15 steps rồi thả model chạy 1 mạch — nó sẽ drift: tự chế thêm, bỏ verify, sửa lan.

**Công thức gate:** mỗi phase có việc + verify lệnh + điều kiện sang phase tiếp; xong + log xanh mới được đụng phase N+1; phase đỏ → dừng toàn bộ, báo blocker, không vá lén.

**Ví dụ gate trong plan.md:**

```markdown
## Phase 1 — Types + validator
- Việc: thêm RefundRequest/RefundResult trong src/payments/types.ts
- Verify: `pnpm --filter payments test types` xanh
- Gate: xanh mới sang Phase 2. Đỏ → dừng, dán log.

## Phase 2a — Service refund()
- Việc: implement refund() idempotent trong src/payments/service.ts
- Verify: `pnpm --filter payments test service` xanh (gồm 2 cases mới)
```

Có gate vs không gate: không gate → chạy 1 mạch 10 steps, hỏng ở step 3 nhưng step 9 mới biết, tự thêm feature "cho tiện"; có gate → hỏng dừng ngay, rewind 1 phase, mọi thêm ngoài plan phải hỏi trước.

---

## 9. Khi nào plan vs làm luôn?

| Tín hiệu | Plan-first | Làm luôn |
|---|---|---|
| Số files | >1 file | 1 file |
| Số steps | >2 steps | 1–2 steps rõ ràng |
| Rủi ro | Đụng API/schema/migrate/auth/money | Đổi text, thêm log, typo |
| Ví dụ | Refund payments, tách file 800 dòng, fix race | Sửa label button, thêm log |

> Quy tắc ngón tay: **>1 file hoặc >2 steps → vào plan mode theo phản xạ.** Được bỏ plan nhưng vẫn an toàn khi đủ cả 3: (1) lệnh verify 1 dòng; (2) NEVER viết được trong 1 dòng; (3) rewind được trong 10 giây nếu sai (chưa push, chưa migrate).

---

## 10. Pitfalls + hiểu nhầm thường gặp

| Pitfall / Hiểu nhầm | Fix / Sự thật |
|---|---|
| Plan chung chung ("sửa vài files auth") | Ép template 7 mục (mục 4), đường dẫn đầy đủ |
| Plan 15 steps không gate | Chia ≤3–4 phases, mỗi phase có verify + gate |
| Plan trong session bẩn (70% rác) | `/clear` rồi mới plan; nạp `CLAUDE.md` + spec gọn |
| Duyệt plan vội (ok luôn) | Sửa plan ít nhất 1 vòng: hỏi "risks? edge? verify?" |
| Code lén trong plan mode | Dặn rõ "không sửa code message này"; check `git status` sau plan |
| 1 session làm hết plan 3 ngày | Mỗi phase 1 session fresh (mục 6) |
| Tin plan là đúng tuyệt đối | Plan là giả thuyết: phase 1 rẻ nhất để kiểm chứng, sai thì sửa plan |

---

## 11. Bài tập

1. **Xoay chế độ (15p):** `Shift+Tab` xoay hết vòng, chụp nhớ vị trí `plan`; thử `/plan` và dặn bằng lời — cái nào hợp bạn?
2. **Plan 1 feature thật (30p):** task >1 file trong backlog → prompt theo Ví dụ 1, ép 7 mục, sửa 2 vòng, save `plan.md`. Đếm: bao nhiêu files/risks bạn chưa nghĩ ra trước khi plan?
3. **2-session flow (45p):** Session A plan + commit; Session B fresh "chỉ làm Phase 1, verify rồi dừng". So số turns + số lần rewind với cách code ngay trước đây.

> Đạt: sau 2 tuần, mọi task >1 file của bạn đều có `plan.md` trước khi có diff.

---

## 12. Tham khảo chéo

- Lệnh: [plan](../01-huong-dan-su-dung/commands/model-mode/plan/README.md) · [clear](../01-huong-dan-su-dung/commands/session-context/clear/README.md) · [goal](../01-huong-dan-su-dung/commands/model-mode/goal/README.md) (completion condition cho plan dài) · [verify](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) · [terminal-setup](../01-huong-dan-su-dung/commands/auth-settings/terminal-setup/README.md) (fix Shift+Tab)
- Bài tips: [Tips 01](./01-context-hygiene.md) (tách sessions) · [Tips 02](./02-prompt-engineering.md) (prompt plan chuẩn) · [Tips 04](./04-verification-done-that.md) (verify từng phase) · [Tips 05](./05-parallel-agents.md) (planner + reviewer fresh)
