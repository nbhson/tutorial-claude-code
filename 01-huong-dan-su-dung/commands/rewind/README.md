# /rewind — Quay ngược conversation + code về checkpoint an toàn (nút undo của cả não lẫn tay)

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Có — có thể xóa đoạn hội thoại sau checkpoint và revert file code về trạng thái checkpoint (mất việc sau checkpoint nếu không sao lưu; checkpoint sau bị bỏ)

`/rewind` (kết hợp phím **Esc × 2 / double-Esc** mở checkpoint picker) là "cỗ máy thời gian toàn diện": quay cả **trí nhớ hội thoại** lẫn **file code** về 1 điểm checkpoint trước đó, khi bạn nhận ra 30 phút vừa rồi đi sai hướng.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/rewind` | _(không có)_ | Mở picker checkpoints để chọn điểm quay về |
| `Esc Esc` (nhấn Esc 2 lần) | _(phím tắt)_ | Cách nhanh nhất mở cùng picker (khi đang ở prompt) |
| `/rewind` + chọn checkpoint | 1 checkpoint trong list | Quay về đúng điểm đó (xác nhận trước khi revert) |

Không có `/rewind <id> --force` chính thức trên v2.1.x — mọi ca đều qua picker + xác nhận.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở picker bằng lệnh
/rewind
# → list: "10:20 trước khi refactor auth" / "10:45 sau khi thêm test" / ...
```

```bash
# Dạng 2: phím tắt (khuyên dùng khi đang gõ dở, muốn quay gấp)
# Nhấn Esc Esc → picker hiện → chọn checkpoint → xác nhận
```

```bash
# Dạng 3: xem checkpoints đi kèm git trước khi rewind
# (mở terminal cạnh bên để đối chiếu)
git log --oneline -10
# rồi mới /rewind để biết checkpoint ứng với commit nào
```

```bash
# Dạng 4: sao lưu trước khi rewind risky (quy trình an toàn)
/export
/rewind
```

---

## Cách nó hoạt động

### Under-the-hood: checkpoint là gì?

1. **Checkpoint tự tạo khi nào?**
   - Trước mỗi batch edit file rủi ro (refactor nhiều file, chạy migration, `apply patch` lớn), Claude Code chụp snapshot: (a) transcript tới thời điểm đó, (b) diff files (hoặc git stash-style backup), (c) todos.
   - List checkpoints lưu trong session metadata + một phần trong `.git` (nếu project là git repo) hoặc thư mục backup local.
2. **Picker hiện gì?**
   - Mỗi checkpoint: thời gian, mô tả tự động ("trước khi sửa 8 files ở src/auth/"), số turns, preview diff. Mới nhất lên đầu.
3. **Khi bạn xác nhận rewind:**
   - **Conversation:** mọi turns sau checkpoint bị cắt khỏi context (và đánh dấu truncated trong transcript — tùy bản có giữ để audit hay xóa hẳn).
   - **Files:** các file đã đổi sau checkpoint được revert về nội dung lúc checkpoint (qua git checkout-style hoặc backup restore).
   - **Todos:** quay về trạng thái todos lúc checkpoint.
   - **Checkpoints sau:** các checkpoint mới hơn điểm bạn chọn thường bị vô hiệu/bỏ (timeline rẽ nhánh, không còn tuyến tính).
4. **Không phải git reset:**
   - Git reset chỉ quay code. Rewind quay cả code + memory hội thoại + todos trong 1 thao tác. Nhưng git commits đã push lên remote thì rewind local không thu hồi được — phải xử lý git riêng.

```text
Timeline:
  CP1 (10:20, trước refactor) ── CP2 (10:45, sau test) ── NOW (11:10, hỏng bét)
        ▲                                                       |
        └──────────── /rewind về CP1 ───────────────────────────┘
        → conversation 10:45-11:10 bị cắt, files về như 10:20, CP2 bị bỏ
```

### Khác gì với lệnh dễ nhầm? (bảng sinh tử)

| Lệnh | Quay memory? | Revert files? | Bản gốc sau thao tác? |
|---|---|---|---|
| `/rewind` | Có (cắt đoạn sau checkpoint) | Có (revert về checkpoint) | 1 timeline (đoạn sau mất) |
| `/clear` | Xóa trắng toàn bộ | Không (files giữ nguyên) | Trắng, không quay về điểm nào |
| `/compact` | Nén thành summary (không cắt hẳn) | Không | Cùng timeline, gọn hơn |
| `/fork` | Copy sang timeline mới | Không tự revert (chung đĩa) | 2 timelines (gốc còn nguyên) |
| `/branch` | Copy what-if sang mới | Không | 2 timelines |
| `git checkout .` / `git reset` | Không (model vẫn nhớ) | Có | Code quay, não model không quay |
| `Esc Esc` | Chính là rewind picker (phím tắt) | Như rewind | Như rewind |

> Quy tắc ngón tay cái:
>
> - **Code hỏng + memory sai → `/rewind`.**
> - **Code ổn, chỉ memory bẩn/đổi task → `/clear`.**
> - **Code ổn, memory dài nhưng đúng hướng → `/compact`.**
> - **Muốn giữ bản sai để so sánh → `/fork`, đừng rewind.**

---

## Ví dụ thực tế

### Kịch bản 1: Refactor auth 30 phút càng sửa càng đỏ — quay về điểm còn xanh

```bash
# 10:20 checkpoint tự tạo "trước khi refactor src/auth/ (8 files)"
# 10:20-11:10: sửa 8 files, test từ 2 fail lên 14 fail, càng fix càng rối

/rewind
# → picker: chọn "10:20 trước khi refactor src/auth/"
# → xác nhận "Revert 8 files + cắt 25 turns sau checkpoint? [Yes]"
# → về 10:20: test lại xanh như cũ, đầu óc nhẹ

# Làm lại khôn hơn, chia nhỏ:
Hãy refactor từng file một trong src/auth/, mỗi file xong chạy test file đó rồi mới sang file tiếp theo.
```

### Kịch bản 2: Double-Esc giữa lúc model đang "phá" — chặn + quay gấp

```bash
# Model đang xóa/sửa hàng loạt sai ý (ví dụ đổi hết import paths)
# Tay: nhấn Esc Esc ngay → picker checkpoints hiện → chọn checkpoint 5 phút trước
# → edits dở bị revert, conversation cắt đúng lúc trước khi nó phá
```

> Phản xạ nên luyện: _thấy model sửa bừa >3 files sai → Esc Esc, đừng ngồi xem nó phá tiếp._

### Kịch bản 3: Rewind an toàn khi chưa chắc (export + git song song)

```bash
# Sắp rewind 1 tiếng làm việc, sợ mất ý hay trong đoạn sai
/export
# → lưu đoạn sai vào docs/spike-that-bai.md (biết đâu có 1 ý dùng được)

git status
git stash push -m "truoc-rewind-11h10" --include-untracked
# → dù rewind có gì lạ, git stash vẫn cứu được

/rewind
# → chọn checkpoint, xác nhận
```

### Kịch bản 4: Rewind xong đi hướng mới (kết hợp fork để giữ bằng chứng thất bại)

```bash
# Muốn giữ đoạn sai để so sánh mà vẫn quay về làm lại:
# Cách A (giữ bằng chứng): fork trước, rewind sau
/fork Lưu nhánh thất bại để đối chiếu.
/rename that-bai-huong-A
# → quay về bản gốc
/resume <ban-goc>
/rewind
# → bản gốc quay về CP1 sạch, nhánh thất bại vẫn còn để so
```

---

## Rủi ro & lưu ý

### Mất gì? Có cứu được không?

| Mất gì | Cứu được không? | Cách cứu |
|---|---|---|
| Turns hội thoại sau checkpoint | Thường không (bị cắt) | Chỉ còn nếu đã `/export` trước, hoặc transcript giữ đoạn truncated (tùy bản) |
| Code edits sau checkpoint | Không (bị revert) | `git stash` / `git branch` / `/export` trước khi rewind |
| Checkpoints mới hơn | Thường bị bỏ | Không cứu — chọn kỹ trước khi xác nhận |
| File chưa từng track (untracked, chưa commit, không trong backup) | Có thể mất hẳn | `git add -N` / stash include-untracked trước |
| Commits đã push remote | Rewind local không thu hồi remote | Xử lý git riêng (`git revert`), rewind không thay remote |

> **Luật sắt:** _rewind là destructive._ Chưa `export` + chưa `git stash/branch` thì chưa rewind đoạn >15 phút.

### Tốn token? Version? Plan?

- **Tốn token:** tự thân rewind ~0. Nhưng sau rewind context nhẹ hẳn (ví dụ 70%→15%) nên các prompt sau rẻ hơn. Ngược lại, nếu rewind rồi làm lại y hệt sai lầm cũ thì tốn gấp đôi — nên đổi chiến thuật sau rewind.
- **Version tối thiểu:** checkpoint picker + double-Esc hoàn thiện trên v2.0+, mượt nhất v2.1.x. Bản CLI rất cũ có thể ít checkpoints hơn IDE.
- **Plan/provider:** mọi plan. Không cần plugin/MCP. Nhưng độ chi tiết backup files phụ thuộc project có phải git repo không (có git thì revert tin cậy hơn).

### Cloud vs Local

| Môi trường | Khác biệt |
|---|---|
| CLI + git repo | Revert tin cậy nhất (dựa git diff/stash) |
| CLI không git | Dựa backup local, vẫn được nhưng kém tin cậy với file mới/rename |
| IDE | Picker trực quan nhất: preview diff từng checkpoint, tick chọn files muốn revert |
| Web/Desktop | Tương tự IDE; revert files chỉ áp dụng nếu workspace sync về local |

> Dự án chưa `git init` mà muốn rewind an toàn → `git init + commit` ngay hôm nay. Rewind trên nền git tin cậy hơn hẳn.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `Esc Esc` | Phím tắt mở rewind khi thấy sai |
| `/export` → `/rewind` | Lưu bằng chứng thất bại rồi mới quay |
| git stash/branch → `/rewind` | Cứu code trước khi quay memory |
| `/rewind` → `/compact` | Quay về rồi nén nhẹ để làm lại gọn |
| `/rewind` → đổi chiến thuật | Sau rewind phải prompt khác đi (chia nhỏ, khóa phạm vi), không lặp sai cũ |
| `/fork` → `/rewind` | Fork giữ nhánh sai, rewind bản chính |

Prompt mẫu sau rewind (tránh lặp sai lầm):

```bash
# Sau khi về CP1, đừng bảo "làm lại đi" chung chung. Hãy:
Hãy refactor src/auth/ từng file một.
Mỗi file: sửa → chạy `npm test <file>` → báo OK/FAIL rồi mới sang file tiếp.
Không sửa quá 2 files cùng lúc. Dừng ngay khi test đỏ quá 2.
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Picker checkpoints trống / ít | Session mới, chưa có edit rủi ro nào; hoặc project không git nên ít snapshot | Làm tiếp để có checkpoints; `git init + commit` để snapshot tin cậy hơn |
| Rewind xong file không về như cũ | File untracked/rename ngoài tầm backup; hoặc edits sau checkpoint có bước manual ngoài Claude | Kiểm tra `git status`/`git stash list`, phục hồi tay; lần sau stash trước |
| Rewind nhầm checkpoint quá cũ (mất 1 tiếng) | Chọn vội, không đọc mô tả/preview | Đọc preview diff + thời gian kỹ; export trước luôn để có đường lui |
| Muốn undo rewind (quay lại tương lai) | Timeline đã rẽ, checkpoints sau bị bỏ | Không có forward; cứu bằng `git stash`/export trước đó. Phòng bệnh hơn chữa |
| `Esc Esc` không mở gì | Focus không ở prompt input (đang ở terminal output/pager) hoặc bản cũ | Click vào ô prompt rồi Esc Esc; hoặc gõ `/rewind` |
| Rewind xong model vẫn "nhớ" đoạn sai | Model dựa vào summary/COMPACT cũ hoặc file docs ghi sai | `/compact` lại với focus đúng + sửa docs nhiễm sai; bảo model `read` lại file thực tế |
| Rewind trên Web không revert file local | Workspace chưa sync | Sync workspace rồi rewind; hoặc revert tay bằng git local |
| Rewind xong `/todos` quay về cũ | Đúng thiết kế (todos theo checkpoint) | Kiểm tra `/todos` sau rewind, tạo lại việc mới phát sinh sau checkpoint nếu vẫn cần |
| Không chắc checkpoint nào đúng | Mô tả checkpoint chung chung | Soi `git log --oneline -10` + preview diff trước khi chọn; khi nghi ngờ thì `/export` trước |

### Checklist 15 giây trước khi nhấn Yes

```bash
# 1. Đã /export chưa? (giữ bằng chứng + ý hay trong đoạn sai)
# 2. Đã git stash/branch chưa? (giữ code sau checkpoint)
# 3. Đã đọc preview diff + thời gian checkpoint chưa?
# 4. Sau rewind sẽ prompt khác đi thế nào? (viết sẵn câu prompt mới, chia nhỏ hơn)
# Nếu 4 câu đều OK → Yes. Thiếu 1 câu → làm câu đó trước.
```

> Ghi nhớ: _checkpoint tốt + git sạch = rewind không sợ; thiếu 1 trong 2 là rewind hồi hộp._
>
> Đọc thêm về worktree cách ly trong `../11-git-worktrees-checkpoints.md` trước ca refactor lớn.

---

## Tham khảo

- Lệnh liên quan:
  - [../clear/README.md](../clear/README.md) — xóa trắng khi đổi task (không revert files)
  - [../compact/README.md](../compact/README.md) — nén khi đúng hướng (không cắt)
  - [../fork/README.md](../fork/README.md) — giữ nhánh sai để so sánh
  - [../branch/README.md](../branch/README.md) — what-if thay vì quay đầu
  - [../resume/README.md](../resume/README.md) — mở lại sau khi quay
  - [../export/README.md](../export/README.md) — lưu trước khi quay
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — checkpoints + worktrees + git stash/branch (đọc kỹ trước khi rewind risky)
  - `../10-permissions-modes-availability.md` — hạn chế quyền ghi để khỏi phải rewind
  - `../03-claude-md-memory-rules.md` — luật trong CLAUDE.md không bị rewind (vẫn còn)

> Mẹo 1 dòng: _thấy test đỏ tăng dần sau 3 lần fix → dừng gõ, `Esc Esc`, về checkpoint còn xanh rồi đi bước nhỏ hơn._
