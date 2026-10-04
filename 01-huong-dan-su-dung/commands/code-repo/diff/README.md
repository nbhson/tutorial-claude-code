# /diff — Xem diff tương tác: model sửa gì, từng dòng, duyệt trước khi nhận

> Loại Built-in · Nhóm Code & Repo · Nguy hiểm Không (chỉ xem, không sửa thêm; là kính lúp bắt buộc sau mỗi bước thực thi)

`/diff` mở interactive diff viewer: liệt kê mọi file model vừa sửa, từng hunk thêm/xóa, cho bạn duyệt/chỉnh/revert trước khi nhận. Không có `/diff` sau bước code = nhận hàng mù.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/diff` | _(không có)_ | Mở viewer cho mọi thay đổi chưa review |
| `/diff <file>` | đường dẫn | Chỉ xem diff 1 file |
| `/diff --staged` | (quy ước git) | Xem phần đã stage (tùy bản hỗ trợ git passthrough) |

Ví dụ:

```bash
# Dạng 1: sau mỗi bước code — thói quen bắt buộc
/diff
```

```bash
# Dạng 2: chỉ xem 1 file quan trọng
/diff src/payments/stripe.ts
```

```bash
# Dạng 3: workflow plan từng bước
# Làm bước 1 → /diff → ok → mới làm bước 2
Thực hiện bước 1 của plan.
/diff
# → ok → Làm tiếp bước 2.
```

```bash
# Dạng 4: trước khi commit — quét lần cuối
/diff
# git add -p + git commit (làm tay ngoài, sau khi duyệt)
```

---

## Cách nó hoạt động

### Cơ chế sâu

1. **Nguồn diff 2 tầng:**
   - Tầng Claude: thay đổi trong session (Edit/Write calls) — hiện ngay cả khi bạn chưa `git add`.
   - Tầng git: `git diff` + `git status` (unstaged/staged/untracked) — để thấy toàn cảnh.
2. **Interactive viewer:**
   - Duyệt từng hunk: `giữ / bỏ / sửa tay`. Bỏ 1 hunk không ảnh hưởng hunk khác.
   - Gộp với checkpoint (`/rewind`): thấy sai cả bước → rewind thay vì bỏ từng hunk.
3. **Không pollute history:**
   - `/diff` chỉ đọc, không thêm turn/tools vào history thực thi. Xem bao nhiêu lần cũng không tốn context suy luận.
4. **Khác `/review`/`/code-review`:** `/diff` là xem thô để bạn tự quyết; `/review` là xin ý kiến model; `/code-review` là skill gọi subagent mới soi.

### Khác gì lệnh dễ nhầm?

| Lệnh | Ai xem? | Ai cho ý kiến? | Dùng khi nào? |
|---|---|---|---|
| `/diff` | Bạn tự xem thô | Không ai | Sau mọi bước code |
| `/review` | Bạn + model hiện tại | Model hiện tại | Xin nhận xét nhanh |
| `/code-review` | Subagent mới (fresh eyes) | Subagent | Trước merge PR |

---

## Ví dụ thực tế

### Kịch bản 1: Bắt quả tang model sửa lan

Model bảo "chỉ rename 1 biến", bạn `/diff` thấy nó sửa 5 file trong đó 1 file logic đổi.

```bash
/diff
# → hunk 1-3: rename đúng. hunk 4: đổi if (x > 0) thành if (x >= 0) — KHÔNG yêu cầu.
# → bỏ hunk 4, giữ 1-3.
```

### Kịch bản 2: Review trước commit (team không có CI kỹ)

```bash
/diff
# → quét 12 file, phát hiện 1 file test bị skip (it.skip) do model lười.
# → bảo: Bỏ .skip, chạy lại test đó cho xanh rồi mới commit.
```

---

## Rủi ro & lưu ý

- **Không `/diff` = nhận hàng mù.** Đặc biệt sau `auto`/`bypass` (model tự ghi không hỏi).
- Tốn 0 token đáng kể (chỉ render). Không có lý do bỏ qua.
- Provider thiếu gì: IDE hiện inline đẹp nhất; CLI bản cũ render text thô nhưng vẫn đủ.

---

## Kết hợp trong workflow

| Combo | Khi nào | Mẫu |
|---|---|---|
| Code → `/diff` → `/verify` | Mọi task | Sửa → `/diff` duyệt → `/verify` chạy thật |
| `/plan` từng bước + `/diff` | Task lớn | Bước 1 → `/diff` → bước 2 |
| `/diff` → `/review` | Tự xem rồi xin ý kiến | `/diff` ok → `/review` soi thêm |

```bash
# Workflow chuẩn sau mỗi bước:
# 1. Model sửa xong → /diff
# 2. Ổn → /verify (chạy test thật)
# 3. Xanh → mới cho bước tiếp
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/diff` trống dù model bảo đã sửa | Sửa ở worktree khác (`/batch`) hoặc file chưa flush | Kiểm tra worktree path; bảo model paste đường dẫn tuyệt đối |
| Diff quá lớn (50 file) đọc nản | Task quá to, model sửa lan | Bảo "tóm tắt 10 bullet + chỉ hiện file quan trọng"; chia task nhỏ |
| `/diff` hiện cả file bạn sửa tay | Gộp chung thay đổi người + model | Dùng `git diff` tay để phân biệt, hoặc commit phần bạn trước |
| Muốn revert 1 hunk mà không được | Viewer bản cũ chỉ xem | Revert tay bằng `git checkout -p`, hoặc bảo model revert hunk đó |

---

## Tham khảo

- Lệnh liên quan:
  - [../review/README.md](../../code-repo/review/README.md) — xin nhận xét sau khi tự xem diff
  - [../code-review/README.md](../../code-repo/code-review/README.md) — review sâu bằng subagent mới
  - [../verify/README.md](../../code-repo/verify/README.md) — chạy thật sau khi duyệt diff
  - [../plan/README.md](../../model-mode/plan/README.md) — diff từng bước plan
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _code xong mà chưa `/diff` thì như ký hợp đồng không đọc._
