# /plan — Chế độ lập kế hoạch: chỉ đọc + viết plan, cấm sửa code cho tới khi duyệt

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (bản thân plan mode an toàn — cấm ghi/sửa file; nguy hiểm chỉ khi bạn duyệt plan ẩu rồi cho chạy bypass sau đó)

`/plan` (và mode `plan` trong vòng xoay Shift+Tab) khóa Claude Code ở trạng thái "chỉ được nhìn, không được chạm": đọc file, search, vẽ kiến trúc, viết plan từng bước — nhưng mọi Edit/Write/Bash ghi đều bị chặn. Bạn duyệt plan rồi mới cho thực thi. Đây là phanh an toàn số 1 cho task lớn.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/plan` | _(không có)_ | Vào plan mode cho session hiện tại |
| `/plan <mô tả task>` | text sau lệnh | Vào plan mode + yêu cầu lập plan cho task đó luôn |
| Shift+Tab | _(xoay mode)_ | `default` → `acceptEdits` → `plan` → `auto` → `bypassPermissions` |
| Duyệt plan | `Enter / Yes` trên picker | Thoát plan, cho phép thực thi |
| Từ chối / chỉnh | `No / feedback text` | Giữ plan mode, bắt lập lại |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: vào plan mode trống rồi giao việc
/plan
```

```bash
# Dạng 2: vào plan + giao task trong 1 bước (khuyên dùng)
/plan Thiết kế lại module payments từ Stripe đơn lẻ sang multi-provider (Stripe + MoMo + VNPay).
Không code vội — chỉ đọc code hiện tại và đưa plan từng bước.
```

```bash
# Dạng 3: xoay bằng Shift+Tab (không gõ lệnh)
# Nhấn Shift+Tab cho tới khi status bar hiện "plan"
```

```bash
# Dạng 4: plan cho migration nguy hiểm
/plan Migrate DB users từ 1M rows sang schema mới, yêu cầu zero-downtime.
Liệt kê từng migration step, rollback cho mỗi step, và cách verify.
```

```bash
# Dạng 5: plan xong → duyệt → thực thi có kiểm soát
# (sau khi đọc plan, gõ:)
Thực hiện bước 1-2 thôi, dừng lại cho tôi review trước khi làm bước 3.
```

```bash
# Dạng 6: thoát plan mà không thực thi (đổi ý)
/plan
# ... đọc plan ...
# → gõ: Thôi không làm nữa, quay lại mode thường.
# Hoặc Shift+Tab về acceptEdits
```

---

## Cách nó hoạt động

### Cơ chế sâu: plan mode khóa tools nào?

1. **Allowlist khi ở plan:**
   - ĐƯỢC: `Read`, `Glob`, `Grep`, `Glob-search`, `WebFetch`, `WebSearch`, `TodoWrite` (lập todos), `AskUser` (hỏi lại bạn).
   - BỊ CHẶN: `Edit`, `Write`, `NotebookEdit` (mọi ghi file), `Bash` ghi (mkdir, rm, git commit, npm install...), `MCP` tools có tính ghi.
   - `Bash` đọc (ls, git status, git log, cat) thường vẫn được — tùy `permissions` cấu hình.
2. **Chặn ở 2 lớp:**
   - Lớp 1 — model tự từ chối: system prompt ở plan mode dặn "không gọi tools ghi".
   - Lớp 2 — permission gate cứng: dù model cố gọi Edit, executor chặn và báo `permission denied (plan mode)`. Không có đường vòng prompt-injection.
3. **Plan artifact lưu ở đâu?**
   - Plan hiển thị trong chat + thường được ghi vào `~/.claude/plans/<slug>.md` hoặc file bạn chỉ định (tùy bản).
   - Bạn có thể bảo "lưu plan vào docs/plans/payments-v2.md" — ở plan mode model không tự ghi được, nó sẽ đưa nội dung để bạn paste (hoặc xin tạm quyền ghi 1 file).
4. **Duyệt plan = mở khóa có điều kiện:**
   - Khi bạn gõ "ok / thực hiện đi", session thoát plan → về `acceptEdits` (vẫn hỏi trước mỗi ghi nguy hiểm) trừ khi bạn Explicit chọn `bypass`.
   - Plan tốt có checkboxes từng bước → thực thi tới đâu tick tới đó (`/todos` đồng bộ).
5. **Plan mode vs /goal vs /verify:**
   - `/plan`: khóa tay trước khi làm (phòng bệnh).
   - `/goal`: đặt tiêu chí xong để evaluator check mỗi turn (giám sát trong khi làm).
   - `/verify`: build + chạy thật sau khi làm (khám sau).
   - Combo chuẩn: plan trước → goal giữa → verify sau.
6. **Model nào plan tốt nhất?**
   - `opus + high` cho plan kiến trúc (khôn, thấy trade-off).
   - `sonnet + medium` đủ cho plan task vừa (CRUD, refactor nhỏ).
   - Đừng `haiku + low` cho plan lớn — plan ẩu thì thực thi sai cả chặng.

### Sơ đồ trạng thái

```text
[default/acceptEdits] --/plan--> [PLAN MODE: chỉ đọc]
                                      |
                        model đọc 10 file, vẽ plan 8 bước
                                      |
                        bạn review: ok? sửa? bỏ?
                        /         |           \
                   duyệt hết   duyệt 1-2 bước   từ chối
                      |            |                |
              [acceptEdits]  [acceptEdits]    [vẫn plan, lập lại]
              chạy cả plan   chạy từng phần
```

### Khác gì với lệnh dễ nhầm?

| Chế độ | Đọc? | Ghi? | Hỏi trước khi ghi? | Dùng khi nào? |
|---|---|---|---|---|
| `plan` (`/plan`) | Có | Không (chặn cứng) | N/A | Task lớn, chưa chắc hướng |
| `default` | Có | Có | Hỏi khi nhạy cảm | Hàng ngày |
| `acceptEdits` | Có | Có (auto file thường) | Hỏi khi nguy hiểm | Làm việc đã rõ |
| `auto` | Có | Có (ít hỏi hơn) | Ít hỏi | Task tin tưởng, vẫn muốn phanh |
| `bypassPermissions` | Có | Có (không hỏi) | Không | Chỉ CI/sandbox, không dùng tay |

> Quy tắc ngón tay cái:
>
> - **Chưa biết làm thế nào → `/plan` trước.**
> - **Biết rồi, việc rõ → `acceptEdits` làm thẳng.**
> - **Không bao giờ `bypass` bằng tay trên máy thật.**

### Khi nào /plan KHÔNG đủ?

- Plan hay nhưng thiếu tiêu chí xong → thêm `/goal` ("khi nào gọi là xong?").
- Plan涉及 tiền thật (payments) → sau thực thi phải `/verify` chạy thật, không tin plan giấy.
- Plan cho monorepo 500 file: 1 plan tổng quá to → chia `/batch` nhiều worktree, mỗi đứa 1 plan con.

---

## Ví dụ thực tế

### Kịch bản 1: Multi-provider payments (task kiến trúc điển hình)

Bạn có Stripe chạy ổn, sếp bảo thêm MoMo + VNPay. Code bừa là cháy tiền thật.

```bash
# Bước 1: vào plan, ép đọc trước
/plan Thêm MoMo và VNPay vào module payments hiện chỉ có Stripe.
Yêu cầu: interface chung, idempotency, webhook verify, không phá API cũ.
Chỉ lập plan, chưa code.
```

> Model đọc `src/payments/*`, trả plan 8 bước: (1) tách interface, (2) adapter MoMo, (3) adapter VNPay, (4) idempotency key, (5) webhook verify, (6) migration, (7) test, (8) rollout từng phần.

```bash
# Bước 2: duyệt từng phần, không duyệt cả cục
Ok bước 1-2. Thực hiện bước 1 (tách interface) thôi, xong dừng cho tôi review.
```

```bash
# Bước 3: review diff rồi mới cho tiếp
/diff
# → thấy ổn →
Làm tiếp bước 2.
```

### Kịch bản 2: Zero-downtime DB migration (task không được sai)

```bash
/plan Migrate bảng users (1M rows) thêm cột phone_verified.
Yêu cầu: zero-downtime, mỗi step có rollback, có cách verify bằng query thật.
Postgres 15, đang chạy production.
```

> Plan trả về: expand (thêm cột nullable) → backfill batch 10K → validate → contract (set NOT NULL) + rollback từng step.

```bash
# Duyệt nhưng ép verify từng step
Ok. Thực hiện step 1 trên staging trước, chạy query verify cho tôi xem output thật.
```

### Kịch bản 3: Người mới vào codebase lạ — plan như bản đồ

```bash
# Vừa onboard, chưa hiểu monorepo 200 file
/plan Tôi là người mới. Hãy đọc cấu trúc repo này và lập plan "thêm tính năng dark-mode"
giả định: cần chạm những file nào, rủi ro gì, test ở đâu. Chưa code.
```

> Kết quả: bản đồ chạm 6 file + 3 rủi ro + chỗ test. Bạn hiểu codebase trong 10 phút thay vì 2 ngày mò.

### Kịch bản 4: Từ chối plan ẩu (dùng plan như bộ lọc)

```bash
/plan Refactor auth/ sang microservice.
/*
→ Model trả plan "viết lại toàn bộ, downtime 2 giờ".
→ Bạn thấy quá rủi ro → từ chối:
*/
Không ổn, downtime không chấp nhận được. Lập lại theo hướng strangler-fig:
tách dần từng endpoint, giữ monolith chạy song song, có feature-flag.
```

> Giá trị: tốn 0 dòng code để phát hiện hướng sai. Rẻ hơn refactor sai 2 tuần.

---

## Rủi ro & lưu ý

### Tốn token?

- Plan đọc nhiều file → tốn input tokens 1 lần (VD 20–50K). Nhưng rẻ hơn làm sai rồi sửa 10 lần.
- Số học: plan 30K tokens (~$0.10 sonnet) cứu được 1 lần refactor sai (~$2 + 2 ngày công). ROI rõ ràng.
- Mẹo: plan bằng `sonnet + medium` cho task vừa; chỉ `opus + high` cho kiến trúc/tiền thật.

### Destructive?

- Bản thân plan mode = an toàn nhất (chặn ghi cứng).
- Nguy hiểm nằm ở BƯỚC DUYỆT: duyệt ẩu "ok làm hết đi" + đang `bypass` = model xóa/sửa hàng loạt không hỏi.
- Quy tắc duyệt an toàn:
  1. Không duyệt cả plan 10 bước 1 lúc — duyệt 1–2 bước.
  2. Sau mỗi bước: `/diff` + `/verify` rồi mới cho tiếp.
  3. Không bao giờ duyệt ở `bypassPermissions` trên máy thật.

### Version floor & provider thiếu gì?

- `/plan` + plan mode: mọi bản v2.1.x (CLI/IDE/Web/Desktop).
- Plan lưu file `~/.claude/plans/`: bản mới; bản cũ plan chỉ nằm trong chat (copy tay ra file).
- Bedrock/Vertex khóa `Bash` đọc: plan có thể thiếu thông tin git/log — bảo model "chỉ dùng Read/Grep" để plan vẫn chạy.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/plan` → duyệt 1 bước → `/diff` | Task lớn, đi từng bước chắc | `/plan ...` → làm bước 1 → `/diff` |
| `/plan` + `/goal` | Plan + tiêu chí xong rõ ràng | `/plan ...` + `/goal "tests pass + no lint"` |
| `/plan` + `/model opus` | Plan kiến trúc cần não to | `/model opus` → `/plan ...` |
| `/plan` + `/verify` | Plan tiền thật/migration | Thực thi → `/verify` chạy thật |
| `/plan` + `/batch` | Plan tổng → chia worktree song song | Plan tổng → `/batch` mỗi đứa 1 phần |
| `/plan` + Shift+Tab | Vào/thoát plan nhanh | Shift+Tab tới `plan` |

Workflow chuẩn "task lớn an toàn":

```bash
# 1. Plan
/model opus
/plan Thêm MoMo vào payments, yêu cầu idempotency. Chỉ plan.

# 2. Đặt tiêu chí xong
/goal "pytest payments/ pass + webhook verify có test + không đổi API cũ"

# 3. Duyệt từng bước
# → "Làm bước 1 thôi"

# 4. Review + verify từng bước
/diff
/verify

# 5. Mới cho bước tiếp
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/plan` xong model vẫn sửa file | Chưa thật sự ở plan mode (mới gõ text, chưa Enter lệnh) | Kiểm tra status bar hiện `plan`; gõ lại `/plan` |
| Ở plan nhưng cần ghi 1 file plan ra đĩa | Plan chặn ghi là đúng | Bảo "hiển thị plan dạng markdown để tôi copy", hoặc tạm Shift+Tab về `acceptEdits` ghi 1 file rồi quay lại plan |
| Duyệt plan rồi model làm ẩu 10 bước | Duyệt cả cục + effort thấp | Duyệt 1–2 bước; `/effort high` cho bước khó |
| Plan quá chung chung ("bước 1: refactor code") | Prompt plan mơ hồ, effort thấp | Viết rõ ràng buộc + `/effort high` + bảo "plan tới mức file:dòng" |
| Plan mode chặn cả `git log` cần thiết | Admin khóa Bash đọc (Bedrock/managed) | Bảo model chỉ dùng Read/Grep/Glob; lấy git info tay paste vào |
| Muốn thoát plan mà không làm gì | Đổi ý | Shift+Tab về `acceptEdits`/`default`, hoặc gõ "thôi không làm nữa" |
| Plan dài 200 dòng, đọc nản | Task quá to | Bảo "tóm tắt 8 bullet + chi tiết từng bước khi tôi hỏi", hoặc chia `/batch` |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../goal/README.md](../goal/README.md) — đặt tiêu chí xong cho plan
  - [../verify/README.md](../verify/README.md) — kiểm chứng sau khi thực thi plan
  - [../permissions/README.md](../permissions/README.md) — hiểu 5 modes xoay bằng Shift+Tab
  - [../diff/README.md](../diff/README.md) — review từng bước plan
  - [../batch/README.md](../batch/README.md) — chia plan tổng thành worktree song song
  - [../model/README.md](../model/README.md) — opus plan khôn hơn
  - [../effort/README.md](../effort/README.md) — high cho plan khó
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ slash commands
  - `../06-subagents-agent-teams-parallel.md` — giao plan con cho subagent
  - `../10-permissions-modes-availability.md` — 5 modes chi tiết
  - `../11-git-worktrees-checkpoints.md` — checkpoint trước khi chạy plan
  - `../12-agent-sdk-ci-cd-automation.md` — plan trong CI

> Mẹo 1 dòng: _chưa biết làm thế nào thì `/plan` trước — 10 phút plan cứu 2 tuần refactor sai._
