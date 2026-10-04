# /export — Xuất toàn bộ hội thoại ra file text để lưu trữ, bàn giao, đối soát

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc + ghi 1 file export mới, không xóa/sửa code hay history)

`/export` là "nút in báo cáo": gom transcript hiện tại thành 1 file text/markdown gọn gàng để gửi đồng đội, lưu docs, hoặc đọc lại sau khi `/clear`.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/export` | _(không có)_ | Xuất transcript hiện tại ra file (đường dẫn do Claude Code gợi ý/hỏi) |

Không có flag `--format`, `--output` chính thức trên v2.1.x. Muốn tên file/định dạng cụ thể thì dặn bằng lời sau lệnh.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xuất cơ bản
/export
# → Claude hỏi/gợi ý: lưu vào ./exports/session-2026-10-04.md
```

```bash
# Dạng 2: xuất + chỉ định file (dặn bằng lời)
/export
# rồi nhắn tiếp: "Lưu vào docs/handover-payments.md, định dạng markdown, chỉ gồm quyết định + file đã đổi + bước tiếp theo."
```

```bash
# Dạng 3: xuất bản gọn sau khi compact (để người đọc đỡ ngợp)
/compact Tóm tắt để bàn giao: đã xong gì, dở gì, cần đọc file nào.
/export
```

```bash
# Dạng 4: xuất trước khi clear (quy trình an toàn)
/export
/clear
```

---

## Cách nó hoạt động

### Under-the-hood

1. **Đọc transcript `.jsonl`:**
   - Gom toàn bộ turns (prompts, answers, tool calls, diffs, test outputs) của session hiện tại.
2. **Render ra text:**
   - Chuyển thành markdown/text có tiêu đề, phân vai `User/Assistant`, kèm timestamps (tùy bản), lược bớt metadata máy.
   - Bản compacted: phần trước compact hiện dưới dạng summary, không bung full chi tiết cũ.
3. **Ghi file mới:**
   - Ghi ra 1 file mới trong workspace (ví dụ `./exports/*.md`) hoặc đường dẫn bạn chỉ định. Không sửa file code hiện có, không xóa history.
4. **Không nạp ngược:**
   - File export là bản chết (static). Muốn làm tiếp từ đó phải `read` lại hoặc `/resume` session gốc. Export ≠ resume.

### Khác gì với lệnh dễ nhầm?

| Lệnh | Kết quả | Dùng khi nào |
|---|---|---|
| `/export` | 1 file text để đọc/gửi/lưu docs | Bàn giao, lưu trữ |
| `/copy` | Copy đoạn hội thoại ra clipboard (nhanh, tạm) | Paste nhanh vào Slack/PR |
| `/resume` | Nạp session vào RAM để làm tiếp | Tiếp tục việc |
| Transcript `.jsonl` gốc | JSON máy đọc, đầy đủ nhất | Debug, audit, tooling |

---

## Ví dụ thực tế

### Kịch bản 1: Bàn giao ca trực — export gọn cho người sau

```bash
# Cuối ca, session 80 turns, người sau không thể đọc hết
/compact Tóm tắt để bàn giao: đã xong auth, đang dở payments bước webhook, file cần đọc src/payments/*.
/export
# → "Lưu vào docs/handover-2026-10-04.md"
# → gửi file cho ca sau, họ đọc 2 phút là vào việc
```

### Kịch bản 2: Lưu quyết định kiến trúc vào docs (chống quên sau clear)

```bash
# Vừa chốt: dùng Postgres + Drizzle, idempotency-key header
/export
# → mở file export, copy 10 dòng quyết định vào docs/decisions.md
# → rồi mới yên tâm /clear
/clear
```

---

## Rủi ro & lưu ý

- **Mất gì:** không mất gì. Nhưng file export có thể chứa **secrets** đã paste trong chat (API keys, tokens) → kiểm tra trước khi gửi public/commit lên git.
- **Tốn token:** ~0 (render local). File càng dài càng nặng đĩa, không tốn tiền.
- **Version:** có mặt trên v2.1.x ở CLI/IDE/Web/Desktop. Đường dẫn/định dạng mặc định khác nhau chút giữa các bề mặt.
- **Cloud vs local:** CLI ghi file local trong repo; Web/Desktop có thể cho download hoặc lưu cloud tùy bản. Đừng export chứa dữ liệu nhạy cảm lên nơi share nhầm.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/compact` → `/export` | Gọn rồi mới xuất cho dễ đọc |
| `/export` → `/clear` | Lưu rồi mới xóa (quy trình an toàn) |
| `/resume` → `/export` | Mở session cũ rồi xuất cho người mới |
| `/export` → `git commit` | Lưu handover vào repo để có lịch sử |
| `/todos` → `/export` | Chốt todos rồi export kèm trong báo cáo |

```bash
/todos
/export
# → file export kèm trạng thái todos, sếp đọc là rõ tiến độ
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Không biết file export nằm đâu | Mỗi bản gợi ý đường dẫn khác nhau, dễ bỏ qua | Đọc kỹ câu trả lời sau `/export`, hoặc dặn trước "lưu vào docs/handover.md" |
| File export quá dài (5000+ dòng) | Xuất nguyên session 100+ turns chưa compact | `/compact` trước rồi export; hoặc dặn "chỉ xuất quyết định + bước tiếp theo" |
| Export thiếu đoạn trước compact | Đúng thiết kế: đoạn cũ đã nén thành summary | Muốn full thì soi `.jsonl` gốc, hoặc export thường xuyên hơn |
| File export chứa secret | Paste key trong chat, export bưng nguyên | Tìm + xóa secret trong file, rotate key, không commit file nhiễm lên git public |
| Muốn JSON để tooling parse | `/export` ra text cho người đọc | Dùng file `.jsonl` trong `~/.claude/projects/<hash>/` cho máy đọc |

---

## Tham khảo

- Lệnh liên quan:
  - [../copy/README.md](../../session-context/copy/README.md) — copy nhanh ra clipboard thay vì file
  - [../resume/README.md](../../session-context/resume/README.md) — mở lại để làm tiếp thay vì chỉ đọc
  - [../compact/README.md](../../session-context/compact/README.md) — gọn trước khi xuất
  - [../clear/README.md](../../session-context/clear/README.md) — xuất xong rồi mới xóa
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — transcript + checkpoints
  - `../10-permissions-modes-availability.md` — ai được ghi file export

> Mẹo 1 dòng: _chưa `/export` thì chưa `/clear` — 10 giây xuất file cứu được 2 tiếng giải thích lại._
