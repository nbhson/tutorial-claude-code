# /model — Đổi model AI giữa phiên, cân bằng tốc độ / sức mạnh / chi phí

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (không sửa file, chỉ đổi engine suy luận cho các turn tiếp theo; context cũ giữ nguyên)
>
> **Nói nôm na:** `/model` cho bạn đổi "bộ não" của Claude Code ngay giữa phiên: lúc cần nhanh-rẻ thì dùng Haiku/Sonnet, lúc cần suy luận sâu thì chuyển Opus 5.5 (mặc định ở hầu hết gói từ ≥2.1.280). Context hội thoại, file đã đọc, todos giữ nguyên — chỉ model phục vụ turn tiếp theo thay đổi.

## Khi nào dùng

- Dùng /model khi cần đổi "bộ não" giữa phiên: nhanh-rẻ (Haiku/Sonnet) cho việc thường, suy luận sâu (Opus 5.5) cho bài khó.
- Dùng /model **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /model thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/model`
`/model <tên>`
`/model default`
```

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

- Claude trả đúng việc của /model (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

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
