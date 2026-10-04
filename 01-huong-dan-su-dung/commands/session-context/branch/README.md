# /branch — Tạo nhánh thử nghiệm what-if từ conversation hiện tại

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file; chỉ copy context sang nhánh thử nghiệm — an toàn nếu kết hợp git riêng)

`/branch` giống `/fork` nhưng mang ngữ nghĩa "thử giả thuyết": tách 1 nhánh what-if để trả lời "nếu làm theo cách B thì sao?", trong khi nhánh chính vẫn đi cách A.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/branch` | _(không có)_ | Tạo nhánh what-if từ điểm hiện tại |
| `/branch <giả-thuyết>` | text mô tả điều muốn thử | Tạo nhánh + nêu giả thuyết cần kiểm chứng |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: tạo nhánh trống
/branch
```

```bash
# Dạng 2: nêu giả thuyết (khuyên dùng)
/branch Nếu dùng Zod strict mode thì còn bao nhiêu lỗi type ở billing/?
```

```bash
# Dạng 3: so sánh hiệu năng
/branch Thử cache Redis cho GET /api/products và đo số query giảm được.
```

```bash
# Dạng 4: nhánh + rename ngay
/branch Thử Drizzle thay vì Prisma.
/rename thu-nghiem-drizzle
```

---

## Cách nó hoạt động

1. **Copy context như fork:** snapshot history/todos sang session ID mới.
2. **Gắn nhãn thử nghiệm:** nhánh mới được hiểu là disposable (dùng 1 lần, bỏ cũng không tiếc). Picker/resume hiện nó như session riêng.
3. **Không cách ly files:** chung filesystem/git như fork. Muốn thử đập phá file thật → tạo `git branch` / `git worktree` riêng (xem bài 11).
4. **Kết luận rồi bỏ hoặc giữ:** nhánh what-if trả lời xong thì ghi kết luận vào docs, bỏ nhánh. Không có merge tự động.

| Lệnh | Ngữ nghĩa | Khi nào dùng |
|---|---|---|
| `/branch` | "Thử xem sao, bỏ cũng được" | Câu hỏi what-if, spike 15-30 phút |
| `/fork` | "Rẽ hướng nghiêm túc, có thể thành chính" | 2 hướng đều khả thi dài hạn |
| `/rewind` | "Quay lại trên cùng đường" | Đi sai muốn quay đầu |

---

## Ví dụ thực tế

### Kịch bản 1: Spike 20 phút — Zod strict có đáng không?

```bash
# Nhánh chính đang dùng Zod lỏng, muốn biết strict thì vỡ bao nhiêu chỗ
/branch Nếu bật Zod strict cho packages/billing/, liệt kê số lỗi type và ước lượng giờ fix. Không sửa file, chỉ báo cáo.
# → 20 phút sau có con số để quyết định, nhánh chính không nhiễm
```

### Kịch bản 2: So sánh 2 thư viện trước khi chốt

```bash
# Đang phân vân Drizzle vs Prisma
/branch Thử migrate 1 bảng users sang Drizzle trong thư mục tạm, báo cáo số dòng code + DX cảm nhận.
# → có dữ liệu thật để chốt, thay vì tranh luận suông
```

---

## Rủi ro & lưu ý

- **Mất gì:** không mất nhánh gốc. Nhưng file đĩa chung — nhánh thử mà `rm -rf` hay sửa bừa là nhánh chính cũng dính. Luôn `git status` / worktree riêng khi thử phá.
- **Tốn token:** 1 lượt copy context. Nhánh what-if nên ngắn (15-30 phút), hỏi hẹp để rẻ.
- **Version:** v2.1.x, mọi plan, CLI/IDE/Web/Desktop.
- **Quên dọn nhánh:** để 10 nhánh what-if trong picker gây rối. Đặt tên rõ + bỏ nhánh thua (không resume nữa).

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/branch` → `/rename` | Đặt tên giả thuyết ngay |
| `/branch` + git worktree | Cách ly cả files (chuẩn lab) |
| `/branch` → `/export` | Giữ báo cáo nhánh thắng |
| `/resume` (chính) + `/branch` (thử) | Chính đi A, nhánh thử B |

```bash
# Lab chuẩn cho thử nghiệm risky:
git worktree add ../repo-thu-b -b thu-b
# + /branch trong phiên chính để tách memory
/branch Thử hướng B, chỉ sửa trong worktree ../repo-thu-b/.
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Nhánh thử sửa hỏng code nhánh chính | Chung filesystem | Dùng `git worktree` riêng; hoặc chỉ cho nhánh thử quyền đọc (`--permission-mode plan`) |
| Không phân biệt branch/fork | Ngữ nghĩa gần nhau | What-if ngắn → branch; rẽ hướng dài → fork. Về kỹ thuật gần như nhau |
| Picker đầy nhánh thử cũ | Không dọn | Đặt tên ngày + bỏ resume nhánh thua; xóa `.jsonl` nếu nhạy cảm |
| Gõ `/branch` báo unknown | CLI cũ | Update CLI |

---

## Tham khảo

- Lệnh liên quan:
  - [../fork/README.md](../../session-context/fork/README.md) — rẽ hướng nghiêm túc
  - [../rewind/README.md](../../session-context/rewind/README.md) — quay đầu thay vì tách
  - [../resume/README.md](../../session-context/resume/README.md) — quay về nhánh chính
  - [../rename/README.md](../../session-context/rename/README.md) — đặt tên nhánh thử
  - [../export/README.md](../../session-context/export/README.md) — lưu kết luận nhánh thắng
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — worktree + branch git cho lab thật
  - `../10-permissions-modes-availability.md` — khóa quyền ghi khi chỉ muốn thử đọc

> Mẹo 1 dòng: _câu hỏi bắt đầu bằng "nếu…" thì `/branch` — trả lời bằng dữ liệu 20 phút thay vì tranh luận 2 tiếng._
