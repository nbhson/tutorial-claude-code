# /model — Đổi model AI giữa phiên, cân bằng tốc độ / sức mạnh / chi phí

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (không sửa file, chỉ đổi engine suy luận cho các turn tiếp theo; context cũ giữ nguyên)
>
> **Nói nôm na:** `/model` cho bạn đổi "bộ não" của Claude Code ngay giữa phiên: lúc cần nhanh-rẻ thì dùng Haiku 5.5/Sonnet, lúc cần suy luận sâu thì chuyển Opus 5.5 (mặc định của tài khoản từ ≥2.1.280). Fable 5.1 mạnh nhất nhưng **không bao giờ** là default — muốn dùng phải gọi tay. Context hội thoại, file đã đọc, todos giữ nguyên — chỉ model phục vụ turn tiếp theo thay đổi.

## Khi nào dùng

- Dùng /model khi cần đổi "bộ não" giữa phiên: nhanh-rẻ (Haiku 5.5/Sonnet) cho việc thường, suy luận sâu (Opus 5.5) cho bài khó.
- Dùng /model **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /model thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
/model
/model <tên>
/model default
```

Alias gõ được ngay bằng `/model <alias>`:

| Alias | Trỏ tới | Ghi chú |
|---|---|---|
| `default` | model mặc định theo tài khoản/provider | Opus 5.5 từ ≥2.1.280 (Pro/Max/Team/Enterprise/API/Bedrock/GCP); Microsoft Foundry: Sonnet 4.5 |
| `best` | Fable 5.1 nếu có, không thì `opus` | Fable không bao giờ tự thành default |
| `fable` | Fable 5.1 | ≥2.1.257; $10/$50, cache $0.25 |
| `opus` | Opus 5.5 | ≥2.1.280; $4/$20, cache $0.20 |
| `sonnet` | Sonnet 5.5 | ≥2.1.284; $2/$10, cache $0.10 |
| `haiku` | Haiku 5.5 trên Anthropic API; Haiku 4.5 trên Bedrock/GCP/AWS | Haiku 5.5 ≥2.1.293; 1M, $0.10/$0.50, cache $0.01 |
| `opusplan` | plan bằng Opus, execute bằng Sonnet | |
| `opus[1m]` | Opus 5.5 mở cửa sổ context 1M | |
| `sonnet[1m]` | Sonnet 5.5 mở cửa sổ context 1M | |

> Haiku 5.5 (`claude-haiku-5-5`, ≥2.1.293) đã thay Haiku 4.5 làm Haiku mặc định trên Anthropic API: 1M context, $0.10/$0.50 khi prompt ≤100K (trên 100K: $0.50/$2.50). Trên Bedrock/GCP/AWS vẫn là Haiku 4.5 (200K, $1/$5).
> Fable 5.1 nằm ngoài hạn mức thường: trên Pro bill bằng usage credits, trên Max tốn ~50% hạn tuần mỗi lượt dùng — nên chỉ gọi tay khi thật cần.
>
> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: đang dùng sonnet, context 30%
/model opus

# Bước 2: giao bài khó, yêu cầu suy luận sâu
Hãy phân tích race condition trong src/queue/worker.ts.
Vẽ timeline 2 workers cùng dequeue 1 job, chỉ ra dòng nào thiếu lock,
rồi đề xuất fix bằng mutex hoặc atomic compare-and-swap.
```

Kết quả mong đợi:

- Claude nhận model mới và trả lời theo "não" mới; context, file đã đọc, todo giữ nguyên.
- Chỉ turn tiếp theo đổi model — hội thoại cũ không bị viết lại.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/model opus` báo `not available` | Plan/provider chưa enable Opus | Dùng `/model sonnet` + `/effort high`; hoặc liên hệ admin Bedrock/Vertex |
| Đổi Opus mà trả lời vẫn "ngu" như cũ | Context nhiễm rác, model nào cũng sai | `/compact` hoặc `/clear` rồi hỏi lại |
| Picker `/model` trống / chỉ 1 model | Bản CLI cũ hoặc managed policy khóa | Update `npm i -g @anthropic-ai/claude-code`; kiểm tra `settings.json` có `allowedModels` không |

## Tham khảo

- [../effort/README.md](../../model-mode/effort/README.md)
- [../fast/README.md](../../model-mode/fast/README.md)
- [../extra-usage/README.md](../../model-mode/extra-usage/README.md)
- [../plan/README.md](../../model-mode/plan/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /model sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
