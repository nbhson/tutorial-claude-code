# /context — Kính hiển vi context window: đang đầy bao nhiêu, nặng ở đâu

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (lệnh chỉ đọc, không xóa/sửa gì cả — an toàn tuyệt đối)

`/context` mở bảng "grid visualize": cho bạn thấy context window đã dùng bao nhiêu %, nặng ở chỗ nào (system, CLAUDE.md, history, tools, MCP), để quyết định nên `/compact`, `/clear` hay cứ làm tiếp.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/context` | _(không có)_ | Hiện bảng phân bổ context hiện tại |
| `/context` _(gõ lại sau mỗi 30-60 phút)_ | — | Theo dõi đà phình context trong task dài |

Không có flag, không có focus text. Lệnh read-only.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: kiểm tra cơ bản
/context
```

```bash
# Dạng 2: kiểm tra trước quyết định compact hay clear
/context
# → 72% + toàn log test → /compact (cùng task)
# → 72% + task đã xong → /clear (đổi task)
```

```bash
# Dạng 3: kiểm tra sau khi paste file lớn
# Vừa paste 3 file log, muốn biết tốn bao nhiêu
/context
```

```bash
# Dạng 4: kiểm tra định kỳ trong task dài (đặt nhắc tay)
/todos
/context
# → todos còn 2/5, context 58% → compact nhẹ rồi làm tiếp
```

Output mẫu (minh họa, số liệu tùy model):

```text
Context usage: 68% (136K / 200K tokens)
[██████████████░░░░░░]
Breakdown:
  System prompt + tools:  8K  (4%)
  CLAUDE.md + memory:     3K  (2%)
  Conversation history:  95K (48%)
  Tool results / files:  28K (14%)
  MCP outputs:            2K  (1%)
Tip: consider /compact with focus to shed tool results.
```

---

## Cách nó hoạt động

### Under-the-hood

1. **Đếm tokens thực tế:**
   - Claude Code đếm tokens theo tokenizer của model đang dùng (ví dụ Sonnet/Opus 200K window). Mỗi phần (system, CLAUDE.md, history, tool definitions, tool results, ảnh) được đo riêng.
   - Ảnh và file đính kèm được quy đổi ra tokens (ảnh ~1-2K tokens tùy độ phân giải).
2. **Vẽ grid / breakdown:**
   - Panel hiện thanh tiến trình + bảng phân bổ theo nhóm. Bản v2.1.x gọi là "grid visualize" vì chia context thành ô vuông trực quan trong IDE/Web.
   - Nhóm thường thấy: `System`, `CLAUDE.md/Memory`, `History`, `Tool calls`, `File reads`, `MCP`, `Images`.
3. **Không thay đổi gì:**
   - Lệnh không nén, không xóa, không gọi model tóm tắt. Chỉ đọc counters local + ước lượng tokenizer. Tốn ~0 token API.
4. **Ngưỡng cảnh báo:**
   - <50%: xanh, cứ làm tiếp.
   - 50-70%: vàng, nên lên kế hoạch compact (viết focus sẵn).
   - 70-85%: cam, compact tay ngay nếu còn làm tiếp.
   - >80-85%: đỏ, auto-compact có thể kích hoạt bất cứ lúc nào.

### Đọc bảng thế nào cho đúng?

- **History phình mà Tool results phình:** thường do paste log / `cat` file lớn. Fix bằng `/compact bỏ log`.
- **CLAUDE.md phình (>10K):** file luật quá dài, nên tách. Xem bài memory để tỉa.
- **MCP outputs phình:** 1 MCP server trả về quá nhiều (ví dụ GitHub MCP trả cả thread dài). Fix bằng cách hỏi hẹp hơn, tắt MCP không cần.
- **System + tools cố định:** không tối ưu được nhiều, đừng cố.

```text
Ví dụ đọc nhanh:
  History 48% + Tool 14% = 62% → rác từ log → compact bỏ log là về ~15%.
  CLAUDE.md 12% → luật quá dài → tỉa CLAUDE.md rồi /clear để nạp lại.
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Trả về gì | Thay đổi context? |
|---|---|---|
| `/context` | Báo cáo % + breakdown | Không |
| `/cost` | Tiền + tokens đã tiêu (billing) | Không |
| `/usage` | Breakdown theo skills/subagents/plugins/MCP + rate limits | Không |
| `/compact` | Summary thay history | Có (nén) |
| `/clear` | Session trắng | Có (xóa) |

> Nhớ: `/context` hỏi "RAM còn bao nhiêu?", `/cost` hỏi "tốn bao nhiêu tiền?", `/usage` hỏi "tiền đi vào việc gì (skill nào, MCP nào)?".

---

## Ví dụ thực tế

### Kịch bản 1: Quyết định compact hay clear trong 10 giây

```bash
# Bạn làm task payments được 1 tiếng, thấy trả lời chậm dần
/context
# → Output: 74%, History 55%, Tool results 15%
# → Kết luận: cùng task, rác là log → compact, không clear

/compact Bỏ log test, giữ quyết định Postgres+Drizzle và file src/payments/route.ts, bước tiếp là fix webhook mock.
```

### Kịch bản 2: Phát hiện CLAUDE.md quá béo

```bash
/context
# → Output: CLAUDE.md + memory chiếm 18K tokens (9%) — quá cao
# → Thông thường chỉ nên 2-5K

# Hành động: mở file luật ra tỉa
# (mở tay file CLAUDE.md, xóa ví dụ dài, chuyển sang docs/)
# Rồi nạp lại bằng clear (vì CLAUDE.md chỉ nạp lúc đầu phiên / sau clear)
```

### Kịch bản 3: Soi MCP nào ngốn RAM

```bash
# Sau khi bật 3 MCP (github, postgres, playwright), thấy chậm
/context
# → MCP outputs 22K (11%), chủ yếu từ github MCP

# Hành động: hỏi hẹp hơn, hoặc tắt MCP tạm thời
# Ví dụ: thay vì "liệt kê hết issues", hỏi "lấy 5 issues mới nhất repo X"
```

### Kịch bản 4: Checkpoint định kỳ trong ca trực dài

```bash
# Mỗi 30 phút gõ 2 lệnh này (tạo thói quen)
/todos
/context
# → todos 3/5 xong, context 58% → compact nhẹ rồi làm tiếp
/compact Giữ todos còn lại (4/5, 5/5) và file đang sửa src/billing/invoice.ts.
```

---

## Rủi ro & lưu ý

### Mất gì? Tốn gì?

- **Mất:** không mất gì. Read-only.
- **Tốn token:** ~0. Đếm local, không gọi model.
- **Hiệu năng:** hiện ngay (<1s) trên CLI/IDE.

### Version tối thiểu & provider

- Grid visualize hoàn thiện trên v2.0+, đẹp nhất trên v2.1.x (IDE/Web có grid màu, CLI có bảng text).
- Mọi plan đều có. Không cần plugin.
- Số liệu % phụ thuộc model đang dùng (window 200K vs 1M khác nhau). Đổi model thì % đổi theo — đừng so % giữa 2 model khác nhau.

### Cloud vs Local

| Môi trường | Hiển thị |
|---|---|
| CLI | Bảng text + thanh `████` |
| IDE (VS Code/JetBrains) | Grid ô vuông màu + tooltip từng nhóm |
| Web/Desktop | Card trực quan + gợi ý compact/clear |

> Lưu ý: con số là ước lượng tokenizer, có thể lệch ±2-3% so với billing thực tế (xem `/cost`). Dùng để ra quyết định, không dùng để đối soát hóa đơn.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/context` → `/compact` | Combo quốc dân: đo rồi nén |
| `/context` → `/clear` | Đo rồi thấy task xong → xóa trắng |
| `/context` → tỉa CLAUDE.md | Phát hiện luật béo → sửa file luật |
| `/context` → `/usage` | Context đầy + muốn biết ai ngốn (MCP/skill nào) |
| `/context` → `/cost` | Context đầy + muốn biết tốn bao nhiêu tiền rồi |
| `/todos` + `/context` | Cặp kiểm tra mỗi 30 phút trong task dài |

Thói quen đề xuất:

```bash
# Dán lên màn hình (quy ước cá nhân):
# "Mỗi 30 phút: /todos + /context. >60%: compact. Task xong: clear."
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/context` báo % khác với `/cost` | `/context` đo RAM hiện tại, `/cost` đo tổng billing tích lũy | Không phải lỗi; đọc cả 2 với ý nghĩa khác nhau |
| % vọt từ 30% lên 75% sau 1 paste | Paste file log/ảnh lớn | `/compact bỏ log` hoặc đừng paste cả file, chỉ paste đoạn cần (`read` theo dòng) |
| Grid không hiện breakdown MCP | Bản CLI cũ hoặc MCP chưa trả output nào | Update CLI; breakdown chỉ hiện nhóm có số liệu >0 |
| Gõ `/context` báo unknown | CLI < v2.0 hoặc gõ sai trong `--print` | Update `npm i -g @anthropic-ai/claude-code` |
| % thấp mà trả lời vẫn chậm | Chậm do mạng/model tải cao, không phải do context | Xem `/usage` (rate limits) + thử đổi model |
| CLAUDE.md chiếm quá nhiều % | File luật quá dài, nhồi ví dụ | Tỉa CLAUDE.md, chuyển ví dụ sang `docs/`, chỉ giữ luật cốt lõi. Xem bài memory |
| Muốn số chính xác từng token | Grid chỉ ước lượng | Muốn chính xác billing thì xem `/cost`; muốn chính xác từng request thì xem transcript `.jsonl` |
| Paste 1 ảnh screenshot mà % vọt 5% | Ảnh quy đổi ~1-2K tokens/ảnh | Nén ảnh trước khi paste, hoặc mô tả bằng chữ thay vì gửi ảnh |
| Breakdown hiện `Tool definitions` to bất thường | Bật quá nhiều MCP + tools cùng lúc | Tắt MCP không dùng trong session này |
| `/context` hiện 0% sau khi vừa hỏi dài | Vừa bị auto-compact / clear ngầm | Kiểm tra có dòng "Compacted" không; nếu có thì history đã bị nén |

### Mẹo đọc nâng cao: ước lượng số tokens còn lại

```bash
# Ví dụ window 200K, /context báo 68% → còn ~64K tokens
# Mỗi lượt tool-call trung bình ~2-4K → bạn còn ~15-25 lượt nữa
# Nếu task cần >30 lượt → compact ngay, đừng ráng
```

```bash
# Quy tắc 60/80:
# 60% → viết sẵn focus compact (đề phòng)
# 80% → auto-compact có thể nổ → compact tay trước để giữ focus đẹp
/context
```

---

## Tham khảo

- Lệnh liên quan:
  - [../compact/README.md](../../session-context/compact/README.md) — hành động sau khi thấy đầy
  - [../clear/README.md](../../session-context/clear/README.md) — khi task xong thì xóa thay vì nén
  - [../cost/README.md](../../session-context/cost/README.md) — từ % RAM sang tiền thật
  - [../usage/README.md](../../session-context/usage/README.md) — từ % chung sang ai ngốn (skill/MCP nào)
  - [../todos/README.md](../../session-context/todos/README.md) — cặp kiểm tra định kỳ
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../03-claude-md-memory-rules.md` — tỉa CLAUDE.md khi nó ngốn context
  - `../10-permissions-modes-availability.md` — tools definitions cũng chiếm context
  - `../08-mcp-ket-noi-cong-cu-ngoai.md` — MCP outputs ngốn RAM thế nào

> Mẹo 1 dòng: _gõ `/context` mỗi khi thấy model chậm lại — 10 giây nhìn bảng rẻ hơn 10 phút đoán mò._

> Nhớ thêm: _`/context` là chân ga, `/compact` là phanh nhẹ, `/clear` là phanh gấp — nhìn đồng hồ trước khi đạp._
>
> Đọc thêm về ngưỡng auto-compact (~80%) trong [../compact/README.md](../../session-context/compact/README.md).
