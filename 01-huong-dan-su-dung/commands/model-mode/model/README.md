# /model — Đổi model AI giữa phiên, cân bằng tốc độ / sức mạnh / chi phí

> Loại Built-in · Nhóm Model & Mode · Nguy hiểm Không (không sửa file, chỉ đổi engine suy luận cho các turn tiếp theo; context cũ giữ nguyên)

`/model` cho bạn đổi "bộ não" của Claude Code ngay giữa phiên: lúc cần nhanh-rẻ thì dùng Haiku/Sonnet, lúc cần suy luận sâu thì chuyển Opus. Context hội thoại, file đã đọc, todos giữ nguyên — chỉ model phục vụ turn tiếp theo thay đổi.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/model` | _(không có)_ | Mở picker chọn model tương tác |
| `/model <tên>` | `sonnet`, `opus`, `haiku`, `opusplan`, `sonnet[1m]`... | Đổi thẳng không qua picker |
| `/model default` | `default` | Về model mặc định của settings / plan |
| `/model` trong CLI flags | `--model <tên>`, `--fallback-model` | Đặt model khi khởi chạy `claude` |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở picker tương tác
/model
```

```bash
# Dạng 2: đổi thẳng sang Opus khi gặp bài khó
/model opus
```

```bash
# Dạng 3: về Sonnet cho tác vụ thường ngày (nhanh, rẻ)
/model sonnet
```

```bash
# Dạng 4: dùng Haiku cho việc vặt (đọc log, rename biến)
/model haiku
```

```bash
# Dạng 5: CLI khởi chạy với model chỉ định
claude --model sonnet "Giải thích hàm main() trong main.py"
```

```bash
# Dạng 6: đặt fallback khi model chính quá tải
claude --model opus --fallback-model sonnet
```

```bash
# Dạng 7: kiểm tra model hiện tại (hỏi trực tiếp)
/model
# → picker hiển thị dấu tick ở model đang dùng
```

---

## Cách nó hoạt động

### Cơ chế sâu: /model đổi gì trong session?

1. **Session state tách 3 lớp:**
   - `conversation context` (lịch sử chat, file đã đọc, todos) — giữ nguyên 100%.
   - `model binding` (engine nào sẽ trả lời turn tiếp theo) — đây là thứ duy nhất `/model` đổi.
   - `mode binding` (plan/acceptEdits/auto/bypass — do Shift+Tab quản lý) — không bị `/model` đụng tới.
2. **Hiệu lực từ turn tiếp theo:**
   - Prompt bạn gõ sau `/model opus` sẽ được route tới Opus.
   - Các câu trả lời trước đó không bị viết lại, không tốn token re-run.
3. **System prompt được rebuild nhẹ:**
   - Mỗi model có system prompt + tool-use format hơi khác (Opus suy luận dài hơn, Haiku ngắn gọn hơn).
   - Claude Code tự inject lại phần này, bạn không cần `/clear` hay restart.
4. **Context window khác nhau theo model:**
   - Sonnet/Opus bản 1M context (`sonnet[1m]`) chứa được nhiều file hơn Haiku.
   - Đổi từ Haiku → Opus giữa chừng: context cũ vẫn vừa (vì Opus window lớn hơn).
   - Đổi từ Opus 1M → Haiku khi context đã 500K: có thể chạm trần → model báo truncated, lúc đó nên `/compact` hoặc `/clear`.
5. **OpusPlan là gì?**
   - Một số bản có `opusplan`: dùng Opus cho bước lập plan, Sonnet cho bước thực thi — tiết kiệm mà vẫn khôn.
   - Nếu picker không thấy `opusplan`, bản của bạn chưa có, cứ dùng `opus` thuần.
6. **Model availability theo plan/provider:**
   - Pro/Max/Team: đủ Sonnet + Opus + Haiku.
   - API pay-as-you-go (`ANTHROPIC_API_KEY`): tùy quota, Opus đắt gấp ~5x Sonnet.
   - Bedrock/Vertex: danh sách model bị giới hạn bởi admin cloud — picker chỉ hiện những gì được phép.

### Sơ đồ trạng thái

```text
[Session: context 40% + model=sonnet]
        --/model opus-->
[Session: context 40% (giữ nguyên) + model=opus]
        --hỏi tiếp-->
[Trả lời bởi Opus, sâu hơn, đắt hơn]
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Đổi gì? | Giữ context? | Dùng khi nào? |
|---|---|---|---|
| `/model` | Engine suy luận | Có | Bài khó cần não to hơn |
| `/effort` | Mức suy luận sâu (reasoning budget) | Có | Muốn model nghĩ kỹ hơn mà không đổi model |
| `/fast` | Shortcut bật chế độ nhanh (thường = sonnet + effort thấp) | Có | Cần trả lời gấp, việc dễ |
| `--model` (CLI flag) | Model lúc khởi chạy | N/A (phiên mới) | Script, automation |
| Shift+Tab | Permission mode (ai được sửa file) | Có | Đổi mức tự động hóa, không đổi não |

> Quy tắc ngón tay cái:
>
> - **Bài khó, cần thông minh hơn → `/model opus`.**
> - **Việc dễ, cần nhanh-rẻ → `/model haiku` hoặc `/model sonnet`.**
> - **Muốn cùng model nhưng nghĩ kỹ hơn → `/effort high` thay vì đổi model.**

### Khi nào đổi model KHÔNG đủ?

- Context đã nhiễm rác 80%: đổi Opus cũng không cứu — phải `/compact` hoặc `/clear` trước.
- Luật dự án sai (CLAUDE.md sai): Opus cũng làm sai theo luật sai — sửa `CLAUDE.md` trước.
- Thiếu quyền tools (plan mode khóa ghi file): đổi model không mở khóa — phải Shift+Tab hoặc `/permissions`.

---

## Ví dụ thực tế

### Kịch bản 1: Sáng code thường, chiều gặp bug race condition khó

Bạn code CRUD bằng Sonnet cả buổi (nhanh, rẻ). Đến chiều gặp race condition trong worker pool, Sonnet đoán 3 lần sai.

```bash
# Bước 1: đang dùng sonnet, context 30%
/model opus

# Bước 2: giao bài khó, yêu cầu suy luận sâu
Hãy phân tích race condition trong src/queue/worker.ts.
Vẽ timeline 2 workers cùng dequeue 1 job, chỉ ra dòng nào thiếu lock,
rồi đề xuất fix bằng mutex hoặc atomic compare-and-swap.
```

> Kết quả: Opus phân tích đúng dòng 42 thiếu lock, đề xuất fix kèm test. Xong việc → `/model sonnet` để về chế độ rẻ.

### Kịch bản 2: Tiết kiệm quota cuối tháng — Haiku cho việc vặt

Cuối tháng, quota Opus gần hết. Bạn còn loạt việc lặt vặt: rename biến, format, viết docstring.

```bash
# Bước 1: chuyển Haiku
/model haiku

# Bước 2: giao việc vặt hàng loạt
Rename biến `x` thành `userId` trong src/auth/*.ts, giữ nguyên logic.
Sau đó viết docstring cho mỗi hàm public.
```

```bash
# Bước 3: xong việc vặt, cần review quan trọng → lên lại Sonnet
/model sonnet
Hãy review diff vừa rename xem có sót chỗ nào không.
```

### Kịch bản 3: OpusPlan — plan khôn, chạy rẻ (nếu bản của bạn có)

```bash
# Bước 1: bật opusplan
/model opusplan

# Bước 2: giao task kiến trúc
Thiết kế lại module payments từ Stripe sang multi-provider (Stripe + MoMo).
Lập plan chi tiết trước, khi tôi duyệt mới code.
```

> Kết quả: bước plan dùng Opus (khôn), bước code dùng Sonnet (nhanh). Tiết kiệm ~40% so với Opus thuần.

### Kịch bản 4: Kết hợp /model + /effort cho bài toán siêu khó

```bash
# Bài toán NP-khó: tối ưu query + refactor kiến trúc
/model opus
/effort max

Hãy phân tích toàn bộ query N+1 trong src/api/, đề xuất schema mới,
đánh đổi giữa denormalization và join cost, kèm migration plan zero-downtime.
```

---

## Rủi ro & lưu ý

### Tốn token / tiền?

| Model (5.5) | Input / Output (per 1M tokens) | Tốc độ | Khi nào dùng |
|---|---|---|---|
| `haiku` | $1 / $5 | Nhanh nhất | Việc vặt, đọc log, rename, format |
| `sonnet` (5.5) | $2 / $10 | Nhanh | Mặc định hàng ngày, code CRUD, review thường |
| `opus` (5.5) | $4 / $20 | Chậm hơn | Kiến trúc, bug khó, bảo mật, thuật toán |
| `fable` | $10 / $50 | Chậm nhất, mạnh nhất | Agent xuất sắc nhất, task cực khó — không bao giờ là default |

- Alias `opusplan` = plan bằng Opus, thực thi bằng Sonnet (tiết kiệm ~40% so với Opus thuần).
- `fable` không bao giờ là default — chỉ dùng khi gọi tường minh (`/model fable` hoặc `--model fable`).
- IDs đầy đủ (dùng trong script/CI): `claude-opus-5-5`, `claude-sonnet-5-5`, `claude-fable-...`, `claude-haiku-...`
  — picker `/model` luôn là nguồn sự thật, đừng hardcode ID cũ.

- `/model` tự nó tốn 0 token. Nhưng Opus trả lời dài hơn → tốn output tokens hơn.
- Ví dụ số học: 1 task Opus ~$0.50, Sonnet ~$0.10, Haiku ~$0.02. Dùng sai chỗ = đốt tiền.
- Mẹo: mặc định Sonnet, chỉ lên Opus khi stuck > 2 lần.

### Destructive?

- Không. `/model` không sửa/xóa file, không đổi git, không đổi permissions.
- Rủi ro duy nhất: Opus "sáng tạo" hơn → nếu đang ở `bypassPermissions`, Opus có thể refactor quá tay. Hãy ở `acceptEdits` khi thử model mới.

### Version floor & provider

- Có mặt mọi bản v2.1.x (CLI, IDE, Web, Desktop).
- Tên model khả dụng thay đổi theo thời gian — picker luôn là nguồn sự thật. Đừng hardcode tên model cũ trong script.
- Bedrock/Vertex: nếu admin chưa enable Opus, `/model opus` báo `not available`. Liên hệ admin hoặc dùng Sonnet + `/effort high`.
- API key cá nhân hết quota Opus → tự fallback về Sonnet (nếu đã đặt `--fallback-model`).

### Cloud vs Local

| Môi trường | Hành vi |
|---|---|
| CLI | Picker inline, đổi ngay trong session |
| IDE | Dropdown trên thanh chat + lệnh `/model` đồng bộ nhau |
| Web/Desktop | Dropdown model trên UI, tương đương `/model` |

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/model opus` → `/effort high` | Bài siêu khó, cần cả não to + nghĩ lâu | `/model opus` rồi `/effort high` |
| `/model haiku` → việc vặt | Tiết kiệm quota | `/model haiku` + rename/format |
| `/model` + `/fast` | Cần nhanh gấp | `/fast` (tự về sonnet nhanh) |
| `/model` + `/compact` | Đổi model khi context đầy | `/compact` trước rồi `/model opus` |
| `/model` + Shift+Tab | Vừa đổi não vừa đổi quyền | `/model opus` + Shift+Tab về `acceptEdits` |
| `/model` + `/verify` | Code bằng Sonnet, verify bằng Opus | Code xong → `/model opus` → `/verify` |

Workflow chuẩn "leo thang":

```bash
# 1. Mặc định Sonnet cho mọi việc
/model sonnet

# 2. Stuck 2 lần → lên Opus
/model opus

# 3. Vẫn stuck → thêm effort
/effort high

# 4. Xong bài khó → về lại Sonnet cho rẻ
/model sonnet
/effort medium
```

Workflow "tiết kiệm cuối tháng":

```bash
# Việc vặt → Haiku
/model haiku
# ... làm 10 task vặt ...

# Review quan trọng → Sonnet
/model sonnet
/review
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/model opus` báo `not available` | Plan/provider chưa enable Opus | Dùng `/model sonnet` + `/effort high`; hoặc liên hệ admin Bedrock/Vertex |
| Đổi Opus mà trả lời vẫn "ngu" như cũ | Context nhiễm rác, model nào cũng sai | `/compact` hoặc `/clear` rồi hỏi lại |
| Picker `/model` trống / chỉ 1 model | Bản CLI cũ hoặc managed policy khóa | Update `npm i -g @anthropic-ai/claude-code`; kiểm tra `settings.json` có `allowedModels` không |
| Đổi model giữa chừng bị mất context | Hiểu nhầm — context vẫn còn, chỉ là model mới tóm tắt khác | Không cần fix; nếu context quá đầy sau đổi (Haiku window nhỏ) thì `/compact` |
| Script CI hardcode `--model opus-20240101` báo lỗi | Tên model cũ đã deprecated | Dùng alias mới `opus` / `sonnet` / `haiku`, không ghim version cụ thể |
| Opus refactor quá tay, sửa lung tung | Đang ở `bypassPermissions` + model mạnh | Shift+Tab về `acceptEdits`, review diff bằng `/diff` |
| `/model` trong `--print` không có tác dụng | Non-interactive mỗi lần gọi là session mới | Dùng flag `claude --model opus --print "..."` thay vì `/model` |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../effort/README.md](../../model-mode/effort/README.md) — đổi độ sâu suy luận mà không đổi model
  - [../fast/README.md](../../model-mode/fast/README.md) — shortcut về chế độ nhanh
  - [../extra-usage/README.md](../../model-mode/extra-usage/README.md) — khi hết quota phải mua thêm để dùng Opus
  - [../plan/README.md](../../model-mode/plan/README.md) — plan mode + Opus là combo kiến trúc
  - [../permissions/README.md](../../model-mode/permissions/README.md) — đổi model không đổi quyền tools
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ slash commands v2.1.x
  - `../06-subagents-agent-teams-parallel.md` — subagent có thể dùng model khác agent chính
  - `../10-permissions-modes-availability.md` — Shift+Tab modes vs model
  - `../11-git-worktrees-checkpoints.md` — đổi model không ảnh hưởng git/worktree
  - `../12-agent-sdk-ci-cd-automation.md` — đặt model trong CI bằng `--model`

> Mẹo 1 dòng: _mặc định Sonnet, stuck 2 lần mới lên Opus, xong việc nhớ về Sonnet._
