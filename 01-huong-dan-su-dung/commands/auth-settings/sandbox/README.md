# /sandbox — Hộp cát: dependency status, chạy thử cách ly, nổ thì không sao

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chính nó là phanh — chạy trong cát thì nổ cũng không văng ra ngoài; nhưng Có nếu bạn tin "đã sandbox" rồi chạy bừa lệnh phá hoại mà sandbox cấu sai)
> **Nói nôm na:** `/sandbox` quản lý môi trường chạy cách ly: kiểm tra dependency status (cái gì thiếu/hỏng trong cát), chạy lệnh thử trong cát trước khi chạy thật, xoá cát làm lại khi bẩn. Hiểu `/sandbox` là hiểu "phòng thí nghiệm có kính chống nổ" — thuốc mới thử trong này, nổ thì lau kính chứ không sập nhà.

## Khi nào dùng

- Dùng khi muốn chạy thử package/lệnh chưa rõ độ tin cậy trong cách ly trước khi cho chạy thật: cài lib lạ, script có gọi mạng.
- Dùng **trước khi** cài/chạy thứ lạ (đầu task, trước việc chạm mạng hoặc ghi file nhạy cảm): thử trong cát trước, nổ thì `reset` không mất gì.
- Không dùng `/sandbox` thay cho việc tự đọc lệnh trước khi chạy thật ngoài cát — sandbox config sai vẫn không phải là giấy miễn tội.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Trạng thái cát hiện toolchain + network + mounts (`node 20 ✓ · network: blocked`).
- Lệnh chạy trong cát không đụng máy thật; nổ thì `reset` là sạch.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các trục trặc hay gặp khi làm việc trong hộp cát — so lại triệu chứng trên máy bạn rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `command not found` trong cát dù ngoài có | Toolchain cát thiếu | `status` xem thiếu gì; cài vào image cát hoặc chạy ngoài |
| Lệnh cần mạng fail trong cát | Network blocked (đúng thiết kế) | Allowlist registry cần thiết, hoặc chạy ngoài khi đã tin |
| File ghi trong cát "mất" sau reset | Reset xoá state cát | Copy kết quả ra `/repo` (mount chung) trước khi reset |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng bạn gặp, "Vì sao" cho biết nguyên nhân nằm ở cát hay ở mình, "Cách sửa" là việc tiếp theo.

> **Tóm gọn 1 câu:** `/sandbox` là sân tập có rào an toàn — thử mọi thứ lạ trong cát trước cho tới khi tin, rồi mới cho ra sân thật.

## Tham khảo

- [../config/README.md](../../auth-settings/config/README.md)
- [../remote-env/README.md](../../auth-settings/remote-env/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /sandbox sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
