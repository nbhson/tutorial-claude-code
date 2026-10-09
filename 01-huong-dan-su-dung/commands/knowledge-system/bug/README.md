# /bug — Gói bug report gửi Anthropic: khi lỗi là của tool, không phải của bạn

> Loại Workflow (thu thập + đóng gói) · Nhóm Tri thức & Hệ thống · Mức rủi ro Có nếu ẩu (gói conversation gửi đi có thể chứa secret/code nội bộ — luôn review trước khi Send)
> **Nói nôm na:** `/bug` thu thập mọi thứ cần để báo lỗi Claude Code: mô tả, bước tái hiện, log, version, transcript rút gọn — đóng thành 1 gói, bạn review rồi mới gửi (GitHub issue hoặc Anthropic support). Dùng khi `/debug` xong kết luận "tôi làm đúng, tool sai". Hiểu 1 câu: `/debug` tự xem, `/bug` gửi người ta xem.

## Khi nào dùng

- Dùng khi `/debug` xong kết luận "tôi làm đúng, tool sai" và bạn cần gửi báo cáo cho Anthropic/GitHub.
- Dùng **trước khi** tự bới log bằng tay: `/bug` gom sẵn mô tả, bước tái hiện, log, version, transcript rút gọn.
- Không dùng khi lỗi do cấu hình/code của bạn — sửa trước, đừng đẩy việc của mình lên tool.

## Cách gọi

```bash
/bug                # thu thập rồi mở bước review trước khi gửi
/bug --anonymize    # che secret/PII (DSN, token) trước khi đóng gói
/bug --dry-run      # chỉ xem gói, chưa gửi
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# /debug xong: cứ gọi mcp__db__query là treo 180s, reconnect không hết, bản cũ không bị.
/bug --anonymize
# B1 mô tả: "mcp__db__query treo sau update 2.1.210, bản 2.1.205 OK. Tái hiện: /mcp add db ... rồi query bất kỳ."
# B3 review: kiểm tra không còn DSN/pass → Send
# → có link issue, dán vào PR nội bộ để team né bản lỗi
```

Kết quả mong đợi:

- Gói report gồm mô tả + bước tái hiện + log/transcript rút gọn + version; sau anonymize không còn secret.
- Gửi xong có link issue (GitHub) hoặc ticket (support) để dán vào PR nội bộ.

**Kiểm tra nhanh:** mở lại gói ở bước B3, grep `password|token|dsn` phải rỗng; `/status` hoặc `/context` xác nhận mode/context còn sạch.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/bug` báo unknown | CLI cũ | Update CLI; hoặc báo tay qua GitHub |
| Anonymize sót secret lạ (format riêng cty) | Pattern không biết | Review tay B3; thêm pattern vào `.claude/bug-ignore` nếu có |
| Issue bị close "need repro" | Thiếu bước tái hiện | Bổ sung 3 bước + clip/log, mở lại |

## Tham khảo

- [../debug/README.md](../../knowledge-system/debug/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _luôn chạy --anonymize trước khi Send — mắt người vẫn là chốt cuối._
