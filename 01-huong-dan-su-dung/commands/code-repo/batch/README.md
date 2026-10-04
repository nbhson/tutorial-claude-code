# /batch — Chia task lớn thành 5–30 worktree-subagents song song, mỗi đứa 1 PR

> Loại Skill/Workflow · Nhóm Code & Repo · Nguy hiểm Có nếu ẩu (30 đứa cùng sửa + cùng push = conflict/loạn branch; tốn quota mạnh — luôn giới hạn scope + số lượng + verify từng đứa)

`/batch` là "chia để trị" ở quy mô lớn: tách 1 epic thành N task độc lập, mỗi task chạy trong 1 git worktree riêng + 1 subagent riêng, cuối cùng mỗi đứa mở 1 PR. Thay vì 1 agent làm 3 ngày, 10 agents làm 1 buổi — với giá là công sức điều phối + quota.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/batch <mô tả epic>` | text | Chia epic + spawn worktree-subagents |
| `/batch <epic> --n <số>` | `5`–`30` | Giới hạn số subagents song song |
| `/batch <epic> --scope <path>` | đường dẫn | Giới hạn mỗi đứa 1 thư mục |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: cơ bản — giao epic, để skill tự chia
/batch Thêm JSDoc + unit test cho toàn bộ src/utils/ (20 file).
Mỗi subagent 2 file, mỗi đứa 1 PR nhỏ.
```

```bash
# Dạng 2: giới hạn số lượng (khuyên dùng — đừng thả 30 ngay)
/batch Migrate 30 API routes sang App Router. Tối đa 5 subagents song song,
mỗi đứa 6 routes, mỗi đứa 1 branch + 1 PR.
```

```bash
# Dạng 3: giới hạn scope chống dẫm chân
/batch Viết test cho services/. Mỗi subagent chỉ được chạm 1 service con
(api/ worker/ notifications/), cấm chạm service của đứa khác.
```

```bash
# Dạng 4: batch có goal + verify từng đứa (chuẩn)
/batch Thêm rate-limit cho 10 endpoints trong src/api/.
Mỗi subagent: goal là "vitest endpoint đó pass + k6 smoke < 500ms",
xong thì /verify module mình rồi mới mở PR.
```

```bash
# Dạng 5: batch + review sau (điều phối tay)
/batch Refactor 12 components sang TypeScript strict.
# ... đợi các PR mở ...
/code-review 131
/code-review 132
```

```bash
# Dạng 6: dọn dẹp worktrees sau batch
git worktree list
git worktree remove --force .worktrees/batch-01
# (làm tay — skill không tự xóa để bạn còn review)
```

---

## Cách nó hoạt động

### Cơ chế sâu: batch chia worktrees thế nào?

1. **Planner chia task:**
   - Skill đọc epic → tách thành N task ĐỘC LẬP (không phụ thuộc thứ tự). Task phụ thuộc nhau (A xong B mới làm được) KHÔNG cho batch — làm tuần tự.
   - Mỗi task có: scope files, goal riêng, branch riêng (`batch/<task>-<id>`), tiêu chí verify riêng.
2. **Git worktree — mỗi đứa 1 sân riêng:**
   - `git worktree add .worktrees/batch-01 -b batch/task-01` → mỗi subagent có checkout vật lý riêng, cùng commit gốc nhưng file cách ly.
   - Không dẫm chân: đứa A sửa `services/api/` không thấy file đứa B đang sửa ở worktree khác.
   - Cuối: mỗi đứa `git push -u origin batch/task-01` + `gh pr create` → N PR nhỏ thay vì 1 PR khổng lồ.
3. **Subagent spawn + kế thừa:**
   - Mỗi subagent nhận: prompt task + goal + scope + bảng permissions (kế thừa session chính) + model/effort (thường nhẹ hơn chính: sonnet+medium cho task nhỏ).
   - Chạy song song thật (parallel tool-calls / agent teams — xem bài 06).
4. **Điều phối + merge:**
   - Bạn (hoặc 1 coordinator agent) theo dõi N PR: `/code-review` từng cái, `/verify` từng cái, merge từng cái nhỏ.
   - Conflict khi merge vào main: vì scope đã chia không giao nhau, conflict hiếm — nếu có thì giải tay 1 chỗ.
5. **Quota & giới hạn 5–30:**
   - 5–10: vùng an toàn (máy + quota chịu được).
   - 15–30: chỉ khi task siêu độc lập (VD 30 file rename) + đã bật `/extra-usage` + máy khỏe. Vượt 30: diminishing returns (điều phối lâu hơn làm).
6. **Khi nào KHÔNG batch?**
   - Task phụ thuộc thứ tự, task cần 1 quyết định kiến trúc thống nhất, task < 30 phút (overhead chia > lợi), hoặc chạm cùng 1 file nóng (migration đơn).

### Sơ đồ worktrees

```text
main @ abc123
  |-- .worktrees/batch-01 (branch batch/api-01) [subagent 1: routes 1-6]
  |-- .worktrees/batch-02 (branch batch/api-02) [subagent 2: routes 7-12]
  |-- .worktrees/batch-03 (branch batch/api-03) [subagent 3: routes 13-18]
  |-- ... mỗi đứa 1 PR → review từng PR → merge dần vào main
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Song song? | Cách ly file? | Dùng khi nào? |
|---|---|---|---|
| `/batch` | Có (5–30) | Có (worktree) | Epic độc lập, nhiều file |
| Subagent đơn (`Task`) | 1–2 | Không (cùng thư mục) | Task con trong phiên |
| `/loop` | Không (lặp tuần tự) | Không | 1 task lặp tới đạt |
| `/plan` chia bước | Không | Không | Task phụ thuộc thứ tự |

> Quy tắc ngón tay cái:
>
> - **Độc lập + nhiều + giống nhau → `/batch`. Phụ thuộc nhau → `/plan` tuần tự.**

---

## Ví dụ thực tế

### Kịch bản 1: Thêm test cho 20 utils (task batch kinh điển)

20 file `src/utils/*.ts` chưa có test. 1 agent làm 3 giờ; 10 agents làm 25 phút.

```bash
# Bước 1: batch 10 đứa, mỗi đứa 2 file
/batch Viết unit test (vitest) cho src/utils/*.ts, mỗi subagent đúng 2 file,
goal: "vitest file đó pass, coverage lines ≥ 80%". Mỗi đứa 1 branch + 1 PR.
Tối đa 10 song song.
```

> Diễn biến: 10 worktrees spawn, mỗi đứa đọc 2 file + viết test + chạy vitest file mình + mở PR. Bạn nhận 10 PR nhỏ, mỗi PR ~50 dòng — review 5 phút/PR.

```bash
# Bước 2: review + merge dần
/code-review 140
/verify
# → merge từng PR nhỏ (không gộp 1 PR to)
```

### Kịch bản 2: Migrate 30 routes — batch có scope chống conflict

```bash
/batch Migrate 30 API routes (pages/api/*) sang App Router (app/api/*).
Chia 5 subagents, mỗi đứa 6 routes LIỀN NHAU theo danh sách tôi paste dưới đây.
CẤM chạm routes của đứa khác. Mỗi đứa xong chạy pnpm build module mình.
/* paste danh sách chia 6-6-6-6-6 */
```

> Giá trị của "liền nhau + cấm chạm": không có 2 đứa sửa cùng file, merge 5 PR không conflict.

### Kịch bản 3: Batch sai — task phụ thuộc (bài học đừng batch)

```bash
# SAI: epic "thiết kế schema + migrate + viết API" — 3 bước phụ thuộc nhau
/batch Làm cả 3: (1) thiết kế schema, (2) migrate, (3) viết API.
# → 3 đứa làm song song, đứa API đoán schema sai vì schema chưa xong.

# ĐÚNG: plan tuần tự cho phần phụ thuộc, batch cho phần độc lập
/plan Thiết kế schema + migrate (làm trước, 1 agent).
# → xong schema →
/batch Viết 10 endpoints trên schema ĐÃ CHỐT, mỗi đứa 2 endpoints.
```

### Kịch bản 4: Batch + extra-usage (chuẩn bị quota trước)

```bash
# 20 subagents opus = đốt quota nhanh. Bật trước:
/extra-usage
/model sonnet
/effort medium
/batch Viết docs cho 20 services, mỗi đứa 1 service. Dùng sonnet+medium cho rẻ.
# ... xong ...
/extra-usage
# → off
```

---

## Rủi ro & lưu ý

### Tốn token? (rất tốn nếu không giới hạn)

| Số agents | Chi phí tương đối | Khi nào |
|---|---|---|
| 3–5 | 3–5x task đơn | Chuẩn, nên dùng |
| 10 | ~10x | Epic vừa, đã bật extra |
| 20–30 | 20–30x + overhead điều phối | Chỉ task siêu độc lập + máy khỏe |

- Mỗi subagent đọc lại context riêng (system + files) → overhead lặp. Task nhỏ mà batch 30 = overhead > lợi.
- Luôn đặt `--n` + dùng `sonnet+medium` cho task con (đừng opus+max cho 30 đứa).
- Quên tắt extra sau batch lớn = bill bất ngờ. Tắt ngay khi PR cuối mở.

### Destructive?

- CÓ THỂ: 30 đứa cùng `git push` + `gh pr` + chạy scripts. Rủi ro:
  1. Đứa chạm nhầm scope (sửa file người khác) → conflict/loạn. Chống: scope cấm rõ + branch riêng.
  2. Subagent chạy migration/seed xóa DB dùng chung → mất dữ liệu. Chống: mỗi worktree DB/port riêng (`.env.test-<id>`), deny `*prod*`.
  3. Merge ồ ạt 30 PR không review → bug lọt. Chống: review + verify từng PR, merge dần.
- Không bao giờ batch ở `bypassPermissions`.

### Version / provider

- Cần git worktrees (git ≥ 2.20, repo không bare) + `gh` CLI cho PR.
- Skill batch bản mới (v2.1.x). Bản cũ: chia tay bằng `git worktree add` + `Task` thủ công (xem bài 06).
- Bedrock/managed khóa Bash Worktree → subagent không tạo sân được → batch kẹt. Liên hệ admin hoặc batch trên máy cá nhân.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/batch` + `/extra-usage` | Batch lớn đốt quota | Bật extra trước batch |
| `/batch` + goal/PR | Mỗi đứa 1 goal + 1 PR | Prompt batch kèm goal |
| `/batch` → `/code-review` từng PR | Review sau batch | Batch xong review từng PR |
| `/batch` + `/verify` từng đứa | Mỗi worktree tự verify | "Xong thì /verify module mình" |
| `/plan` → `/batch` | Chốt kiến trúc rồi mới chia | Plan trước, batch sau |
| `/batch` + `/loop` | 1 task lặp trong 1 worktree | Hiếm — chỉ khi task con cần lặp |

Workflow chuẩn "epic lớn":

```bash
# 1. Plan kiến trúc trước (1 agent, không batch)
/plan Migrate 30 routes. Chỉ plan, chốt pattern 1 route mẫu.

# 2. Chuẩn bị quota + não rẻ cho task con
/extra-usage
/model sonnet
/effort medium

# 3. Batch phần độc lập
/batch Migrate 29 routes còn lại theo pattern đã chốt. 5 song song, mỗi đứa 1 PR.

# 4. Review + verify + merge từng PR
/code-review <từng PR>
/verify
# merge dần

# 5. Dọn + tắt
# git worktree remove ... (từng cái đã merge)
/extra-usage
# → off
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| 2 subagents sửa cùng file → conflict | Chia scope giao nhau / không cấm rõ | Chia lại không giao nhau; branch riêng; merge tay chỗ conflict |
| Worktree báo `already exists` / detached | Worktree cũ chưa xóa / branch trùng | `git worktree list` + `remove` cái cũ; đặt tên branch duy nhất |
| Subagent kẹt `permission denied` git push | Permissions thiếu `Bash(git push)` / `gh` chưa auth | Allow push trong session batch; `gh auth login` trước |
| Batch 20 đứa, máy đơ / OOM | Mỗi worktree + node_modules + build ngốn RAM | Giảm `--n` còn 5; dùng 1 `node_modules` share read-only nếu được; máy yếu batch ít |
| Bill/quota nổ sau batch | 30 × opus × max + quên extra on/off | Dùng sonnet+medium cho task con; bật extra trước, tắt sau |
| Task phụ thuộc mà batch → kết quả lệch | Batch sai loại task | Dừng; chuyển phần phụ thuộc về `/plan` tuần tự, chỉ batch phần độc lập |
| PR từ batch thiếu test / ẩu | Prompt batch không kèm goal/verify | Prompt batch luôn kèm: goal đo được + "xong thì /verify rồi mới PR" |
| Muốn hủy batch giữa chừng | Đổi ý / sai hướng | Bảo dừng; `git worktree list` + remove từng cái; xóa branch remote chưa merge (`git push origin --delete`) |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../plan/README.md](../../model-mode/plan/README.md) — chốt kiến trúc trước khi batch
  - [../goal/README.md](../../model-mode/goal/README.md) — mỗi task con 1 goal riêng
  - [../verify/README.md](../../code-repo/verify/README.md) — mỗi worktree verify riêng
  - [../code-review/README.md](../../code-repo/code-review/README.md) — review từng PR batch
  - [../extra-usage/README.md](../../model-mode/extra-usage/README.md) — bật trước batch lớn
  - [../loop/README.md](../../code-repo/loop/README.md) — lặp trong 1 task (khác batch song song)
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md` — đọc kỹ: worktrees + agent teams
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md` — đọc kỹ: worktree + checkpoint + merge
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _batch task độc lập thì thần tốc, batch task phụ thuộc thì thảm họa — chia đúng trước khi chia nhiều._
