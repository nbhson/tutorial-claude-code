# /tasks — Quản lý background jobs đang chạy ngầm (alias /bashes)

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (chỉ liệt kê/theo dõi jobs; kill job có thể dừng việc đang chạy — không xóa code)

`/tasks` (alias `/bashes`) là "trình quản lý tác vụ nền": xem jobs nào đang chạy (test suite, dev server, agent Explore dài), kiểm tra output, hoặc dừng job kẹt.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/tasks` | _(không có)_ | Liệt kê background jobs của session (id, lệnh, trạng thái, thời gian) |
| `/bashes` | _(không có)_ | Alias của `/tasks` (lịch sử tên cũ) |

Muốn kill/xem output chi tiết thì dặn bằng lời sau lệnh (tùy bản hỗ trợ kill theo id).

Ví dụ gọi từng dạng:

```bash
# Dạng 1: liệt kê jobs
/tasks
```

```bash
# Dạng 2: alias cũ
/bashes
```

```bash
# Dạng 3: xem rồi xử lý job kẹt
/tasks
# rồi nhắn: "Kill job npm test đang kẹt quá 10 phút, giữ lại dev server."
```

```bash
# Dạng 4: kiểm tra sau khi chạy song song
/tasks
/todos
# → jobs nào xong thì tick todos tương ứng
```

---

## Cách nó hoạt động

1. **Jobs từ đâu?** Khi bạn bảo chạy lệnh lâu (`npm test`, `npm run dev`, Explore codebase lớn), Claude Code có thể ném sang background để bạn làm việc khác. Mỗi job có id + logs riêng.
2. **`/tasks` đọc registry:** liệt kê id, command, status (running/done/failed/killed), thời gian chạy, exit code nếu xong.
3. **Không tự kill:** lệnh chỉ liệt kê. Kill phải xác nhận (tránh dừng nhầm dev server).
4. **Gắn với session:** jobs của session A không hiện ở session B. Clear session có thể mồ côi jobs → kiểm tra trước khi clear.

| Lệnh | Quản gì | Ví dụ |
|---|---|---|
| `/tasks` | Jobs chạy ngầm (tiến trình) | `npm test`, `dev server`, Explore dài |
| `/todos` | Việc cần làm (kế hoạch) | "Bước 1 auth, bước 2 payments..." |

---

## Ví dụ thực tế

### Kịch bản 1: Chạy test suite 10 phút — làm việc khác trong lúc chờ

```bash
# Bảo chạy test nặng nền
Hãy chạy npm test ở background, tôi làm docs trong lúc chờ.

# 5 phút sau kiểm tra
/tasks
# → npm test: running (5:00), dev server: running
# → làm tiếp docs, 5 phút nữa check lại
```

### Kịch bản 2: Job kẹt — tìm và kill

```bash
/tasks
# → job test-abc: running 25 phút (bất thường, mọi khi 5 phút là xong)
# → nhắn: "Kill job test-abc, chạy lại với --reporter=min, chỉ file payments."
```

---

## Rủi ro & lưu ý

- **Mất gì:** kill nhầm job mất output chưa đọc. Xem output trước khi kill jobs quan trọng.
- **Tốn token:** xem list ~0. Nhưng jobs chạy ngầm vẫn đốt CPU/thời gian và có thể gọi model (agent jobs) → tốn tiền dù bạn không nhìn.
- **Version:** `/tasks` + alias `/bashes` trên v2.1.x. Bản rất cũ chỉ có `/bashes`.
- **Jobs mồ côi:** clear/đóng terminal mà job còn chạy → tiến trình có thể treo. Kiểm tra `/tasks` trước khi clear/tắt máy.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/tasks` → `/todos` | Job xong thì tick việc tương ứng |
| `/tasks` → `/clear` | Kill/check jobs trước khi xóa session |
| `/tasks` + `/usage` | Job nào đốt tokens? (agent jobs dài) |
| `/tasks` + `/export` | Kèm trạng thái jobs vào báo cáo bàn giao |

```bash
/tasks
/todos
/export
# → báo cáo: jobs nào xong/chạy, việc nào done/pending
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/tasks` trống dù vừa chạy lệnh | Lệnh chạy foreground xong nhanh, không thành job nền | Đúng hành vi; chỉ lệnh lâu mới thành background job |
| Job running mãi không xong | Kẹt watch mode / chờ input / test treo | Kill rồi chạy lại với flags non-interactive (`--watchAll=false`, `--reporter=min`) |
| Kill nhầm dev server | Kill theo tên chung chung | Ghi rõ id: "kill job <id> test, giữ dev server" |
| `/bashes` báo unknown | Bản mới đổi tên chính thành `/tasks` | Dùng `/tasks`; update CLI để có cả 2 |
| Jobs session cũ không thấy | Jobs gắn theo session | Resume đúng session cũ rồi mới `/tasks` |

---

## Tham khảo

- Lệnh liên quan:
  - [../todos/README.md](../../session-context/todos/README.md) — việc cần làm (đừng nhầm với jobs)
  - [../usage/README.md](../../session-context/usage/README.md) — jobs nào đốt tokens
  - [../clear/README.md](../../session-context/clear/README.md) — check jobs trước khi xóa
  - [../export/README.md](../../session-context/export/README.md) — kèm jobs vào bàn giao
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../06-subagents-agent-teams-parallel.md` — agent teams sinh jobs song song
  - `../10-permissions-modes-availability.md` — quyền chạy background commands

> Mẹo 1 dòng: _lệnh nào >2 phút thì hỏi "chạy background được không?" rồi `/tasks` để canh — đừng ngồi nhìn cursor chớp._
