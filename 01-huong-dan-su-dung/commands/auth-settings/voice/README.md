# /voice — Nói thay vì gõ (giữ Space để nói, thả để gửi)

> Loại Built-in · Nhóm Nhập liệu & Trợ năng · Mức rủi ro Không (chỉ đổi cách nhập; nhưng Có nhẹ nếu bạn đọc to secret/mã OTP nơi đông người)
> **Nói nôm na:** `/voice` bật/tắt voice dictation trong terminal: giữ `Space` để nói, thả ra là transcript thành prompt gửi đi. Sinh ra cho lúc mỏi tay, đang đi bộ với mobile, hoặc ý dài nói nhanh hơn gõ. Hiểu `/voice` là hiểu "nhắn voice như chat app, nhưng nó biến thành chữ trước khi gửi".

## Khi nào dùng

- Dùng khi mỏi tay, đang đi bộ với mobile, hoặc ý dài nói nhanh hơn gõ.
- Dùng **trước khi** rời bàn / chuẩn bị đọc đoạn dài — kiểm tra mic hoạt động từ đầu, khỏi thu được nửa chừng mới biết hỏng.
- Không dùng `/voice` thay cho việc tự đọc lại transcript trước khi gửi — voice dễ sai từ chuyên môn, vẫn phải kiểm tra.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Giữ Space thu giọng, thả ra transcript hiện trong khung nhập.
- Enter mới gửi; bạn đọc lại transcript trước khi gửi.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các trục trặc hay gặp khi thu giọng nói — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Giữ Space không thu, thả ra trống | OS chưa cấp quyền mic (lần đầu Deny) | Settings OS → cho terminal quyền mic; `/terminal-setup` kiểm tra lại |
| Transcript toàn sai từ chuyên môn | Nói nhanh + từ lạ (`webhook`, `idempotency`) | Nói chậm, đánh vần tên riêng; hoặc gõ tay đoạn có từ chuyên môn |
| Thu cả tiếng quạt/đồng nghiệp | Mic mặc định là mic xa/kém chống ồn | Đổi mic gần (tai nghe) trong settings OS; vào chỗ yên |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng lúc thu/phát, "Vì sao" chỉ nguyên nhân (quyền OS, cách nói, mic), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/voice` là nhắn voice mà app tự đổi thành chữ — nói thay gõ khi mỏi tay, nhưng luôn đọc lại transcript trước khi gửi.

## Tham khảo

- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../mobile/README.md](../../auth-settings/mobile/README.md)
- [../btw/README.md](../../code-repo/btw/README.md)
- [../background/README.md](../../session-context/background/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /voice sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
