# /fork — Tách conversation hiện tại thành nhánh mới, giữ bản gốc nguyên vẹn

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file; chỉ copy context sang session mới — bản gốc giữ nguyên)

`/fork` là "rẽ nhánh không sợ hỏng": copy toàn bộ (hoặc 1 phần) context hiện tại sang 1 conversation mới để thử hướng khác, trong khi bản gốc vẫn an toàn.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/fork` | _(không có)_ | Tách toàn bộ context hiện tại sang session mới |
| `/fork <hướng-thử>` | text mô tả hướng mới | Fork + nêu luôn muốn thử gì ở nhánh mới |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: fork trắng (tự nghĩ hướng sau)
/fork
```

```bash
# Dạng 2: fork + nêu hướng (khuyên dùng)
/fork Thử cách dùng Redis queue thay vì Postgres queue, giữ nguyên API.
```

```bash
# Dạng 3: fork để giao việc rủi ro cho nhánh mới
/fork Thử refactor mạnh tay src/auth/, nếu hỏng thì bỏ nhánh này, bản gốc không sao.
```

```bash
# Dạng 4: fork rồi đổi tên ngay để khỏi nhầm
/fork Thử hướng B cho payments.
/rename payments-huong-B
```

---

## Cách nó hoạt động

1. **Snapshot context:** copy history (hoặc summary nếu dài) + todos + file references sang session ID mới.
2. **2 timeline độc lập:** từ đây 2 sessions append riêng. Sửa file ở nhánh fork vẫn đổi file trên đĩa (chung filesystem/git), nhưng memory hội thoại thì tách.
3. **Bản gốc freeze:** bản gốc không nhận thêm turns từ nhánh mới. Muốn gộp ý hay về thì copy tay hoặc ghi ra docs.

| Lệnh | Giữ bản gốc? | Chung memory sau tách? |
|---|---|---|
| `/fork` | Có | Không — 2 memory riêng |
| `/branch` | Có (+ nhãn what-if) | Không — tương tự fork nhưng ngữ nghĩa thử nghiệm |
| `/rewind` | Không (quay ngược trên cùng timeline) | Có — 1 timeline |

---

## Ví dụ thực tế

### Kịch bản 1: Đứng giữa 2 kiến trúc — thử song song không phá bản chính

```bash
# Bản gốc đang làm Postgres queue, muốn thử Redis queue mà sợ hỏng
/fork Thử lại bằng Redis queue, so sánh latency. Giữ nguyên API ở src/queue/.
# → nhánh mới tự do đập phá, bản gốc vẫn còn nếu Redis thua
```

### Kịch bản 2: Review risky refactor trước khi merge ý tưởng

```bash
# Muốn thử refactor auth/ mạnh tay
/fork Refactor src/auth/ sang JWT rotation, cho phép đổi nhiều file. Nếu test đỏ quá 5 thì dừng.
/rename auth-rotation-thu-nghiem
# → hỏng thì bỏ nhánh, gốc không nhiễm
```

---

## Rủi ro & lưu ý

- **Mất gì:** không mất memory gốc. Nhưng **file trên đĩa là chung** — fork không tạo git branch hay worktree riêng. Sửa file ở fork vẫn ảnh hưởng filesystem. Muốn cách ly file thật → kết hợp `git worktree` / `git branch` (xem bài worktrees).
- **Tốn token:** tốn 1 lượt copy context (input). Fork từ session 100K thì nhánh mới mở đã 100K. Fork từ session dài nên `/compact` trước.
- **Version:** ổn định trên v2.1.x, mọi plan, CLI/IDE/Web/Desktop.
- **Nhầm lẫn phổ biến:** tưởng fork là git fork — không phải. Fork ở đây là fork conversation, không phải fork repo.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/fork` → `/rename` | Fork xong đặt tên ngay để khỏi nhầm nhánh |
| `/resume` → `/fork` | Mở bản cũ rồi fork để thử mới |
| `/fork` + git worktree | Cách ly cả memory lẫn files (xem bài 11) |
| `/fork` → `/export` | Thử xong, export nhánh thắng để lưu |

```bash
/fork Thử hướng B.
/rename huong-B
# ... thử xong, hướng B thắng ...
/export
# → lưu nhánh thắng, bỏ nhánh thua
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Fork xong 2 nhánh sửa cùng file loạn | Chung filesystem, không cách ly file | Dùng `git worktree` / `git branch` riêng cho mỗi hướng |
| Fork từ session 80% RAM, nhánh mới đã đầy | Copy nguyên history nặng | `/compact` trước khi fork, hoặc fork sớm hơn |
| Không biết đang ở nhánh nào | Quên rename sau fork | `/rename` ngay sau fork; kiểm tra picker `/resume` |
| Muốn gộp 2 nhánh tự động | Không có merge conversation | Copy ý hay bằng tay / ghi docs, không có nút merge |
| Gõ `/fork` báo unknown | CLI cũ | Update CLI |

---

## Tham khảo

- Lệnh liên quan:
  - [../branch/README.md](../branch/README.md) — what-if có nhãn
  - [../resume/README.md](../resume/README.md) — mở lại bản gốc
  - [../rewind/README.md](../rewind/README.md) — quay lại thay vì tách nhánh
  - [../rename/README.md](../rename/README.md) — đặt tên nhánh
  - [../export/README.md](../export/README.md) — lưu nhánh thắng
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — cách ly file thật với worktree
  - `../10-permissions-modes-availability.md` — permissions 2 nhánh có giống nhau không

> Mẹo 1 dòng: _trước ý tưởng risky, `/fork` 5 giây rẻ hơn `/rewind` 30 phút — giữ bản gốc sống sót._
