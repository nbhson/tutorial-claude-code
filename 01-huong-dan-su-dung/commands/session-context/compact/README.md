# /compact — Nén lịch sử hội thoại thành tóm tắt, giữ đà task mà nhẹ context

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (không xóa/sửa file code; chỉ thay conversation dài bằng bản tóm tắt — chi tiết gốc không khôi phục trong phiên)

`/compact` là "nén RAM có chọn lọc": thay vì xóa trắng như `/clear`, nó tóm tắt toàn bộ hội thoại thành 1 bản summary gọn rồi tiếp tục task từ đó. Dùng khi context đầy nhưng bạn vẫn đang làm dở cùng 1 task.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/compact` | _(không có)_ | Tự động tóm tắt toàn bộ history |
| `/compact <focus>` | text tự do sau lệnh | Nén nhưng nhấn mạnh khía cạnh cần giữ (file, quyết định, bước tiếp theo) |
| Auto-compact | _(tự động ở ~80% context)_ | Claude Code tự nén khi sắp đầy, không cần gõ |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: nén cơ bản
/compact
```

```bash
# Dạng 2: nén có focus — giữ quyết định kiến trúc
/compact Giữ lại quyết định dùng Postgres + Drizzle, file đã sửa src/db/schema.ts, bước tiếp theo là migration.
```

```bash
# Dạng 3: nén giữ danh sách file đang đụng
/compact Tập trung vào các file trong src/payments/ và lỗi stripe webhook chưa fix xong.
```

```bash
# Dạng 4: nén giữ todos
/compact Giữ nguyên todo list: xong auth, đang làm payments (bước 2/5), chưa làm refunds.
```

```bash
# Dạng 5: kiểm tra trước khi compact
/context
# → thấy 68%, toàn log rác ở đầu + quyết định quan trọng ở cuối
/compact Chỉ giữ quyết định ở 20 tin nhắn cuối, bỏ log debug ở đầu.
```

Không có flag `--size`, `--ratio`, `--model`. Focus là text tự do, không phải cú pháp key=value.

---

## Cách nó hoạt động

### Under-the-hood: 5 bước khi bạn Enter `/compact`

1. **Thu thập history thô:**
   - Toàn bộ turns (user prompts, assistant answers, tool calls, file diffs, test outputs, todos) được gom lại thành 1 batch.
2. **Gọi 1 lượt summarization:**
   - Claude Code dùng 1 model tóm tắt (thường là model rẻ/nhanh hơn hoặc cùng model ở chế độ nén) để viết bản summary có cấu trúc: _mục tiêu task, quyết định đã chốt, file đã đổi, test đã chạy, bước tiếp theo, cạm bẫy cần tránh._
   - Nếu bạn ghi focus (`/compact <focus>`), focus được chèn vào prompt tóm tắt như instruction ưu tiên cao.
3. **Thay context bằng summary:**
   - History chi tiết (có thể 100K+ tokens) bị loại khỏi context window, thay bằng summary (~1-3K tokens).
   - Token usage tụt từ ví dụ 75% về ~8-12%.
4. **Giữ nguyên đĩa + session:**
   - File code, git branch, todos (dạng rút gọn), CLAUDE.md, MCP connections giữ nguyên.
   - Session ID không đổi — bạn vẫn ở cùng phiên, chỉ nhẹ đầu hơn.
5. **Tiếp tục từ summary:**
   - Prompt tiếp theo của bạn được xử lý với context = `system + CLAUDE.md + summary + prompt mới`.
   - Model không còn nhớ nguyên văn code cũ, chỉ nhớ "đã sửa file X để làm Y".

```text
[History 120K tokens] --summarize--> [Summary 2K tokens] + prompt mới
  chi tiết từng dòng code            chỉ còn: mục tiêu, quyết định,
  log test dài 800 dòng              file đã đổi, bước tiếp theo
```

### Summary mẫu (minh họa cấu trúc thật)

```markdown
# Compact summary
- Goal: triển khai POST /api/payments với Stripe.
- Decisions: dùng Postgres + Drizzle; idempotency-key ở header.
- Changed: src/payments/route.ts (thêm handler), src/db/schema.ts (bảng payments).
- Tested: `npm test payments` — 2 failed do thiếu mock webhook.
- Next: fix mock webhook, chạy lại test, viết docs.
- Pitfalls: đừng đổi secret key trong .env, đừng sửa src/auth/.
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Kết quả | Mất gì | Khi nào dùng |
|---|---|---|---|
| `/compact` | Giữ task, gọn context | Chi tiết nguyên văn (log, code cũ) | Cùng task, context 50-80% |
| `/clear` | Trắng tinh | Toàn bộ memory task | Đổi task khác hẳn |
| `/rewind` | Quay về checkpoint đúng nguyên văn đoạn trước | Đoạn sau checkpoint | Đi sai hướng muốn quay lại |
| `/fork` | Copy sang phiên mới giữ nguyên văn | Không mất (bản gốc còn) | Muốn thử hướng khác song song |
| Auto-compact | Giống `/compact` nhưng tự động | Giống compact, nhưng không có focus của bạn | Khi bạn quên compact tay |

> Kinh nghiệm xương máu: _auto-compact không có focus thường tóm tắt chung chung và hay làm rơi quyết định quan trọng._ Nên compact tay với focus rõ ràng khi context chạm ~60%.

### Focus ảnh hưởng thế nào?

- Không focus: summary cân đều mọi thứ → dễ giữ cả rác (log debug) mà làm rơi cái quan trọng (tên file, số dòng).
- Có focus: summary ưu tiên giữ entity bạn nêu (tên file, quyết định, bước tiếp theo) và mạnh tay bỏ phần còn lại.
- Focus tốt nêu 3 thứ: **quyết định + file + bước tiếp theo.** Ví dụ: _"Giữ quyết định X, file Y đã sửa, bước tiếp là Z."_

---

## Ví dụ thực tế

### Kịch bản 1: Task refactor dài 3 tiếng, context 72% — compact giữ đà

Bạn đang refactor `src/auth/` sang JWT rotation. Đã sửa 8 file, chạy test 5 lần, context phình 72%.

```bash
# Bước 1: kiểm tra
/context
# → usage 72%, phần lớn là log test cũ

# Bước 2: compact có focus
/compact Giữ lại: mục tiêu chuyển sang JWT rotation, 8 file đã sửa trong src/auth/, quyết định dùng refresh-token 7 ngày, bước tiếp theo là fix 2 test fail ở auth.test.ts.

# Bước 3: tiếp tục ngay, không cần đọc lại file
Hãy fix 2 test fail còn lại trong auth.test.ts, chỉ sửa file test, không đổi logic src/.
```

> Kết quả: context về ~10%, model vẫn nhớ "đang làm JWT rotation, đã sửa những file nào", không cần giải thích lại từ đầu.

### Kịch bản 2: Debug production log khổng lồ — bỏ log, giữ kết luận

Bạn paste 3 file log (mỗi file 400 dòng) để tìm race condition. Đã tìm ra nguyên nhân nhưng context nặng trĩu log.

```bash
# Compact bỏ log thô, chỉ giữ kết luận
/compact Bỏ toàn bộ log thô, chỉ giữ: nguyên nhân là race condition ở worker pool (src/queue/worker.ts:42), fix dự kiến là thêm mutex, bước tiếp theo là viết patch.

# Hỏi tiếp nhẹ tênh
Hãy viết patch mutex cho src/queue/worker.ts theo kết luận trên.
```

### Kịch bản 3: Chuỗi compact định kỳ trong task siêu dài (monorepo migration)

```bash
# Mỗi 45-60 phút hoặc mỗi khi /context > 60%, compact 1 lần
/context
/compact Tập trung vào module đang migrate (packages/billing/), bỏ chi tiết module đã xong (packages/auth/).

# ... làm tiếp 1 tiếng ...

/context
/compact Tập trung vào lỗi type còn lại ở billing/invoice.ts, giữ quyết định dùng Zod strict mode.
```

### Kịch bản 4: Compact trước khi bàn giao ca / trước khi `/export`

```bash
# Muốn bản export gọn để gửi đồng đội, compact trước cho summary đẹp
/compact Tóm tắt để bàn giao: đã xong gì, đang dở gì, ai làm tiếp cần đọc file nào.

/export
# → file export giờ mở đầu bằng summary gọn, đồng đội đọc 1 phút là hiểu
```

---

## Rủi ro & lưu ý

### Mất gì? Có cứu được không?

| Mất gì | Cứu được không? | Ghi chú |
|---|---|---|
| Nguyên văn code/log cũ trong chat | Không (trong phiên) | Muốn xem lại phải mở file trên đĩa hoặc transcript `.jsonl` |
| Số dòng chính xác, stack trace chi tiết | Thường bị làm tròn / bỏ | Nên ghi số dòng quan trọng ra file trước khi compact |
| Ảnh / diagram đã paste | Có thể bị mô tả lại sơ sài | Paste lại nếu cần chi tiết pixel |
| Todos chi tiết | Có thể bị rút gọn quá mức | Nêu rõ "giữ nguyên todo list" trong focus |
| Code trên đĩa, git, CLAUDE.md | Không mất | An toàn tuyệt đối |

> **Ảo giác nguy hiểm nhất:** sau compact, model nói tự tin như thể vẫn nhớ chi tiết, nhưng thực ra chỉ đọc summary. Hãy bảo nó "đọc lại file X" khi cần chính xác từng dòng.

### Tốn token?

- 1 lần compact tốn 1 lượt summarization (vài nghìn tokens output + đọc toàn bộ history 1 lần cuối). Nhưng sau đó mỗi prompt tiết kiệm hàng chục nghìn tokens.
- Bài toán hòa vốn: nếu còn ≥5 prompts nữa trong cùng task, compact luôn lời.
- Auto-compact dùng model nào thì tính tiền model đó (thường rẻ hơn model chính).

### Version tối thiểu & provider

- Có từ bản sớm, hoàn thiện focus trên v2.0+, ổn định trên v2.1.x.
- Mọi plan đều dùng được (Free/Pro/Team/API). Không cần plugin.
- CLI + IDE + Web + Desktop đều hỗ trợ. CLI có thêm auto-compact khi chạy interactive; `--print` mode không compact vì mỗi lần gọi là 1 shot.

### Cloud vs Local

| Môi trường | Khác biệt |
|---|---|
| CLI local | Summary lưu trong transcript `.jsonl`, có thể soi lại history thô bằng editor |
| IDE | Panel chat hiện 1 dòng "Compacted" + summary thu gọn, bấm để mở rộng |
| Web/Desktop | Hiển thị tương tự, transcript cloud giữ cả pre-compact theo retention |

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/context` → `/compact` | Chuẩn vàng: xem đầy bao nhiêu rồi compact đúng lúc |
| `/compact` + focus file | Nêu tên file + quyết định + bước tiếp theo trong focus |
| `/compact` → `/export` | Compact cho gọn rồi export cho đồng đội dễ đọc |
| `/compact` → `/clear` | Compact vài lần mà task vẫn xong → clear để sang task mới |
| `/compact` → `/todos` | Sau compact kiểm tra todos còn đủ không, bổ sung nếu summary làm rơi |
| `/compact` → `/rewind` | Compact xong thấy summary sai hướng → rewind về checkpoint trước compact (nếu còn) |

Anti-pattern:

```bash
# SAI: compact khi đã đổi task — summary cũ làm nhiễm task mới
/compact
Hãy viết game Tetris (trong khi summary cũ toàn chuyện payments)
# → ĐÚNG phải là /clear, không phải /compact
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Compact xong model quên tên file quan trọng | Focus quá chung chung ("tóm tắt giúp tôi") | Compact lại không cứu được (history đã mất); lần sau focus nêu tên file cụ thể. Trước mắt bảo model đọc lại file / `glob` tìm lại |
| Compact xong todos biến mất | Summary bỏ qua todos | Gõ `/todos` kiểm tra, tạo lại tay; lần sau focus ghi "giữ nguyên todo list" |
| Auto-compact tự chạy giữa chừng, summary xấu | Chạm ngưỡng ~80% mà không compact tay trước | Chủ động `/compact <focus>` ở ~60%; vào settings chỉnh ngưỡng nếu bản bạn cho phép |
| `/compact` báo không có gì để nén | Context còn quá nhẹ (<10%) hoặc vừa clear xong | Không cần compact, cứ làm tiếp |
| Compact xong model bịa chi tiết (hallucinate số dòng) | Summary không ghi số dòng, model đoán | Bắt model `read` lại file, cấm đoán số dòng; ghi số dòng quan trọng ra file trước khi compact |
| Muốn xem lại đoạn trước compact | Panel chỉ hiện summary | Mở transcript `.jsonl` trong `~/.claude/projects/<hash>/` hoặc `/export` trước khi compact ở lần sau |
| Compact trong `--print` không có tác dụng | Non-interactive mỗi lần gọi là stateless | Không dùng compact ở chế độ 1-shot; chỉ có ý nghĩa trong session interactive |

---

## Tham khảo

- Lệnh liên quan:
  - [../clear/README.md](../../session-context/clear/README.md) — khi nào xóa trắng thay vì nén
  - [../context/README.md](../../session-context/context/README.md) — đo % trước khi compact
  - [../rewind/README.md](../../session-context/rewind/README.md) — quay checkpoint khi compact sai hướng
  - [../todos/README.md](../../session-context/todos/README.md) — giữ todos không rơi sau compact
  - [../export/README.md](../../session-context/export/README.md) — lưu bản gọn sau compact
  - [../resume/README.md](../../session-context/resume/README.md) — mở lại session đã compact
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ slash commands
  - `../11-git-worktrees-checkpoints.md` — checkpoints vs compact summary
  - `../03-claude-md-memory-rules.md` — CLAUDE.md sống sót qua compact
  - `../10-permissions-modes-availability.md` — permissions không đổi sau compact

> Mẹo 1 dòng: _thấy `/context` > 60% là compact tay ngay với focus "quyết định + file + bước tiếp theo" — đừng đợi auto-compact._
