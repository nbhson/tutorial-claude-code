# /goal — Đặt điều kiện hoàn thành, evaluator tự check mỗi turn cho tới khi xong

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (không sửa file; chỉ đặt tiêu chí dừng + vòng check; tốn thêm tokens evaluator — cần ≥2.1.139)

`/goal` biến câu "làm cho xong" mơ hồ thành hợp đồng rõ ràng: bạn viết điều kiện hoàn thành ("tests pass + không lint error"), một evaluator (model phụ) check sau mỗi turn, task chỉ dừng khi đạt — hoặc khi bạn ngắt. Chống bệnh "model bảo xong nhưng thực ra chưa".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/goal <điều kiện>` | text tự nhiên | Đặt goal cho task hiện tại |
| `/goal` | _(không có)_ | Xem goal đang active |
| `/goal clear` | `clear` | Xóa goal (quy ước phổ biến, tùy bản) |
| `/goal <đk 1> + <đk 2>` | nhiều mệnh đề | Goal复合 — phải đạt tất cả mới dừng |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem goal hiện tại
/goal
```

```bash
# Dạng 2: goal đơn — test phải xanh
/goal pytest tests/payments/ pass 100%, không skip.
```

```bash
# Dạng 3: goal复合 — test + lint + không phá API
/goal Refactor xong khi: (1) pytest pass, (2) ruff không báo lỗi, (3) API cũ trong docs/api.md vẫn giữ nguyên.
```

```bash
# Dạng 4: goal cho migration — có verify bằng query thật
/goal Migrate xong khi: SELECT COUNT(*) khớp trước/sau, app staging boot được, rollback script chạy thử ok.
```

```bash
# Dạng 5: goal hiệu năng — có số đo
/goal Tối ưu xong khi: p95 API /search < 200ms trên dataset 100K rows (đo bằng script bench.sh).
```

```bash
# Dạng 6: xóa goal khi đổi hướng (tùy bản hỗ trợ)
/goal clear
```

```bash
# Dạng 7: kết hợp plan + goal (khuyên dùng)
/plan Thêm MoMo vào payments. Chỉ plan.
/goal Xong khi: pytest payments/ pass + webhook verify có test + API cũ không đổi.
```

---

## Cách nó hoạt động

### Cơ chế sâu: goal evaluator loop ra sao?

1. **2 vai trong 1 session:**
   - `worker` (model chính): làm task — đọc, sửa, chạy test.
   - `evaluator` (model phụ nhẹ hơn): sau mỗi turn worker, đọc diff + test output + checklist goal, trả về `PASS / FAIL + lý do + gợi ý bước tiếp`.
2. **Loop chi tiết từng turn:**
   - Turn N: worker edit 3 file → chạy pytest → 2 pass 1 fail.
   - Evaluator đọc output, so với goal "pass 100%" → `FAIL: test_checkout còn đỏ, lỗi assert total`.
   - Worker nhận feedback → turn N+1 chỉ fix chỗ đó, không lan man.
   - Lặp tới khi `PASS` hoặc bạn Ctrl+C / `/goal clear` / hết vòng giới hạn (tùy bản ~25–50 turns).
3. **Goal lưu ở đâu?**
   - Gắn với session/task hiện tại (không phải settings vĩnh viễn). `/clear` hoặc session mới là mất.
   - Xem lại bằng `/goal` (không tham số).
4. **Evaluator tốn gì?**
   - Mỗi turn tốn thêm 1 lần gọi model nhẹ (~500–1500 tokens) để chấm. Task 20 turns ≈ thêm ~20K tokens (~$0.05–0.10 sonnet). Rẻ so với làm sai phải làm lại.
   - Effort của evaluator thường theo effort chính (high → evaluator cũng kỹ).
5. **Goal vs plan vs verify:**
   - `/plan`: khóa tay trước khi làm.
   - `/goal`: giám sát trong khi làm (evaluator mỗi turn).
   - `/verify`: khám sau khi làm (build + chạy thật).
   - 3 lớp phòng thủ xếp chồng, không thay thế nhau.
6. **Goal mơ hồ = evaluator mù:**
   - "Làm cho đẹp" → evaluator không đo được → PASS ẩu.
   - "p95 < 200ms + pytest pass + ruff sạch" → đo được → evaluator nghiêm.
   - Quy tắc: goal phải có động từ đo được (pass, <, =, tồn tại file, output chứa X).

### Sơ đồ trạng thái

```text
Bạn: /goal "pytest pass + ruff sạch"
  → [GOAL ACTIVE]
Worker turn 1: sửa 2 file, pytest 3/5 pass
Evaluator: FAIL (2 test đỏ) → gợi ý đọc traceback
Worker turn 2: fix, pytest 5/5 nhưng ruff còn 2 lỗi
Evaluator: FAIL (lint) → gợi ý chạy ruff --fix
Worker turn 3: ruff sạch
Evaluator: PASS → task dừng, báo "goal đạt"
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Check khi nào? | Ai check? | Dùng khi nào? |
|---|---|---|---|
| `/goal` | Mỗi turn tự động | Evaluator model | Task dài, sợ "xong ẩu" |
| `/verify` | 1 lần sau khi xong (bạn gọi tay) | Build + app thật chạy | Cần bằng chứng chạy được |
| `/plan` duyệt tay | Khi bạn rảnh đọc | Chính bạn | Task kiến trúc cần duyệt người |
| Prompt "nhớ test nhé" | Không check | Không ai | Không tin được — model quên |

> Quy tắc ngón tay cái:
>
> - **Task > 5 turns → đặt `/goal`.**
> - **Task tiền thật/migration → `/goal` + `/verify`.**

### Khi nào goal KHÔNG đủ?

- Goal sai (tiêu chí thấp: "code chạy được là xong" mà không đòi test) → evaluator PASS nhưng chất lượng kém. Viết goal kỹ.
- Task cần duyệt người (kiến trúc): evaluator chỉ check kỹ thuật, không check "hướng này có đúng chiến lược không" — vẫn cần `/plan` duyệt tay.
- Infinite loop: goal quá khó ("p95 < 10ms" bất khả thi) → loop tới giới hạn, tốn tiền. Đặt goal khả thi + ngắt tay khi thấy stuck 5 turns.

---

## Ví dụ thực tế

### Kịch bản 1: Refactor auth — chống "xong ẩu" kinh điển

Không goal: model sửa 5 file, chạy 1 test xanh, bảo "xong" — nhưng 3 test khác đỏ mà nó không chạy.

```bash
# Bước 1: đặt goal trước khi cho làm
/goal Refactor src/auth/ xong khi: pytest tests/auth/ pass toàn bộ (không skip),
ruff + mypy sạch, và grep "old_login" không còn kết quả trong src/.
```

```bash
# Bước 2: giao việc
Tách hàm login() trong src/auth/login.py thành 3 hàm nhỏ, giữ nguyên behavior.
```

> Diễn biến: turn 1 model xong sớm, evaluator FAIL vì mypy còn 2 lỗi → turn 2 fix typing → turn 3 PASS. Bạn không cần canh từng turn.

### Kịch bản 2: Tối ưu hiệu năng — goal có số đo

```bash
/goal Tối ưu xong khi: python bench.py cho p95 < 200ms (hiện 800ms),
kết quả in ra màn hình, và pytest vẫn pass (không đánh đổi đúng đắn lấy tốc độ).
```

```bash
Thêm index + fix N+1 trong src/api/search.py. Mỗi phương án thử phải bench và báo số.
```

> Evaluator ép model bench thật thay vì đoán ("chắc nhanh hơn"). Không có goal số đo, model hay bảo "đã tối ưu" mà không đo.

### Kịch bản 3: Migration DB — goal là bằng chứng, không phải lời hứa

```bash
/goal Migrate xong khi: (1) COUNT(*) users trước/sau bằng nhau (paste output 2 query),
(2) app staging boot thành công (paste log), (3) file rollback.sql tồn tại và chạy thử ok.
```

> Giá trị: evaluator đòi paste output thật, không chấp nhận "em nghĩ là được".

### Kịch bản 4: Goal sai → sửa goal (bài học)

```bash
# Goal ban đầu quá ẩu
/goal Làm dark-mode cho xong.

# → evaluator PASS sau 2 turns nhưng UI vỡ 3 chỗ.
# Sửa goal cụ thể hơn:

/goal Dark-mode xong khi: (1) 10 màn trong checklist.md đều có screenshot,
(2) contrast ratio ≥ 4.5 (dùng tool check), (3) không còn hardcode màu trắng trong src/styles/.
```

---

## Rủi ro & lưu ý

### Tốn token?

- Evaluator mỗi turn ~0.5–1.5K tokens. Task 20 turns ≈ +10–30K tokens (~$0.05–0.15 sonnet, ~$0.25–0.50 opus).
- Nhưng tiết kiệm được vòng "bạn tự review phát hiện sai → bắt làm lại" (mỗi vòng đó tốn 5–10K + thời gian bạn).
- Mẹo: task < 3 turns thì khỏi goal (overhead không đáng). Task > 5 turns thì goal luôn lời.

### Destructive?

- Không. Goal chỉ check, không mở thêm quyền ghi. Nhưng goal + `bypassPermissions` = model loop 30 turns tự sửa không hỏi — tốn tiền + có thể sửa lan. Giữ `acceptEdits`.

### Version floor: /goal ≥2.1.139

- Bản cũ hơn gõ `/goal` báo `unknown command`. Update: `npm i -g @anthropic-ai/claude-code` rồi `claude --version` xác nhận ≥2.1.139.
- Hành vi evaluator (số turns tối đa, model evaluator) thay đổi theo bản — đọc changelog khi update.

### Provider thiếu gì?

- Bedrock/Vertex khóa một số tools test (Bash chạy pytest bị chặn) → evaluator không có output để chấm → FAIL mãi. Fix: cho evaluator đọc log bạn paste tay, hoặc mở quyền Bash đọc/chạy test.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/plan` + `/goal` | Task lớn: plan duyệt tay + goal giám sát | `/plan ...` → `/goal "..."` → duyệt từng bước |
| `/goal` + `/verify` | Task tiền thật: evaluator + chạy thật | `/goal ...` → làm → `/verify` |
| `/goal` + `/effort high` | Bài khó cần nghĩ sâu + check kỹ | `/effort high` + `/goal ...` |
| `/goal` + `/loop` | Lặp task tới khi đạt chuẩn | `/goal ...` + `/loop ...` |
| `/goal` + `/batch` | Nhiều worktree, mỗi đứa 1 goal | Mỗi batch prompt kèm goal riêng |

Workflow chuẩn "task dài tự giám sát":

```bash
# 1. Plan (nếu lớn)
/plan Refactor payments. Chỉ plan.

# 2. Goal đo được
/goal Xong khi: pytest payments/ pass + ruff sạch + API cũ không đổi.

# 3. Effort phù hợp
/effort high

# 4. Giao việc, để loop chạy
Thực hiện bước 1-2 của plan.

# 5. Sau PASS → verify thật
/verify
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/goal` báo `unknown command` | Bản < 2.1.139 | Update CLI ≥2.1.139 |
| Evaluator PASS ẩu dù còn lỗi | Goal mơ hồ ("làm cho xong") | Viết lại goal có số đo (pass, <, file tồn tại) |
| Loop mãi không PASS (20+ turns) | Goal bất khả thi hoặc thiếu tools test | Hạ goal khả thi; kiểm tra Bash/pytest có bị chặn không; ngắt tay |
| Đặt goal rồi model bỏ qua, làm 1 turn bảo xong | Goal chưa active (gõ sai) hoặc task quá ngắn | Gõ `/goal` kiểm tra active; task ngắn không cần goal |
| `/goal clear` không có tác dụng | Bản chưa hỗ trợ clear | Gõ goal mới đè lên, hoặc `/clear` session mới |
| Evaluator FAIL mãi vì "thiếu output test" | Bash chạy test bị permissions chặn | Mở quyền Bash test trong `/permissions`, hoặc paste log tay |
| Goal mất sau restart | Goal gắn session, không persistent | Đặt lại mỗi session; ghi goal vào file task để copy-paste |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../plan/README.md](../../model-mode/plan/README.md) — duyệt hướng trước khi goal giám sát
  - [../verify/README.md](../../code-repo/verify/README.md) — bằng chứng chạy thật sau PASS
  - [../loop/README.md](../../code-repo/loop/README.md) — lặp task tới khi goal đạt
  - [../effort/README.md](../../model-mode/effort/README.md) — effort cao cho task goal khó
  - [../batch/README.md](../../code-repo/batch/README.md) — mỗi worktree 1 goal riêng
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _task dài mà không có `/goal` thì như thi không có đáp án — model chấm ẩu cho qua._
