# /bug — Gói bug report gửi Anthropic: khi lỗi là của tool, không phải của bạn

> Loại Workflow (thu thập + đóng gói) · Nhóm Tri thức & Hệ thống · Mức rủi ro Có nếu ẩu (gói conversation gửi đi có thể chứa secret/code nội bộ — luôn review trước khi Send)
> **Nói nôm na:** `/bug` thu thập mọi thứ cần để báo lỗi Claude Code: mô tả, bước tái hiện, log, version, transcript rút gọn — đóng thành 1 gói, bạn review rồi mới gửi (GitHub issue hoặc Anthropic support). Dùng khi `/debug` xong kết luận "tôi làm đúng, tool sai". Hiểu 1 câu: `/debug` tự xem, `/bug` gửi người ta xem.

## Khi nào dùng

- Dùng khi `/debug` xong kết luận "tôi làm đúng, tool sai" và bạn cần gửi báo cáo cho Anthropic/GitHub.
- Dùng **trước khi** tự bới log bằng tay: `/bug` gom sẵn mô tả, bước tái hiện, log, version, transcript rút gọn.
- Không dùng khi lỗi do cấu hình/code của bạn — sửa trước, đừng đẩy việc của mình lên tool.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Gói report gồm mô tả + bước tái hiện + log/transcript rút gọn + version; sau anonymize không còn secret.
- Gửi xong có link issue (GitHub) hoặc ticket (support) để dán vào PR nội bộ.

**Kiểm tra nhanh:** mở lại gói ở bước B3, grep `password|token|dsn` phải rỗng; `/status` hoặc `/context` xác nhận mode/context còn sạch.

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/bug`: từ gói báo lỗi bị đóng tới issue thiếu repro, kèm cách xử lý.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/bug` báo unknown | CLI cũ | Update CLI; hoặc báo tay qua GitHub |
| Anonymize sót secret lạ (format riêng cty) | Pattern không biết | Review tay B3; thêm pattern vào `.claude/bug-ignore` nếu có |
| Issue bị close "need repro" | Thiếu bước tái hiện | Bổ sung 3 bước + clip/log, mở lại |

> **Cách đọc bảng này:** "Triệu chứng" là phản hồi bạn nhận, "Vì sao" giải thích vì sao hệ thống phản ứng vậy, "Cách sửa" là bước xử lý được ngay.

> **Tóm gọn 1 câu:** `/debug` là tự soi gương, còn `/bug` là gửi mẫu bệnh phẩm lên phòng xét nghiệm của Anthropic — nhớ khử khuẩn (anonymize) trước khi gửi.

## Tham khảo

- [../debug/README.md](../../knowledge-system/debug/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../stats/README.md](../../knowledge-system/stats/README.md)
- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _luôn chạy --anonymize trước khi Send — mắt người vẫn là chốt cuối._
