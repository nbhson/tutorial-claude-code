# /effort — Chỉnh độ sâu suy luận (reasoning budget) mà không cần đổi model

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (không sửa file, chỉ tăng/giảm tokens suy luận; effort cao tốn tiền và chậm hơn)

`/effort` là núm vặn "nghĩ kỹ hay nghĩ nhanh": `low` trả lời chớp nhoáng cho việc dễ, `max` đào sâu nhiều vòng cho bài toán kiến trúc. Cùng một model Sonnet, effort khác nhau cho chất lượng khác nhau — rẻ hơn nhiều so với cứ stuck là lên Opus.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/effort` | _(không có)_ | Xem effort hiện tại + picker |
| `/effort low` | `low` | Nhanh nhất, ít suy luận — việc vặt |
| `/effort medium` | `medium` | Mặc định cân bằng |
| `/effort high` | `high` | Suy luận sâu — bug khó, review |
| `/effort xhigh` | `xhigh` | Rất sâu — kiến trúc, bảo mật |
| `/effort max` | `max` | Tối đa (session-only, ≥2.1.205) — bài siêu khó |
| `/effort auto` | `auto` | Model tự chọn effort theo độ khó prompt |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem effort hiện tại
/effort
```

```bash
# Dạng 2: việc vặt — nghĩ nhanh cho rẻ
/effort low
Rename biến x thành userId trong src/auth/*.ts
```

```bash
# Dạng 3: mặc định hàng ngày
/effort medium
```

```bash
# Dạng 4: bug khó — nghĩ kỹ
/effort high
Hãy phân tích race condition trong src/queue/worker.ts
```

```bash
# Dạng 5: kiến trúc / audit bảo mật
/effort xhigh
Audit toàn bộ flow auth, liệt kê mọi vector tấn công XSS/CSRF/JWT.
```

```bash
# Dạng 6: bài siêu khó, session-only (mất khi restart)
/effort max
Thiết kế lại schema DB zero-downtime cho 10M rows.
```

```bash
# Dạng 7: để model tự quyết
/effort auto
```

```bash
# Dạng 8: ultracode — alias cộng đồng của max (tùy bản, session-only)
/effort max
# (một số bản hiển thị là ultracode/ultrathink trong picker)
```

---

## Cách nó hoạt động

### Cơ chế sâu: /effort đổi gì trong session?

1. **Reasoning budget, không phải model:**
   - Mỗi turn, model được cấp N tokens "nghĩ thầm" (extended thinking) trước khi trả lời.
   - `low` ≈ vài trăm tokens nghĩ → trả lời ngay, ít vòng tool-call.
   - `high/xhigh/max` ≈ hàng nghìn–chục nghìn tokens nghĩ → nhiều vòng đọc file, thử giả thuyết, tự phản biện.
2. **Số vòng agentic loop tăng theo effort:**
   - `low`: 1–3 vòng tool calls (đọc 1-2 file rồi kết luận).
   - `medium`: 5–10 vòng (đọc + search + edit thử).
   - `high+`: 15–40+ vòng (đọc chéo nhiều file, chạy test, so sánh phương án, tự review).
3. **max/ultracode là session-only (≥2.1.205):**
   - Chỉ hiệu lực trong session hiện tại, restart/reconnect là về `medium`.
   - Lý do: tránh đốt tiền âm thầm nếu quên tắt. Thiết kế an toàn có chủ ý.
   - Nếu cần persistent → đặt trong `settings.json` (`"effort": "high"`), nhưng `max` vẫn bị ép về `high` khi load lại (tùy bản).
4. **`auto` hoạt động ra sao?**
   - Một classifier nhẹ đọc prompt của bạn: "rename biến" → low; "thiết kế kiến trúc" → high.
   - Không hoàn hảo — prompt mơ hồ ("xem giúp code này") thường bị đoán medium. Muốn chắc thì đặt tay.
5. **Tương tác với /model:**
   - `sonnet + high` ≈ `opus + medium` về chất lượng, nhưng rẻ hơn ~50%.
   - `opus + max` = mạnh nhất, đắt nhất — chỉ dùng cho quyết định kiến trúc triệu đô.
   - `haiku + max` vẫn không bằng `sonnet + medium` cho bài suy luận — đừng kỳ vọng phép màu.
6. **Effort không mở khóa tools:**
   - Đang ở plan mode (khóa ghi file) thì effort max cũng không được ghi. Phải Shift+Tab đổi mode.

### Sơ đồ trạng thái

```text
Prompt "fix bug X"
  |--/effort low--> [nghĩ 500 tok] --> trả lời 1 phương án, nhanh, có thể sai
  |--/effort medium--> [nghĩ 2K tok] --> 2-3 phương án, đọc 5 file
  |--/effort high--> [nghĩ 8K tok] --> so sánh trade-off, chạy test, tự review
  |--/effort max--> [nghĩ 20K+ tok] --> đào sâu edge cases, attack vectors, migration plan
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Đổi gì? | Tốn tiền? | Dùng khi nào? |
|---|---|---|---|
| `/effort` | Độ sâu suy luận của cùng model | Có (tăng dần low→max) | Muốn khôn hơn mà không đổi model |
| `/model` | Engine (haiku/sonnet/opus) | Có (haiku→opus tăng mạnh) | Cần não khác hẳn |
| `/fast` | Shortcut về nhanh (thường = low + sonnet) | Giảm | Cần gấp, việc dễ |
| `/goal` | Điều kiện dừng (evaluator check) | Gián tiếp (loop nhiều vòng) | Task dài cần tiêu chí xong rõ ràng |

> Quy tắc ngón tay cái:
>
> - **Việc 1 phút → `low`. Mặc định → `medium`. Stuck → `high`. Kiến trúc/bảo mật → `xhigh`. Cược lớn → `max`.**
> - **Luôn thử tăng effort trước khi đổi model — rẻ hơn.**

### Khi nào tăng effort cũng vô ích?

- Context nhiễm rác: effort cao chỉ "nghĩ kỹ về rác". `/compact`/`/clear` trước.
- Thiếu context file: model không được đọc file cần → effort max cũng đoán mò. Hãy `@file` hoặc bảo nó đọc.
- Prompt mơ hồ: "làm cho đẹp hơn" — effort max sẽ over-engineer. Viết rõ tiêu chí xong trước (hoặc dùng `/goal`).

---

## Ví dụ thực tế

### Kịch bản 1: Leo thang effort khi debug (không vội lên Opus)

Bạn gặp bug pagination trả sai tổng số trang. Sonnet medium đoán sai 1 lần.

```bash
# Bước 1: đang medium, đoán sai → tăng high thay vì đổi Opus ngay
/effort high

# Bước 2: giao lại với yêu cầu tự kiểm chứng
Bug vẫn còn: GET /api/users?page=3&limit=20 trả total=95 nhưng thực tế 100 rows.
Hãy đọc src/api/users.ts + query COUNT, tự viết script reproduce,
rồi fix. Không đoán mò, phải có bằng chứng chạy được.
```

> Kết quả: high đọc thêm migration file, phát hiện COUNT thiếu WHERE soft-delete. Fix đúng, tốn ~$0.15 thay vì ~$0.50 nếu lên Opus ngay.

### Kịch bản 2: low cho loạt việc vặt cuối sprint

```bash
# 20 file thiếu docstring, việc cơ học
/effort low
Viết JSDoc 1 dòng cho mọi hàm public trong src/utils/*.ts. Không refactor, không đổi logic.
```

```bash
# Xong việc vặt → về medium cho việc thường
/effort medium
```

> Kết quả: mỗi file ~2 giây, rẻ gấp 5x so với để high. Chất lượng vẫn ổn vì việc dễ.

### Kịch bản 3: xhigh/max cho audit bảo mật trước release

```bash
# Ngày mai release, cần audit auth
/effort xhigh

Audit flow login trong src/auth/: liệt kê mọi vector
(XSS, CSRF, JWT expiry, refresh rotation, rate-limit, timing attack).
Với mỗi vector: mức độ (critical/high/low) + file:dòng + cách fix cụ thể.
```

```bash
# Nếu là hệ thanh toán tiền thật → max
/effort max
Audit thêm phần payments/ với cùng format, ưu tiên double-spend và idempotency.
```

### Kịch bản 4: auto cho người mới chưa quen chỉnh tay

```bash
# Người mới, không muốn nhớ low/high khi nào
/effort auto

# Rồi cứ giao việc tự nhiên — model tự leo/giảm
Rename hàm này...
# → auto chọn low
Thiết kế hệ thống notification chịu 1M msg/ngày...
# → auto chọn high
```

---

## Rủi ro & lưu ý

### Tốn token?

| Effort | Tốc độ | Chi phí tương đối | Vòng tool-call |
|---|---|---|---|
| `low` | ~5–10s | 1x | 1–3 |
| `medium` | ~15–30s | 2–3x | 5–10 |
| `high` | ~1–3 phút | 5–8x | 15–25 |
| `xhigh` | ~3–8 phút | 10–15x | 25–40 |
| `max` | ~5–15 phút | 20x+ | 40+ |

- Quên tắt `max` sau bài khó = mọi câu "ok" sau cũng đốt 20x. **Xong việc nhớ về `medium`.**
- `max` session-only là phao cứu sinh — nhưng đừng ỷ lại, hãy tự hạ sau mỗi task lớn.
- Ví dụ số học: 10 prompts `low` ~$0.05; 10 prompts `max` ~$1.00–2.00.

### Destructive?

- Không trực tiếp. Nhưng effort cao + `bypassPermissions` = combo nguy hiểm: model tự tin refactor 20 file mà không hỏi.
- Quy tắc: `high+` luôn đi với `acceptEdits` (Shift+Tab) để còn checkpoint review.

### Version floor

- `low|medium|high`: mọi bản v2.1.x.
- `xhigh`: bản giữa v2.1.x (nếu picker không thấy, dùng `high`).
- `max` / `ultracode` / `auto`: **≥2.1.205**, session-only. Bản cũ hơn gõ `/effort max` báo `unknown effort level`.
- Kiểm tra bản: `claude --version`.

### Provider thiếu gì?

- API key rẻ / Bedrock quota thấp: `max` có thể bị throttle (429) hoặc ép về `high` âm thầm. Thấy trả lời ngắn bất thường ở `max` → là bị ép.
- Web/Desktop bản free: `max` có thể bị ẩn khỏi picker.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/effort high` + `/model sonnet` | Khôn hơn mà vẫn rẻ | `/model sonnet` + `/effort high` |
| `/effort max` + `/model opus` | Mạnh nhất cho cược lớn | `/model opus` + `/effort max` |
| `/effort low` + `/fast` | Việc gấp, việc dễ | `/effort low` rồi làm |
| `/effort` + `/goal` | Nghĩ sâu + biết khi nào dừng | `/goal "..."` + `/effort high` |
| `/effort` + `/verify` | Nghĩ kỹ rồi kiểm chứng thật | Code ở `high` → `/verify` |
| `/effort` + Shift+Tab | Effort cao phải có phanh | `high` + `acceptEdits` |

Workflow chuẩn "leo thang tiết kiệm":

```bash
# 1. Mặc định
/effort medium

# 2. Stuck lần 1 → high (chưa đổi model)
/effort high

# 3. Stuck lần 2 → mới lên Opus
/model opus

# 4. Xong → hạ cả hai
/model sonnet
/effort medium
```

Workflow "audit trước release":

```bash
/effort xhigh
# ... audit auth ...
/effort max
# ... audit payments (tiền thật) ...
/effort medium
# → nhớ hạ sau release
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/effort max` báo `unknown effort level` | Bản < 2.1.205 | Update `npm i -g @anthropic-ai/claude-code`; tạm dùng `/effort high` |
| Đặt `max` rồi restart mất | `max` session-only by design | Đặt lại sau mỗi session; hoặc `settings.json` để `high` persistent |
| `high` mà trả lời vẫn cạn | Context nhiễm / prompt mơ hồ | `/compact` + viết rõ tiêu chí; thử `/goal` để ép evaluator |
| `low` làm sai việc hơi khó | low chỉ hợp việc cơ học | Lên `medium`/`high` cho task cần suy luận |
| `max` chạy 10 phút chưa xong | Bình thường — đang nhiều vòng | Đợi; hoặc Ctrl+C ngắt, chia task nhỏ hơn, dùng `/goal` giới hạn |
| Thấy bill tăng vọt sau khi thử `max` | Quên hạ về medium | `/effort medium` ngay; kiểm tra usage bằng `/extra-usage` |
| `auto` lúc khôn lúc ngu | Classifier đoán sai prompt mơ hồ | Đặt tay `low/medium/high` cho task quan trọng |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../model/README.md](../../model-mode/model/README.md) — đổi engine khi tăng effort không đủ
  - [../fast/README.md](../../model-mode/fast/README.md) — shortcut về low nhanh
  - [../goal/README.md](../../model-mode/goal/README.md) — đặt điều kiện dừng cho loop effort cao
  - [../extra-usage/README.md](../../model-mode/extra-usage/README.md) — xem bill khi dùng high/max nhiều
  - [../verify/README.md](../../code-repo/verify/README.md) — kiểm chứng kết quả effort cao làm ra
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ slash commands
  - `../06-subagents-agent-teams-parallel.md` — subagent có effort riêng
  - `../10-permissions-modes-availability.md` — effort cao + bypass = nguy hiểm
  - `../11-git-worktrees-checkpoints.md` — checkpoint trước khi cho max refactor
  - `../12-agent-sdk-ci-cd-automation.md` — đặt effort trong CI

> Mẹo 1 dòng: _thử tăng effort trước khi đổi model — `sonnet + high` rẻ hơn `opus + medium` mà khôn tương đương._
