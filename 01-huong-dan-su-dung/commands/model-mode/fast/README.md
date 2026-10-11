# /fast — Chế độ nhanh: trả lời gấp cho việc dễ, không chờ suy luận sâu

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (chỉ giảm độ sâu suy luận / về model nhẹ; không sửa file ngoài ý muốn)
>
> **Nói nôm na:** `/fast` là nút "tăng tốc": ép phiên về chế độ nhanh (thường tương đương Sonnet + effort thấp, ít vòng tool-call) để trả lời ngay cho việc dễ — giải thích code, tra cứu, việc vặt. Trên Opus 5.5, fast mode tính giá riêng $8/$40 (nhanh hơn ~2.5×), cần ≥2.1.280 và **chỉ có trên Anthropic API** — không hỗ trợ trên Bedrock/GCP/AWS.

## Khi nào dùng

- Dùng /fast khi cần trả lời gấp cho việc dễ (giải thích code, tra cứu, việc vặt) — đổi tốc độ lấy độ sâu suy luận.
- Dùng /fast **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /fast thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
/fast
/fast <câu hỏi>
/model sonnet
/effort low
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
/fast Tóm tắt module src/payments/ trong 5 bullet cho người không code.
```

Kết quả mong đợi:

- Trả lời nhanh, ít vòng tool-call — hợp việc dễ (giải thích code, tra cứu, việc vặt).
- Không hợp bài cần suy luận sâu; xong việc nhớ về `/effort medium` cho phiên sau.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/fast` báo `unknown command` | Bản không có lệnh riêng | Dùng `/effort low` thay thế |
| Fast không thấy nhanh hơn khi chạy Bedrock/GCP/AWS | Fast mode chỉ có trên Anthropic API | Dùng `/effort low` + `/model sonnet` thay thế |
| Fast trả lời ẩu, sai | Dùng fast cho bài khó | Lên `/effort medium`/`high` |
| Bật fast rồi quên, bài khó sau cũng ẩu | Fast còn hiệu lực session | `/effort medium` để về bình thường |

## Tham khảo

- [../effort/README.md](../../model-mode/effort/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../extra-usage/README.md](../../model-mode/extra-usage/README.md)
- [../btw/README.md](../../code-repo/btw/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /fast sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
