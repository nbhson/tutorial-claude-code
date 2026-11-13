# /cost — Xem tốn bao nhiêu token và bao nhiêu tiền trong phiên

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (lệnh chỉ đọc báo cáo billing, không xóa/sửa gì, không phát sinh phí khi gọi)
> **Nói nôm na:** `/cost` là "hóa đơn tại bàn": cho biết session hiện tại đã đốt bao nhiêu input/output tokens (kể cả cache), quy ra tiền ước tính, để bạn quyết định có nên compact/clear/đổi model hay không.

## Khi nào dùng

- Dùng `/cost` khi bạn muốn biết session đang đốt bao nhiêu token/quy ra tiền để quyết định có nên tiếp.
- Dùng `/cost` sau khi đổi model hoặc trước khi tiếp tục task dài để ý thức ngân sách.
- Không dùng `/cost` như số billing chính thức — đây là ước tính client, dashboard mới là nguồn tin khi trả tiền.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Bảng token vào/ra (kèm cache) và tiền ước tính cho session hiện tại.
- Số này để ra quyết định kỹ thuật; hóa đơn chính thức vẫn ở dashboard.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/cost` báo $0 dù hỏi nhiều | Đang dùng subscription quota, counters hiển thị khác / bản cũ chưa nhân giá | Không phải lỗi nghiêm trọng; xem `/usage` (quota) thay vì `/cost` |
| Số `/cost` khác dashboard | `/cost` ước tính client, dashboard tính giá chính thức + discount/thuế | Tin dashboard cho billing, tin `/cost` cho ra quyết định kỹ thuật |
| Cost vọt sau khi đổi model | Quên model mới đắt hơn: Opus 5.5 là mặc định tài khoản (≥2.1.280), còn Fable 5.1 và Opus fast mode đắt gấp nhiều lần | Gõ `/cost` ngay sau khi đổi để ý thức giá; quay về Sonnet/Haiku 5.5 cho việc vặt |

> **Cách đọc bảng này:** cả 3 dòng đều là chuyện "con số không như bạn tưởng" — **Vì sao** phân biệt ước tính client với billing chính thức, **Cách sửa** cho biết tin đâu, làm gì.

## Tham khảo

- [../usage/README.md](../../session-context/usage/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _đặt ngân sách miệng trước task rồi `/cost` giữa chừng — vượt ngân sách thì `/compact` hoặc hạ model._

> **Tóm gọn 1 câu:** `/cost` là hóa đơn tại bàn: liếm qua biết mình đang đốt bao nhiêu để kịp chỉnh, còn hóa đơn thanh toán thật vẫn ở dashboard.
