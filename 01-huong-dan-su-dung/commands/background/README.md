# /background — Đẩy session đang chạy thành agent nền, rảnh tay làm việc khác

> Loại Built-in · Nhóm Session & Song song · Nguy hiểm Thấp (chạy nền vẫn dùng quyền session hiện tại; nhưng Có nếu task nền ghi file/xóa/migrate mà bạn quên đang có nó chạy)

`/background` detach session hiện tại thành một background agent: nó tự làm tiếp (code, test, research...), bạn rảnh terminal làm việc khác hoặc mở session mới. Muốn dừng: `Ctrl+X Ctrl+K` bấm 2 lần (kill background agent). Hiểu `/background` là hiểu "giao việc cho đàn em làm ở phòng bên, mình đi họp".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/background` | _(không có)_ | Detach session hiện tại → chạy nền, trả terminal về cho bạn |
| `/tasks` | _(lệnh xem)_ | Liệt kê agent nền đang chạy + trạng thái |
| `Ctrl+X Ctrl+K ×2` | phím kill | Dừng background agent (bấm 2 lần liên tiếp để xác nhận) |
| `/resume <id>` | session ID | Quay lại xem/kế thừa kết quả agent nền |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: task dài (test full, research 10 file) — đẩy nền rồi đi làm khác
# → đang dở: "phân tích 10 file auth, báo cáo lại"
/background
# → "Session detached as background agent (id: a3f9). Terminal free."
```

```bash
# Dạng 2: xem nền đang làm tới đâu
/tasks
# → a3f9 running (đọc file 6/10) | b7e1 done (report sẵn)
```

```bash
# Dạng 3: nền chạy xong / muốn dừng giữa chừng
/resume a3f9     # xem kết quả (done) hoặc tiếp quản
# Kill: Ctrl+X rồi Ctrl+K, lặp lại lần 2 để xác nhận
```

```bash
# Dạng 4: song song 2 việc — 1 nền + 1 foreground
/background      # việc A (nặng, lâu) chạy nền
# → mở session mới làm việc B nhẹ ở foreground
```

---

## Cách nó hoạt động

### Cơ chế sâu: detach rồi nó sống ở đâu?

1. **Detach, không fork mới:**
   - Khác `/fork` (rẽ nhánh giữ 2 bản foreground): `/background` lấy NGUYÊN session hiện tại đẩy xuống nền — foreground trống để bạn làm việc khác.
   - Context, todos, file đã đọc: mang theo hết. Agent nền tiếp tục đúng chỗ bạn dừng.
2. **Chạy với quyền session hiện tại:**
   - Permissions, MCP, model: kế thừa y nguyên. Session đang `Bash(rm -rf:*)` deny thì nền cũng deny — không leo thang.
   - Lưu ý ngược: session đang mở toang (`Bash(*)`) thì nền cũng mở toang — hẹp quyền TRƯỚC khi background task ghi/xoá.
3. **Báo trạng thái, không spam:**
   - Agent nền không chat với bạn liên tục; xong (hoặc kẹt cần hỏi) mới báo. Xem tiến độ chủ động bằng `/tasks`.
   - Kẹt cần quyết (xóa file? chọn hướng A/B?) → nó dừng + đánh dấu `needs-input`, bạn `/resume` vào quyết rồi thả lại.
4. **Kill 2 lần để chắc:**

```text
Ctrl+X Ctrl+K   lần 1 → "Kill background agent a3f9? (press again to confirm)"
Ctrl+X Ctrl+K   lần 2 → agent dừng, công việc dở giữ nguyên để /resume tiếp
→ 2 lần để bạn không kill nhầm khi đang gõ nhanh.
```

5. **Vòng đời đầy đủ:**

```text
foreground đang làm (task dài)
  │  /background
  ▼
background agent a3f9 chạy (bạn rảnh tay)
  ├─ /tasks → running 6/10...
  ├─ needs-input → /resume a3f9 → quyết → thả lại nền
  ├─ done → /resume a3f9 → lấy kết quả
  └─ sai hướng → Ctrl+X Ctrl+K ×2 → kill → /resume làm tiếp tay
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Chạy ở đâu? | Session? | Dùng khi nào? |
|---|---|---|---|
| `/background` | Nền, terminal rảnh | Mang NGUYÊN session đi | Task dài, muốn rảnh tay |
| `/fork` | Foreground (vẫn chiếm terminal) | Rẽ NHÁNH mới | Thử hướng khác, so sánh 2 hướng |
| `/tasks` | Chỉ xem/không chạy | — | Hỏi "nền làm tới đâu" |
| `/resume` | Foreground lại | TIẾP QUẢN session cũ | Lấy kết quả / quyết thay nền |
| `/subtask` | Subagent con trong session | Fork NHỎ báo về đây | Việc phụ 5 phút, không cần rời terminal |

> Quy tắc ngón tay cái:
>
> - **Việc dài cần rảnh tay → `/background`. Việc phụ muốn nó báo về đây → `/subtask`. Thử hướng khác → `/fork`. Chỉ muốn xem tiến độ → `/tasks`.**

---

## Ví dụ thực tế

### Kịch bản 1: Research 10 file auth (20 phút) — đẩy nền, đi review PR khác

```bash
# Bạn: "đọc 10 file src/auth, tìm mọi chỗ verify JWT, báo cáo file:dòng"
# → việc đọc lâu, không cần nhìn nó đọc:
/background
# → "Detached as a3f9. Terminal free."

# Bạn mở session mới review PR đồng nghiệp (10 phút)...
# /tasks → "a3f9 running (7/10)"
# ...5 phút nữa: "a3f9 done — report ready"

# Lấy kết quả:
/resume a3f9
# → báo cáo 6 chỗ verify + 2 chỗ thiếu. Copy sang task chính.
```

> Kết quả: 20 phút research chạy trong lúc bạn làm việc khác — thời gian thực tế tốn của bạn ≈ 2 phút (giao + nhận).

### Kịch bản 2: Test full + build dài — nền chạy, mình sửa bug khác

```bash
# Vừa code xong, cần npm test full (8 phút) + build (3 phút):
# → "chạy npm test full + npm run build, báo PASS/FAIL từng cái"
/background

# Trong lúc chờ: mở session mới sửa bug nhỏ #123 (không đụng file test đang chạy!)
# → /tasks: "a3f9 running (test 40/120)..."
# → xong: "a3f9 done: test 120/120 PASS, build OK"

# Lưu ý: 2 session cùng sửa 1 file = conflict. Chia việc không giẫm chân.
```

### Kịch bản 3: Nền kẹt cần quyết — resume vào quyết rồi thả lại

```bash
# /tasks → "a3f9 needs-input: xóa file legacy auth-old.ts? (Yes/No)"
/resume a3f9
# → vào session nền, đọc diff, quyết: "No — giữ, chỉ bỏ import"
# → dặn tiếp: "tiếp tục, xong báo" → /background (thả lại nền)
# → 5 phút sau done
```

### Kịch bản 4: Kill khi thấy sai hướng (đừng tiếc)

```bash
# /tasks → "a3f9 running" nhưng bạn nhận ra giao sai (nhầm thư mục):
# Kill: Ctrl+X Ctrl+K, rồi Ctrl+X Ctrl+K lần 2
# → "Background agent a3f9 stopped. Progress kept."

# Giao lại cho đúng:
/resume a3f9
# → "làm lại với src/auth-v2, bỏ kết quả cũ" → /background
```

> Đừng tiếc 10 phút nó chạy sai — kill sớm rẻ hơn nhận báo cáo sai rồi làm lại từ đầu.

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào? (quên có agent nền đang chạy)

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| Quên nền đang ghi file, mình cũng sửa cùng file | HAY GẶP NHẤT: conflict/ghi đè mất code | Chia việc không giẫm chân; `/tasks` trước khi sửa file nền đang đụng |
| Background với quyền mở toang | Nền `rm/migrate` nhầm không ai cản kịp | Hẹp permissions TRƯỚC khi `/background` task ghi/xoá |
| Nền kẹt `needs-input` 2 tiếng không ai xem | Tưởng nó chạy, hoá ra đứng chờ | `/tasks` mỗi 10-15 phút; task cần quyết nhiều thì ĐỪNG background |
| 3-4 agent nền cùng lúc | Tốn token/quota song song, máy lag | Tối đa 1-2 nền; việc nhỏ dùng `/subtask` thay vì nền mới |
| Kill 1 lần tưởng đã dừng | Bấm 1 lần chỉ là hỏi xác nhận — agent VẪN CHẠY | Bấm đủ 2 lần, `/tasks` xác nhận `stopped` |

### Tốn token?

- Background tiêu token như foreground (đọc file, chạy tool y hệt) — chỉ khác bạn không phải nhìn. Đặt giới hạn rõ ("đọc tối đa 10 file", "không quá 20 phút") trước khi đẩy nền.
- Nền kẹt vòng lặp (đọc đi đọc lại 1 file) tốn tiền mà không báo — `/tasks` định kỳ để bắt sớm.

### Version / provider

- `/background` + kill `Ctrl+X Ctrl+K ×2`: v2.x. Bản cũ chỉ có foreground đơn.
- `/tasks` xem nền: cùng bản. `/resume <id>`: v2.x.
- Bedrock/Vertex: nền kế thừa provider hiện tại (không login lại).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/background` + `/tasks` | Đẩy rồi ngó tiến độ | Background → tasks mỗi 10 phút |
| `/background` + `/resume` | Lấy kết quả / quyết thay | Done/needs-input → resume |
| `/background` + `/subtask` | Việc lớn nền + việc nhỏ con | Nền research, subtask tra 1 hàm |
| `/background` + `/permissions` | Hẹp quyền trước khi thả nền | Permissions → background |
| `/background` + `/verify` | Nền chạy test, mình review | Background test → resume lấy PASS/FAIL |

Workflow chuẩn "chiều nhiều việc (1 giờ)":

```bash
# 1. Hẹp quyền nếu task nền có ghi/xoá (30 giây)
/permissions
# 2. Giao việc dài cho nền
# "research auth, báo cáo lại" → /background
/background
# 3. Foreground làm việc nhẹ không giẫm chân (review PR, sửa bug khác)
# 4. Ngó mỗi 10-15 phút
/tasks
# 5. Done → lấy kết quả
/resume a3f9
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/background` xong terminal vẫn bận | Detach fail (tool đang chạy dở 1 lệnh dài) | Chờ lệnh hiện tại xong hẳn rồi `/background` lại |
| `Ctrl+X Ctrl+K` không kill | Bấm 1 lần (mới là hỏi), hoặc focus không ở terminal (đang ở IDE pane) | Bấm đủ 2 lần, focus đúng terminal; `/tasks` xác nhận stopped |
| `/tasks` không thấy agent vừa detach | Session ID chưa sync (detach ngay khi mạng lag) | Đợi 5s `/tasks` lại; không thấy nữa thì `/resume` mới nhất |
| Nền báo needs-input mà resume vào trống | Race: nền vừa tự quyết tiếp sau timeout | Đọc log agent trước khi quyết; dặn rõ "không tự quyết xóa, phải hỏi" từ đầu |
| 2 session ghi đè file nhau | Foreground + nền cùng sửa 1 file | Quy ước: file nào nền đụng thì mình không đụng; kill nền trước khi sửa tay |
| Nền chạy 1 tiếng chưa xong | Giao việc quá to ("refactor cả auth") không giới hạn | Kill, chia nhỏ ("chỉ research, không sửa"), giao lại; việc >30 phút nên chia |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../tasks/README.md](../tasks/README.md) — xem trạng thái agent nền
  - [../resume/README.md](../resume/README.md) — tiếp quản / lấy kết quả nền
  - [../fork/README.md](../fork/README.md) — rẽ nhánh foreground (khác detach nền)
  - [../permissions/README.md](../permissions/README.md) — hẹp quyền trước khi thả nền
  - [../clear/README.md](../clear/README.md) — dọn foreground sau khi giao nền
  - [../status/README.md](../status/README.md) — xem session ID đang giữ
- Bài tổng quan:
  - [../../02-cac-be-mat-terminal-ide-web-desktop.md](../../02-cac-be-mat-terminal-ide-web-desktop.md) — vòng đời session/foreground/nền
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md) — song song nâng cao (teams, song song nhiều agent)

> Mẹo 1 dòng: _giao việc dài cho nền, tay làm việc nhẹ, và đừng bao giờ sửa cùng 1 file với nó._
