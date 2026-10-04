# /todos — Xem và quản lý danh sách việc cần làm của session hiện tại

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ đọc/ghi todo list trong memory session, không xóa/sửa code)

`/todos` là "bảng việc dán tường": liệt kê các đầu việc model đang theo (pending/in-progress/done), để bạn kiểm tra tiến độ, bổ sung, hoặc chốt trước khi compact/clear/bàn giao.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/todos` | _(không có)_ | Hiện todo list hiện tại (trạng thái từng việc) |

Không có flag `--add/--done` chính thức — muốn thêm/sửa thì dặn bằng lời sau lệnh.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem nhanh
/todos
```

```bash
# Dạng 2: xem + bổ sung bằng lời
/todos
# rồi nhắn: "Thêm việc viết docs cho API payments vào cuối list."
```

```bash
# Dạng 3: chốt trước khi compact/clear
/todos
/compact Giữ nguyên todo list này.
# hoặc
/todos
/export
/clear
```

```bash
# Dạng 4: kiểm tra định kỳ mỗi 30 phút
/todos
/context
```

---

## Cách nó hoạt động

1. **Todos sống trong session:** list do model duy trì (có thể tự tạo khi task nhiều bước). Mỗi item: nội dung + trạng thái (pending/doing/done) + đôi khi file liên quan.
2. **`/todos` chỉ render:** đọc state hiện tại, không gọi model nặng, tốn ~0 token.
3. **Mất theo session:** clear/compact mạnh tay/fork sai cách có thể làm rơi todos. Resume nạp lại theo transcript (có thể thiếu nếu transcript đã compact).
4. **Không phải issue tracker:** todos là scratchpad tạm, không sync GitHub Issues/Jira. Muốn lưu lâu dài → ghi ra file/`/export`.

| Lệnh | Phạm vi nhớ | Dùng khi nào |
|---|---|---|
| `/todos` | Việc trong session này | Theo dõi task nhiều bước |
| `/tasks` (`/bashes`) | Background jobs đang chạy | Quản việc chạy ngầm |
| GitHub Issues / file docs | Lâu dài, share team | Bàn giao, roadmap |

---

## Ví dụ thực tế

### Kịch bản 1: Task 5 bước — kiểm tra không sót

```bash
# Đang migration billing 5 bước, muốn biết tới đâu
/todos
# → 1.done 2.done 3.doing 4.pending 5.pending
# → nhắn: "Làm tiếp bước 3, xong báo tôi."
```

### Kịch bản 2: Chốt ca — todos vào báo cáo

```bash
/todos
/export
# → file export kèm todos, ca sau đọc là biết còn 2 việc
/clear
```

---

## Rủi ro & lưu ý

- **Mất gì:** clear/compact có thể làm mất/rút gọn todos. Luôn `/todos` + ghi ra file trước khi clear task dài.
- **Tốn token:** 0 khi xem. Nhưng todos dài (20+ items) chiếm context — nên giữ ≤7 items, gộp việc nhỏ.
- **Version:** v2.1.x mọi plan, mọi bề mặt. Không cần plugin.
- **Ảo giác hoàn thành:** model tick done nhưng code chưa thật sự xong → kiểm tra bằng test/`git status`, đừng tin tick 100%.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/todos` + `/context` | Cặp kiểm tra mỗi 30 phút |
| `/todos` → `/compact` | Giữ todos trong focus compact |
| `/todos` → `/export` → `/clear` | Chốt, lưu, xóa (quy trình tan ca) |
| `/resume` → `/todos` | Mở lại là kiểm tra việc dang dở |

```bash
/resume payments-fix
/todos
# → thấy còn bước 4/5 → làm tiếp đúng chỗ
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/todos` trống dù task dài | Model chưa tạo todos (task ít bước hoặc prompt chung) | Dặn: "Tạo todo list 5 bước cho task này" |
| Todos mất sau compact/clear | Gắn với conversation đã nén/xóa | Tạo lại tay; lần sau nêu "giữ todo list" trong focus compact, export trước clear |
| Model tick done nhưng code chưa xong | Tick theo kế hoạch, không verify | Bắt verify: "Mỗi todo done phải kèm lệnh test đã chạy + kết quả" |
| Todos quá dài (20+ items) | Chia việc quá vụn | Gộp thành ≤7 milestones, chi tiết để trong docs |
| Nhầm `/todos` với `/tasks` | Tên gần nhau | Todos = việc cần làm; tasks = jobs chạy ngầm (xem ../tasks) |

---

## Tham khảo

- Lệnh liên quan:
  - [../tasks/README.md](../tasks/README.md) — background jobs (đừng nhầm với todos)
  - [../compact/README.md](../compact/README.md) — giữ todos khi nén
  - [../clear/README.md](../clear/README.md) — todos mất khi xóa
  - [../resume/README.md](../resume/README.md) — todos sau khi mở lại
  - [../export/README.md](../export/README.md) — lưu todos vào báo cáo
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — todos đi kèm checkpoints
  - `../10-permissions-modes-availability.md` — ai được sửa todos

> Mẹo 1 dòng: _task >3 bước thì `/todos` ngay từ đầu — 10 giây nhìn list rẻ hơn 30 phút sót việc._
