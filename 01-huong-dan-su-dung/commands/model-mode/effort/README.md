# /effort — Chỉnh độ sâu suy luận (reasoning budget) mà không cần đổi model

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (không sửa file, chỉ tăng/giảm tokens suy luận; effort cao tốn tiền và chậm hơn)
>
> **Nói nôm na:** `/effort` là núm vặn "nghĩ kỹ hay nghĩ nhanh": `low` trả lời chớp nhoáng cho việc dễ, `max` đào sâu nhiều vòng cho bài toán kiến trúc. Cùng một model, effort khác nhau cho chất lượng khác nhau — rẻ hơn nhiều so với cứ stuck là lên Opus.

## Khi nào dùng

- Dùng /effort khi cùng một model cần nghĩ sâu hơn (bug lạ, thiết kế hệ thống) hoặc trả lời nhanh hơn (việc vặt) — vặn reasoning budget thay vì đổi model.
- Dùng /effort **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /effort thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Cùng model nhưng trả lời sâu hơn (`high`/`max`) hoặc nhanh hơn (`low`) — không đổi model.
- Effort cao tốn token suy luận và chậm hơn; cân nhắc trước khi để `max` cho cả phiên.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

> **Tóm gọn 1 câu:** `/effort` là núm vặn gas của bộ não: việc dễ để `low` chạy lướt, bài khó vặn `high`/`max` để đào sâu — và nhớ mỗi vòng vặn đều đổ xăng (token suy luận).

## Lỗi thường gặp

Bảng dưới là ba cảnh báo hay thấy trên bảng đồng hồ khi vặn núm effort — so triệu chứng của bạn với cột đầu rồi sửa theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/effort max` báo `unknown effort level` | Bản < 2.1.205 | Update `npm i -g @anthropic-ai/claude-code`; tạm dùng `/effort high` |
| Đặt `max` rồi restart mất | `max` session-only by design | Đặt lại sau mỗi session; hoặc `settings.json` để `high` persistent |
| `high` mà trả lời vẫn cạn | Context nhiễm / prompt mơ hồ | `/compact` + viết rõ tiêu chí; thử `/goal` để ép evaluator |

> **Cách đọc bảng này:** mỗi dòng là một hiện tượng sau khi vặn effort; cột "Vì sao" cho biết lỗi nằm ở bản CLI, ở cơ chế session hay ở chất lượng prompt, cột "Cách sửa" là lệnh chạy được ngay.

## Tham khảo

- [../model/README.md](../../model-mode/model/README.md)
- [../fast/README.md](../../model-mode/fast/README.md)
- [../goal/README.md](../../model-mode/goal/README.md)
- [../usage-credits/README.md](../../model-mode/usage-credits/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /effort sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
