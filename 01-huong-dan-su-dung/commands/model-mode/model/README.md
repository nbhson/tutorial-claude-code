# /model — Đổi model AI giữa phiên, cân bằng tốc độ / sức mạnh / chi phí

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (không sửa file, chỉ đổi engine suy luận cho các turn tiếp theo; context cũ giữ nguyên)
>
> **Nói nôm na:** `/model` cho bạn đổi "bộ não" của Claude Code ngay giữa phiên: lúc cần nhanh-rẻ thì dùng Haiku 5.5/Sonnet, lúc cần suy luận sâu thì chuyển Opus 5.5 (mặc định của tài khoản từ ≥2.1.280). Fable 5.1 mạnh nhất nhưng **không bao giờ** là default — muốn dùng phải gọi tay. Context hội thoại, file đã đọc, todos giữ nguyên — chỉ model phục vụ turn tiếp theo thay đổi.

## Khi nào dùng

- Dùng /model khi cần đổi "bộ não" giữa phiên: nhanh-rẻ (Haiku 5.5/Sonnet) cho việc thường, suy luận sâu (Opus 5.5) cho bài khó.
- Dùng /model **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /model thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

Alias gõ được ngay bằng `/model <alias>` — coi như bảng phím bấm của dàn âm thanh: nhớ tên phím là đổi "bộ não" chỉ trong một lệnh, khỏi lục lại tên model đầy đủ:

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

> **Cách đọc bảng này:** mỗi dòng là một alias gõ được sau `/model`; cột "Trỏ tới" cho biết phím bấm đó đổi sang não nào, cột "Ghi chú" nhắc bản tối thiểu (≥2.1.xxx) và giá nếu có — cần giá/bản chi tiết thì đối chiếu dòng đó.

> Haiku 5.5 (`claude-haiku-5-5`, ≥2.1.293) đã thay Haiku 4.5 làm Haiku mặc định trên Anthropic API: 1M context, $0.10/$0.50 khi prompt ≤100K (trên 100K: $0.50/$2.50). Trên Bedrock/GCP/AWS vẫn là Haiku 4.5 (200K, $1/$5).
> Fable 5.1 nằm ngoài hạn mức thường: trên Pro bill bằng usage credits, trên Max tốn ~50% hạn tuần mỗi lượt dùng — nên chỉ gọi tay khi thật cần.
>
> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Claude nhận model mới và trả lời theo "não" mới; context, file đã đọc, todo giữ nguyên.
- Chỉ turn tiếp theo đổi model — hội thoại cũ không bị viết lại.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

> **Tóm gọn 1 câu:** `/model` là thay pin cho phiên làm việc giữa chừng: nhớ dai (context, todo, file đã đọc) giữ nguyên, chỉ nguồn suy nghĩ là khác — việc dở không phải kể lại từ đầu.

## Lỗi thường gặp

Bảng dưới là mấy trục trặc khi đổi "bộ não" giữa phiên — đối chiếu triệu chứng với cột đầu rồi làm theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/model opus` báo `not available` | Plan/provider chưa enable Opus | Dùng `/model sonnet` + `/effort high`; hoặc liên hệ admin Bedrock/Vertex |
| Đổi Opus mà trả lời vẫn "ngu" như cũ | Context nhiễm rác, model nào cũng sai | `/compact` hoặc `/clear` rồi hỏi lại |
| Picker `/model` trống / chỉ 1 model | Bản CLI cũ hoặc managed policy khóa | Update `npm i -g @anthropic-ai/claude-code`; kiểm tra `settings.json` có `allowedModels` không |

> **Cách đọc bảng này:** mỗi dòng là một tình huống "đổi model mà không được như ý"; cột "Vì sao" cho biết rào cản nằm ở gói, ở provider hay ở cấu hình, cột "Cách sửa" là lệnh/bước cụ thể.

## Tham khảo

- [../effort/README.md](../../model-mode/effort/README.md)
- [../fast/README.md](../../model-mode/fast/README.md)
- [../usage-credits/README.md](../../model-mode/usage-credits/README.md)
- [../plan/README.md](../../model-mode/plan/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /model sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
