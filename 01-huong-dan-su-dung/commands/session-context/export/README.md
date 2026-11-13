# /export — Xuất toàn bộ hội thoại ra file text để lưu trữ, bàn giao, đối soát

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (chỉ đọc + ghi 1 file export mới, không xóa/sửa code hay history)
> **Nói nôm na:** `/export` là "nút in báo cáo": gom transcript hiện tại thành 1 file text/markdown gọn gàng để gửi đồng đội, lưu docs, hoặc đọc lại sau khi `/clear`.

## Khi nào dùng

- Dùng `/export` khi bạn cần lưu trữ transcript, bàn giao ca làm việc, hoặc đọc lại sau khi `/clear`.
- Dùng `/export` ở cuối ca hoặc sau khi `/compact` để file ra gọn, có quyết định và bước tiếp theo.
- Không dùng `/export` thay cho backup code — nó chỉ in hội thoại ra file text, không snapshot source.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Transcript được ghi ra một file text/markdown (Claude báo đường dẫn ngay sau lệnh).
- File đủ gọn để đồng đội đọc vài phút là tiếp việc.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Không biết file export nằm đâu | Mỗi bản gợi ý đường dẫn khác nhau, dễ bỏ qua | Đọc kỹ câu trả lời sau `/export`, hoặc dặn trước "lưu vào docs/handover.md" |
| File export quá dài (5000+ dòng) | Xuất nguyên session 100+ turns chưa compact | `/compact` trước rồi export; hoặc dặn "chỉ xuất quyết định + bước tiếp theo" |
| Export thiếu đoạn trước compact | Đúng thiết kế: đoạn cũ đã nén thành summary | Muốn full thì soi `.jsonl` gốc, hoặc export thường xuyên hơn |

> **Cách đọc bảng này:** cột **Triệu chứng** là chuyện hay xảy ra ngay sau khi bấm export, **Vì sao** nói rõ lỗi nằm ở mình hay ở thiết kế lệnh, **Cách sửa** là cách né cho lần tới.

## Tham khảo

- [../copy/README.md](../../session-context/copy/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _`/compact` rồi mới `/export` để file bàn giao gọn; export ngay cuối ca trước khi `/clear`._

> **Tóm gọn 1 câu:** `/export` in cả cuốn hội thoại thành một file bàn giao — đồng đội đọc vài phút là bắt nhịp được việc.
