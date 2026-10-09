# /effort — Chỉnh độ sâu suy luận (reasoning budget) mà không cần đổi model

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (không sửa file, chỉ tăng/giảm tokens suy luận; effort cao tốn tiền và chậm hơn)
>
> **Nói nôm na:** `/effort` là núm vặn "nghĩ kỹ hay nghĩ nhanh": `low` trả lời chớp nhoáng cho việc dễ, `max` đào sâu nhiều vòng cho bài toán kiến trúc. Cùng một model, effort khác nhau cho chất lượng khác nhau — rẻ hơn nhiều so với cứ stuck là lên Opus.

## Khi nào dùng

- Dùng /effort khi cùng một model cần nghĩ sâu hơn (bug lạ, thiết kế hệ thống) hoặc trả lời nhanh hơn (việc vặt) — vặn reasoning budget thay vì đổi model.
- Dùng /effort **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /effort thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/effort`
`/effort low`
`/effort medium`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: đang medium, đoán sai → tăng high thay vì đổi Opus ngay
/effort high

# Bước 2: giao lại với yêu cầu tự kiểm chứng
Bug vẫn còn: GET /api/users?page=3&limit=20 trả total=95 nhưng thực tế 100 rows.
Hãy đọc src/api/users.ts + query COUNT, tự viết script reproduce,
rồi fix. Không đoán mò, phải có bằng chứng chạy được.
```

Kết quả mong đợi:

- Claude trả đúng việc của /effort (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/effort max` báo `unknown effort level` | Bản < 2.1.205 | Update `npm i -g @anthropic-ai/claude-code`; tạm dùng `/effort high` |
| Đặt `max` rồi restart mất | `max` session-only by design | Đặt lại sau mỗi session; hoặc `settings.json` để `high` persistent |
| `high` mà trả lời vẫn cạn | Context nhiễm / prompt mơ hồ | `/compact` + viết rõ tiêu chí; thử `/goal` để ép evaluator |

## Tham khảo

- [../model/README.md](../../model-mode/model/README.md)
- [../fast/README.md](../../model-mode/fast/README.md)
- [../goal/README.md](../../model-mode/goal/README.md)
- [../extra-usage/README.md](../../model-mode/extra-usage/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /effort sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
