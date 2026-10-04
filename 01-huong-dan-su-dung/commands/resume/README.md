# /resume — Mở lại phiên cũ theo ID/tên hoặc picker, tiếp tục đúng chỗ dang dở

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file; chỉ nạp lại transcript cũ vào context — an toàn, nhưng có thể tốn tokens để nạp lại)

`/resume` là "cỗ máy thời gian phiên làm việc": liệt kê các session trước (theo ID/tên), cho bạn mở lại đúng chỗ dang dở thay vì giải thích lại từ đầu. Cặp song sinh với CLI flags `--continue` / `--resume`.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/resume` | _(không có)_ | Mở picker liệt kê sessions gần đây để chọn |
| `/resume <id-hoặc-tên>` | session id / name | Mở thẳng session cụ thể, khỏi picker |
| `claude --continue` | _(CLI flag)_ | Tiếp tục session gần nhất, không hỏi |
| `claude --resume [<id>]` | id tùy chọn | Tiếp tục session chỉ định (hoặc picker nếu bỏ trống) |

Bảng tham số chi tiết:

| Tham số | Ví dụ | Ghi chú |
|---|---|---|
| _(trống)_ | `/resume` | Picker hiện ~10-20 sessions gần nhất: tên, thời gian, preview dòng cuối |
| `<session-id>` | `/resume a1b2c3d4` | ID đầy đủ hoặc prefix duy nhất (như git short hash) |
| `<session-name>` | `/resume payments-fix` | Nếu bạn đã `/rename` session trước đó thì gọi bằng tên dễ nhớ |
| `--continue` (CLI) | `claude --continue` | Shortcut: luôn lấy session mới nhất, hợp cho "sáng mở máy làm tiếp" |
| `--resume` (CLI) | `claude --resume` / `claude --resume a1b2` | Bản CLI của `/resume`, dùng trong terminal ngoài IDE |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: picker trực quan (khuyên dùng khi không nhớ ID)
/resume
# → chọn "payments-fix · 2h trước · đang dở bước webhook mock"
```

```bash
# Dạng 2: mở thẳng bằng tên (sau khi đã /rename)
/rename payments-fix
# ... hôm sau ...
/resume payments-fix
```

```bash
# Dạng 3: mở bằng ID ngắn
/resume a1b2c3
```

```bash
# Dạng 4: CLI — tiếp tục phiên gần nhất (sáng thứ Hai)
/bin/bash -c 'claude --continue'
# hoặc nếu claude trong PATH:
# claude --continue
```

```bash
# Dạng 5: CLI — picker ngoài terminal
claude --resume
```

```bash
# Dạng 6: CLI — resume + hỏi tiếp 1 shot
claude --resume payments-fix --print "Chạy lại test payments và báo kết quả"
```

---

## Cách nó hoạt động

### Under-the-hood

1. **Transcript lưu ở đâu?**
   - Mỗi session ghi append-only vào file `~/.claude/projects/<project-hash>/<session-id>.jsonl`: từng user prompt, assistant message, tool call/result, todos, checkpoints.
   - `/rename` chỉ gán thêm `name → id` trong index, không đổi file.
2. **Picker đọc index:**
   - `/resume` (không tham số) đọc index sessions của project hiện tại, sắp xếp theo `mtime`, hiện preview (câu cuối, số turns, thời gian).
   - Chỉ liệt kê sessions cùng project directory (đổi thư mục là sang namespace khác).
3. **Nạp lại vào context:**
   - Khi chọn 1 session, Claude Code đọc lại toàn bộ (hoặc cửa sổ gần nhất + summary nếu quá dài) vào context window mới.
   - Nghĩa là bạn tốn 1 lượt input tokens để "hồi sinh" memory. Session càng dài càng tốn.
   - Nếu session cũ đã bị compact trước đó, bản nạp lại bắt đầu từ summary đã compact (không lấy lại được chi tiết đã nén).
4. **Tiếp tục append:**
   - Mọi prompt mới sau resume được append tiếp vào cùng file `.jsonl` (giữ 1 lịch sử liền mạch). Checkpoints/rewind cũng dùng chung timeline này.
5. **Quan hệ với `/clear`:**
   - `/clear` tạo marker trong transcript nhưng không xóa file. Nên `/resume` đôi khi vẫn thấy được đoạn trước clear (tùy bản). Đừng coi clear là xóa pháp lý.

```text
~/.claude/projects/<hash>/
  a1b2c3d4.jsonl  ← "payments-fix" (120 turns, 2h trước)
  e5f6g7h8.jsonl  ← "css-tweak" (15 turns, hôm qua)
  i9j0k1l2.jsonl  ← "migration" (80 turns, tuần trước)
/resume → đọc index → picker → chọn a1b2 → nạp 120 turns vào RAM → append tiếp
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Ý nghĩa | Khi nào dùng |
|---|---|---|
| `/resume` | Mở lại session cũ (có thể từ hôm qua/tuần trước) | Tiếp tục việc dang dở |
| `/fork` | Copy session hiện tại sang nhánh mới (giữ bản gốc) | Muốn thử hướng khác mà không phá bản gốc |
| `/branch` | Tương tự fork nhưng gắn nhãn what-if thử nghiệm | Thử giả thuyết song song |
| `/rewind` | Quay ngược trong cùng session về checkpoint cũ | Đi sai hướng trong cùng task |
| ` --continue` | Resume phiên gần nhất, không picker | Sáng mở máy làm tiếp 1 lệnh là xong |
| `/export` | Xuất transcript ra text để đọc/gửi, không nạp vào RAM | Bàn giao, không phải để làm tiếp |

> Quy tắc: _muốn làm tiếp → `/resume`. Muốn giữ bản gốc + thử hướng mới → `/fork`/`/branch`. Muốn quay lại → `/rewind`. Muốn gửi người khác đọc → `/export`._

---

## Ví dụ thực tế

### Kịch bản 1: Sáng thứ Hai mở máy — tiếp tục đúng chỗ tối thứ Sáu

```bash
# Tối thứ Sáu: đang dở bước mock webhook, đặt tên trước khi về
/rename payments-fix

# Sáng thứ Hai: mở terminal trong cùng thư mục dự án
/resume payments-fix
# → model: "Chào, hôm trước ta đang dở bước mock webhook ở src/payments/webhook.test.ts. Tiếp tục nhé?"

# Hỏi tiếp, không cần giải thích lại
Hãy chạy lại test payments và chỉ fix phần mock còn fail.
```

```bash
# Biến thể CLI 1 lệnh (không vào IDE):
claude --continue
# → tự lấy session mới nhất (chính là payments-fix) và tiếp tục
```

### Kịch bản 2: Quên tên — dùng picker + preview

```bash
/resume
# → picker hiện:
#   1. payments-fix · 2h trước · "mock webhook còn 2 fail..."
#   2. css-tweak · hôm qua · "xong button padding..."
#   3. migration · 3 ngày trước · "compacted summary..."
# → chọn 1 bằng phím mũi tên + Enter
```

### Kịch bản 3: Resume xong compact ngay vì session dài

Session cũ 120 turns, nạp lại tốn 90K tokens (45% RAM). Muốn nhẹ mà vẫn giữ đà:

```bash
/resume payments-fix

/context
# → 62% ngay khi vừa mở (vì history dài)

/compact Giữ quyết định Postgres+Drizzle, file src/payments/* đã sửa, bước tiếp là fix webhook mock.
# → về ~12%, làm tiếp nhẹ tênh
```

### Kịch bản 4: Resume để cứu sau khi `/clear` nhầm

```bash
# Lỡ tay /clear mất 2 tiếng thảo luận
/clear

# Cứu: resume lại session vừa clear (transcript vẫn trên đĩa)
/resume
# → chọn session vừa rồi (thường là dòng đầu, "vài giây trước")
# → history quay lại (tùy bản, có thể kèm marker clear)
```

### Kịch bản 5: Resume trong automation (CI/cron)

```bash
# Đêm chạy batch: resume session migration rồi hỏi 1 shot, không cần interactive
claude --resume migration --print "Kiểm tra migration staging có lỗi không, trả lời ngắn gọn OK/FAIL + log."
```

---

## Rủi ro & lưu ý

### Mất gì? Tốn gì?

| Mục | Thực tế |
|---|---|
| File code | Không mất, không tự đổi khi resume. Chỉ nạp memory. |
| Tokens | Tốn 1 lượt nạp history (vài chục nghìn tokens). Session càng dài càng đắt. Nên compact ngay sau resume nếu dài. |
| Todos/checkpoints | Nạp lại theo transcript. Nếu session cũ đã clear/compact, todos có thể thiếu → kiểm tra `/todos` sau resume. |
| Secrets trong transcript | Nạp lại cả secrets cũ vào RAM. Đừng resume session nhiễm secret trên máy share. |

### Giới hạn cần biết

- **Cùng thư mục project:** resume chỉ thấy sessions của project hiện tại. Đổi `cd` sang repo khác là picker khác.
- **Retention:** transcript local giữ tới khi bạn xóa `~/.claude/` hoặc tool xoay vòng. Transcript cloud theo retention plan (Free ngắn hơn Team).
- **Session quá cũ + model đổi:** resume session 1 tháng trước bằng model mới có thể hơi "lạc giọng" vì summary/tools đã đổi. Đọc lại file quan trọng để đồng bộ.
- **Không phải undo cho file:** resume chỉ hồi memory hội thoại. File đã `git commit` / checkpoint mới là nơi cứu code. Muốn quay code → `/rewind` hoặc `git`.

### Version tối thiểu & provider

- Picker `/resume` + `--continue`/`--resume` ổn định trên v2.1.x (CLI/IDE/Web/Desktop đều có, CLI có thêm flags).
- Mọi plan dùng được. Subscription được lợi nhất (quota resume rẻ nhờ cache). API pay-as-you-go trả tiền nạp lại theo tokens thật.
- Không cần MCP/plugin.

### Cloud vs Local

| Môi trường | Hành vi |
|---|---|
| CLI local | Đọc `.jsonl` trực tiếp, nhanh nhất, thấy cả sessions offline |
| IDE | Picker đồ họa + preview đẹp, tìm theo tên/từ khóa |
| Web/Desktop | Đọc transcript cloud, có thể thiếu sessions chỉ lưu local và ngược lại |

> Nếu picker trống dù nhớ đã làm: kiểm tra có đang đứng đúng thư mục project không (`pwd`), và có đăng nhập đúng account/profile không.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/rename` → `/resume` | Đặt tên dễ nhớ hôm nay để mai resume 1 phát trúng |
| `/resume` → `/context` | Vừa mở lại là đo RAM ngay |
| `/resume` → `/compact` | Session dài thì nén nhẹ sau khi mở |
| `/resume` → `/todos` | Kiểm tra todos còn đủ không sau khi nạp |
| `/resume` + `/export` | Mở lại rồi export cho người khác đọc |
| `/resume` + `/fork` | Mở bản cũ rồi fork để thử hướng mới không phá bản gốc |
| `/clear` nhầm → `/resume` | Cứu history vừa xóa |

Thói quen "đóng ca 30 giây":

```bash
# Trước khi tắt máy: đặt tên + chốt todos
/todos
/rename payments-fix-webhook-dang-do

# Sáng mai: 1 lệnh là vào việc
/resume payments-fix-webhook-dang-do
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/resume` picker trống | Đứng sai thư mục / sai profile / transcript bị xóa | `pwd` kiểm tra repo, đăng nhập đúng account, kiểm tra `~/.claude/projects/` còn file không |
| `/resume <tên>` báo not found | Sai tên (phân biệt hoa/thường, dấu `-`/`_`) hoặc tên có khoảng trắng chưa quote | Gõ `/resume` không tham số để picker rồi copy tên chính xác; quote nếu có space: `/resume "my session"` |
| Resume xong context vọt 70% | Session cũ quá dài, nạp nguyên 100+ turns | `/compact` ngay với focus rõ; lần sau compact trước khi nghỉ |
| Resume xong model "quên" file mới nhất | File trên đĩa đã đổi sau khi session lưu (đồng đội push thêm) | Bảo model `git pull` + `read` lại file, đừng tin memory cũ 100% |
| `claude --continue` mở nhầm session | Nó lấy mới nhất, mà mới nhất là task vặt xen giữa | Dùng `claude --resume` (picker) hoặc `--resume <id>` cụ thể |
| Resume session từ 1 tháng trước, tool báo lỗi | Tools/MCP/model đã đổi version, transcript cũ reference tool không còn | Coi transcript như tài liệu tham khảo, bắt đầu task mới từ file hiện tại; cần thì `/fork` thay vì resume sâu |
| Muốn xóa session khỏi picker (nhạy cảm) | Transcript vẫn nằm trên đĩa/cloud | Xóa file `.jsonl` tương ứng + xóa cloud history trong settings/dashboard; rotate secrets đã paste |

---

## Tham khảo

- Lệnh liên quan:
  - [../fork/README.md](../fork/README.md) — mở nhánh mới từ session hiện tại
  - [../branch/README.md](../branch/README.md) — thử what-if song song
  - [../rewind/README.md](../rewind/README.md) — quay checkpoint trong cùng session
  - [../rename/README.md](../rename/README.md) — đặt tên để resume dễ
  - [../export/README.md](../export/README.md) — xuất ra text để gửi người khác
  - [../todos/README.md](../todos/README.md) — kiểm tra việc dang dở sau resume
  - [../clear/README.md](../clear/README.md) — khi resume xong thấy task đã xong thì clear
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../11-git-worktrees-checkpoints.md` — checkpoints đi kèm transcript thế nào
  - `../10-permissions-modes-availability.md` — permissions sau resume có giữ không
  - `../03-claude-md-memory-rules.md` — memory ngoài transcript (CLAUDE.md) cũng được nạp lại

> Mẹo 1 dòng: _tan ca đặt `/rename` cho session đang dở — sáng mai `/resume` 1 phát là vào việc, khỏi giải thích lại 15 phút._
