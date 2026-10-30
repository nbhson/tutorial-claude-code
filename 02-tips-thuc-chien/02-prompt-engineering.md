# Tips 02 — Prompt engineering: viết sao, ra vậy

> **Bài này cho ai:** dev hay gõ prompt rồi nhận output lan man, hoặc người mới (kể cả không viết code) muốn Claude Code ra kết quả đúng ngay lần đầu.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); không bắt buộc đọc gì thêm.
> **Đọc xong bạn làm được:** viết prompt đủ 4 thành phần + 3 gia vị; chọn đúng 1 trong 6 mẫu prompt theo task; tự chấm prompt theo bảng sai→sửa và checklist trước khi bấm Enter.
> **Thời gian:** ~40 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Scope (files nào) | Khoanh vùng model được phép đọc/sửa — càng hẹp càng rẻ | `Chỉ đọc src/auth/login.ts + __tests__/login.test.ts` |
| End-state | Trạng thái "xong" trông thế nào, không phải đang làm gì | `Tách auth.ts thành 3 modules, giữ public API, test xanh` |
| Verify | Dặn model tự chạy check rồi dán kết quả, thay vì "chắc đúng" | `Chạy pnpm --filter auth test và dán log` |

---

## 1. Vì sao prompt quyết định output?

Claude Code không đọc được ý nghĩ. Nguyên nhân #1 của "sửa lan man, đọc 100 files, đổi API không hỏi" là bạn cho model **quyền tự do quá rộng**: `"investigate auth"` với repo 500 files = mời model đi lạc; `"fix login"` không scope = model tự đoán scope, done, verify. Prompt tốt làm 3 việc: **(1) thu hẹp search space** (500 files → 5 files), **(2) định nghĩa done có thể check** ("cho sạch" → "`pnpm test auth` xanh"), **(3) gài vòng lặp tự sửa** ("chạy X và iterate trong message này"). Đắt rẻ: prompt kỹ 2 phút → tiết kiệm 20 phút sửa + rewind; prompt ẩu 10 giây → 5 turns cãi nhau, mỗi turn gánh thêm rác vào context ([Tips 01](./01-context-hygiene.md)).

---

## 2. Giải phẫu prompt tốt: 4 thành phần

Thiếu 1 mảnh là output lệch 1 hướng.

### 2.1. Files nào (scope)

```text
TỐT: "Chỉ đọc src/auth/login.ts + src/auth/__tests__/login.test.ts"
TỐT: "Scope src/payments/*.ts, đừng đụng src/legacy/"
TỐT: "Scope src/payments/*.ts, đừng đụng src/legacy/"
```

Mẹo: dùng `@` để nạp file (`@src/auth/login.ts`); file >1000 dòng → bảo subagent tóm tắt, main chỉ nhận outline; không có code (data/docs) → thay "files" bằng "nguồn" (`/data/feedback-q3.csv`).

### 2.2. Tìm/tạo gì (end-state, không phải activity)

Mô tả **trạng thái cuối**, không mô tả hoạt động. Công thức: **động từ + đối tượng + tiêu chuẩn chấp nhận**.

```text
TỆ (activity):  "Analyze this data" / "Xem giúp auth" / "Refactor cho sạch"
TỐT (end-state): "Top 5 complaints theo frequency, mỗi dòng: quote + count + segment, markdown table"
TỐT (end-state): "Tách src/auth.ts (>500 dòng) thành 3 modules, giữ public API, test xanh"
```

### 2.3. Chi tiết nào + format output nào

Không chỉ định format = nhận format ngẫu nhiên (lúc table, lúc prose dài, lúc JSON gãy). Chỉ định rõ độ phân giải (columns, quotes, counts, edge cases) và format:

```text
TỐT data: "Mỗi dòng: quote nguyên văn + count + segment. Đối chiếu totals summary vs raw, lệch thì fix trước khi show."
TỐT code: "Liệt kê files sẽ sửa (đường dẫn đầy đủ), hàm nào đổi signature, test nào phải giữ xanh."
TỐT: "Output markdown table: | File | Việc | Verify |"
TỐT: "Trả về plan markdown lưu vào plan.md: steps + risks + verify từng phase."
```

### 2.4. Ví dụ tổng hợp

```text
TỐT: "Đọc /data/feedback-q3.csv. Tìm top 5 complaints theo frequency.
Mỗi dòng: quote nguyên văn + count + segment. Output markdown table.
Xong đối chiếu totals ở summary vs raw data, lệch thì fix trước khi show.
Không tạo file mới, chỉ trả lời trong chat."
```

Files: 1 file · End-state: top 5 · Chi tiết: quote+count+segment+đối chiếu · Format: markdown table.

---

## 3. Ba gia vị nâng chất lượng 10x

### 3.1. Tiêu chí thành công — done phải check được bằng lệnh

```text
TỐT: "Done = `pnpm --filter auth test` xanh + `pnpm lint` 0 error + `git diff --stat` chỉ chạm apps/auth/**"
```

Xem thang verification ở [Tips 04](./04-verification-done-that.md).

### 3.2. Cách verify — bắt model tự lặp trong message

```text
"Sau khi sửa, chạy `pnpm --filter auth test` và dán log pass/fail.
Nếu đỏ, fix tiếp trong message này tới khi xanh hoặc dừng sau 3 lần và báo blocker."
```

Biến thể data/docs: `"Sau khi ra table, đối chiếu tổng counts với `wc -l` raw file. Lệch >1% thì kiểm tra lại trước khi show."`

### 3.3. Ràng buộc phủ định (NEVER) — không dặn là model sẽ đụng

```text
"Đừng đụng `src/generated/`, đừng đổi DB schema, đừng commit thẳng main, đừng thêm dependency mới."
"Chỉ sửa trong src/payments/. Không refactor file khác 'cho tiện'. Không xóa test cũ để cho xanh."
```

Mẹo: gom ràng buộc chung vào `CLAUDE.md` (tự áp mọi turn), chỉ để ràng buộc riêng task trong prompt.

---

## 4. Sáu mẫu prompt theo task (copy-paste)

### Mẫu 1 — BUG (fix tối thiểu + regression test)

```text
BUG: Tái hiện lỗi [mô tả + steps tái hiện + log lỗi paste kèm].
1. Tìm root cause trong <module>, giải thích 3 bullet trước khi sửa.
2. Fix tối thiểu, không refactor lan man, không đổi public API.
3. Thêm 1 regression test cover case này.
4. Chạy focused test `pnpm --filter <pkg> test <file>` và dán kết quả. Đỏ thì fix tiếp trong message này.
Ràng buộc: đừng đụng <liệt kê cấm địa>.
```

### Mẫu 2 — FEATURE (plan trước, code sau)

```text
FEATURE: Tôi muốn <mục tiêu 1 câu>.
Trước khi code:
1. Đọc <tối đa 3 file liên quan, ghi đường dẫn>.
2. Trình plan gồm: files sẽ đọc/sửa, steps theo thứ tự, risks/edge cases, cái gì KHÔNG đụng, cách verify từng phase.
3. Chờ tôi duyệt mới implement. Không code trong message này.
Output: markdown plan, lưu vào plan.md.
```

### Mẫu 3 — REFACTOR (giữ API + gate từng bước)

```text
REFACTOR: Tách file <X, vd src/auth.ts ~900 dòng> thành modules <vd auth/login, auth/session, auth/types>.
- Giữ nguyên public API (export cũ vẫn import được).
- Làm từng bước nhỏ, chạy full test `pnpm test <scope>` sau mỗi bước.
- Dừng và báo ngay nếu test đỏ, không cố vá tiếp.
- Cuối cùng dán `git diff --stat` + log test xanh.
```

### Mẫu 4 — RESEARCH (subagent + output chuẩn)

```text
RESEARCH: Dùng subagent explore <phạm vi hẹp, vd src/payments/refund*>.
- Không sửa code, chỉ đọc.
- Trả về: (1) files liên quan (đường dẫn + 1 dòng vai trò), (2) flow hiện tại (5-8 bullet),
  (3) 2 phương án thay đổi (pros/cons mỗi cái 3 bullet).
- Không dump log dài.
```

### Mẫu 5 — REVIEW (adversarial, có severity)

```text
REVIEW: Review diff này với plan trong plan.md.
- Finding = bug/correctness/security/test-gap thực sự. Bỏ qua style preferences.
- Trả về: [SEVERITY: HIGH/MED/LOW] file:line — mô tả 1 dòng — gợi ý fix 1 dòng.
- Cuối cùng: verdict PASS / NEEDS-FIX + 3 gaps ưu tiên cao nhất.
```

### Mẫu 6 — DATA / DOCS (coder và non-coder đều dùng)

```text
DATA: Đọc <file csv/docs, vd /data/feedback-q3.csv>.
- Tìm <câu hỏi cụ thể, vd top 5 complaints theo frequency>.
- Mỗi kết quả kèm evidence: quote/số dòng/file:line.
- Đối chiếu chéo (totals, wc -l, summary) trước khi show. Lệch thì báo lệch.
- Output: markdown table + 3 bullet insight + 1 dòng "confidence: cao/trung/thấp vì...".
```

---

## 5. Walkthrough: từ prompt tệ tới prompt tốt

**Tình huống:** refactor `auth.ts` 800 dòng.

```text
Round 0 (tệ):  "Refactor auth cho sạch"
→ đọc 40 files, đổi luôn API, thêm dependency, test đỏ 5 chỗ. Mất 45 phút rewind.

Round 2 (đạt chuẩn, sau khi thêm scope + end-state + verify + constraints):
"Refactor src/auth.ts (~800 dòng) thành src/auth/login.ts, session.ts, types.ts.
Giữ nguyên public API (file cũ re-export để không gãy import).
Sau mỗi bước chạy `pnpm --filter auth test` và dán log. Đỏ thì dừng và báo.
Đừng đụng src/generated/, đừng thêm dep mới, đừng commit.
Trước khi code, trình outline 5 bullet files/hàm sẽ di chuyển và chờ duyệt."
→ 1 turn plan + 3 turns implement sạch, test xanh, `git diff --stat` gọn. 15 phút.
```

Bài học: **mỗi vòng thêm 1 thành phần (scope → end-state → verify → constraints → format) là bớt 2–3 turns sửa.**

---

## 6. Bảng sai→sửa

| Sai (prompt ẩu) | Vì sao hỏng | Sửa (copy ý này) |
|---|---|---|
| `"investigate auth"` (không scope) | Đọc 300 files, tốn 30K tokens | Khoanh module + câu hỏi + output format |
| Một prompt 5 việc không liên quan | Context nhiễm, việc nọ lẫn việc kia | Tách 5 prompts/sessions, `/clear` giữa ([Tips 01](./01-context-hygiene.md)) |
| Không cho cách verify | "Xong rồi (chắc vậy)" | Kèm check: test/lint/log/diff + dán evidence |
| Mô tả solution thay vì problem | Ép model theo hướng sai từ đầu | Mô tả problem + constraints, để plan mode đề xuất solution |
| `"làm cho nhanh"` | Model cắt test, cắt verify | `"làm tối thiểu nhưng test phải xanh, dán log"` |
| Không ràng buộc phủ định | Sửa lan sang file cấm | Liệt kê NEVER: generated/, schema, main, dep mới |

---

## 7. Hướng dẫn cho người không viết code

Cùng công thức 4 thành phần, chỉ thay từ ngữ:

| Coder nói | Non-coder nói |
|---|---|
| Files | Nguồn: data folder, docs, sheet, email export |
| Test xanh | Đối chiếu số liệu (totals, wc -l, summary) |
| Diff | So sánh trước/sau (table cũ vs mới) |
| Lint | Checklist chính tả / format |

**Prompt khởi động (copy-paste):**

```text
"Phỏng vấn tôi để hiểu project này, rồi tạo CLAUDE.md.
Hỏi từng câu một: project làm gì, dữ liệu ở đâu, output muốn gì,
cái gì không được đụng. Khi đủ thì sinh CLAUDE.md <100 dòng."
```

→ Bạn chỉ cần trả lời hội thoại, Claude lo cấu trúc. Sau đó mọi prompt tiếp theo tự gọn vì đã có `CLAUDE.md`.

---

## 8. Checklist trước khi Enter

- [ ] Có **scope** cụ thể (files/thư mục/đường dẫn)?
- [ ] Có **end-state** (xong thì trông thế nào, không phải "cố gắng")?
- [ ] Có **độ phân giải** (columns, counts, edge cases cần cover)?
- [ ] Có **format output** (table, plan.md, JSON, bullet + file:line)?
- [ ] Có **success criteria** check được bằng lệnh/số + **cách verify** dặn iterate trong message?
- [ ] Có **ràng buộc NEVER** (cấm địa, không commit, không đổi API)?
- [ ] Task >1 file hoặc >2 steps → đã thêm "trình plan, chờ duyệt"? File >1000 dòng → đã tách hoặc giao subagent?
- [ ] 1 prompt 1 việc (không gộp 5 việc)?

---

## 9. Bài tập

1. **Mổ prompt cũ (10p):** lấy 3 prompts gần nhất, chấm theo 4 thành phần — thiếu mảnh nào? Viết lại prompt tệ nhất thành bản đủ 4 mảnh + verify + NEVER.
2. **Dùng 6 mẫu (20p):** 1 bug thật theo Mẫu 1 + 1 feature thật theo Mẫu 2. Đếm số turns tới done: bug ≤4 turns, feature có plan duyệt trước khi code.
3. **Non-coder (15p):** dùng prompt phỏng vấn mục 7 để tạo `CLAUDE.md`; nhờ 1 đồng nghiệp không viết code dùng Mẫu 6 hỏi dữ liệu — họ có cần bạn "dịch" không?

> Thước đo: sau 1 tuần, ≥80% prompts của bạn có scope + verify + NEVER mà không cần cố nhớ.

---

## 10. Tham khảo chéo

- Lệnh kèm prompt: [plan](../01-huong-dan-su-dung/commands/model-mode/plan/README.md) · [goal](../01-huong-dan-su-dung/commands/model-mode/goal/README.md) · [verify](../01-huong-dan-su-dung/commands/code-repo/verify/README.md) · [loop](../01-huong-dan-su-dung/commands/code-repo/loop/README.md) · [code-review](../01-huong-dan-su-dung/commands/code-repo/code-review/README.md) · [batch](../01-huong-dan-su-dung/commands/code-repo/batch/README.md)
- Bài tips: [Tips 01](./01-context-hygiene.md) (scope gọn) · [Tips 03](./03-plan-first-workflow.md) (plan-first) · [Tips 04](./04-verification-done-that.md) (done criteria + adversarial review) · [Tips 05](./05-parallel-agents.md) (giao việc subagent bằng prompt hẹp)
