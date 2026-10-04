# /rename — Đặt tên dễ nhớ cho session hiện tại để mai resume 1 phát trúng

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đổi tên hiển thị trong index, không xóa/sửa code hay history)

`/rename` là "dán nhãn hộp đồ": đặt tên gợi nhớ (`payments-fix`, `migration-ca-dem`) cho session ID khô khan, để `/resume` / picker tìm thấy trong 3 giây.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/rename <tên>` | chuỗi tên (khuyên kebab-case, không dấu) | Gán/đổi tên session hiện tại |
| `/rename` | _(không có / trống)_ | Xem tên hiện tại hoặc được hỏi tên mới (tùy bản) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: đặt tên chuẩn
/rename payments-fix
```

```bash
# Dạng 2: tên có ngày + trạng thái (hợp ca trực)
/rename migration-2026-10-04-dang-do-buoc-3
```

```bash
# Dạng 3: đổi tên sau fork/branch để khỏi nhầm
/fork Thử hướng B.
/rename payments-huong-B
```

```bash
# Dạng 4: resume rồi rename lại cho rõ
/resume a1b2c3
/rename payments-da-fix-xong-cho-review
```

Quy ước đặt tên gợi ý:

```text
<task>-<phạm-vi>-<trạng-thái>
payments-webhook-dang-do
auth-rotation-thu-nghiem
migration-buoc-3-cho-test
```

---

## Cách nó hoạt động

1. **Ghi map name→id:** tên lưu trong index sessions (`~/.claude/projects/<hash>/index` hoặc metadata), trỏ tới file `.jsonl` của session. Không đổi ID, không chép file.
2. **Picker/resume dùng tên:** `/resume payments-fix` tra map rồi nạp đúng file. Tên trùng → bản mới hơn thắng hoặc báo ambiguous (tùy bản) → nên đặt tên duy nhất.
3. **Đổi tên thoải mái:** rename bao nhiêu lần cũng được, history không mất. Tên chỉ là nhãn.
4. **Phạm vi project:** tên chỉ có nghĩa trong cùng thư mục project. Sang repo khác, picker khác.

| Lệnh | Đổi gì | Có mất history không? |
|---|---|---|
| `/rename` | Nhãn hiển thị | Không |
| `/resume` | Nạp session vào RAM | Không (chỉ tốn tokens nạp) |
| `/fork` + `/rename` | Session mới + nhãn mới | Không (gốc còn) |

---

## Ví dụ thực tế

### Kịch bản 1: Tan ca đặt tên — sáng mai vào việc 10 giây

```bash
# 18h00, đang dở bước webhook
/todos
/rename payments-webhook-dang-do-mai-fix-tiep

# Sáng mai trong cùng thư mục:
/resume payments-webhook-dang-do-mai-fix-tiep
# → trúng ngay, khỏi lướt picker
```

### Kịch bản 2: Quản 3 nhánh song song không nhầm

```bash
# Nhánh chính
/rename payments-chinh-huong-A

# Fork thử B
/fork Thử hướng B.
/rename payments-thu-huong-B

# Branch spike
/branch Thử cache Redis.
/rename payments-spike-redis
# → picker hiện 3 tên rõ ràng, không còn a1b2/e5f6 khô khan
```

---

## Rủi ro & lưu ý

- **Mất gì:** không mất gì. Rủi ro duy nhất là **tên trùng/gây hiểu nhầm** (`fix`, `test`, `final-final`) → mai resume nhầm session.
- **Tốn token:** 0.
- **Version/provider:** v2.1.x mọi plan, mọi bề mặt. Ký tự đặc biệt/tiếng Việt có dấu có thể hiển thị khác nhau giữa CLI/IDE — nên dùng kebab-case không dấu.
- **Bảo mật:** tên session có thể hiện trong picker share màn hình → đừng đặt tên chứa secret/khách hàng nhạy cảm.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/rename` → `/resume` | Cặp quốc dân: đặt hôm nay, mở ngày mai |
| `/fork` → `/rename` | Fork xong dán nhãn ngay |
| `/branch` → `/rename` | Nhánh thử nêu giả thuyết trong tên |
| `/todos` → `/rename` | Chốt trạng thái rồi mã hóa vào tên (`-dang-do-buoc-3`) |

```bash
/todos
# → còn 2/5 → mã hóa vào tên
/rename billing-buoc-3-trong-5
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/resume <tên>` báo not found | Sai chính tả, sai dấu, khác hoa/thường | `/resume` (picker) để copy tên chính xác; dùng kebab-case không dấu |
| 2 sessions cùng tên | Đặt tên chung chung (`fix`, `test`) | Đặt tên duy nhất có ngày/phạm vi; rename lại 1 trong 2 |
| Tên có khoảng trắng bị cắt | Shell/parse tách từ | Quote: `/rename "my session"` hoặc dùng gạch ngang |
| Sang máy/repo khác không thấy tên | Tên lưu theo project + account local/cloud | Đứng đúng thư mục + đúng account; export file nếu cần mang đi |
| Muốn xóa tên nhạy cảm | Tên nằm trong index | `/rename` sang tên trung tính; xóa transcript nếu cần (xem bài resume) |

---

## Tham khảo

- Lệnh liên quan:
  - [../resume/README.md](../../session-context/resume/README.md) — dùng tên để mở lại
  - [../fork/README.md](../../session-context/fork/README.md) — fork xong đặt tên
  - [../branch/README.md](../../session-context/branch/README.md) — nhánh thử đặt tên giả thuyết
  - [../todos/README.md](../../session-context/todos/README.md) — mã hóa tiến độ vào tên
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — tên session vs tên git branch (2 thứ khác nhau)

> Mẹo 1 dòng: _tên tốt = mai resume không cần nghĩ: `<task>-<trạng-thái>` bằng kebab-case không dấu._
