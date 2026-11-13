# /statusline — Thanh trạng thái tuỳ biến: acc, model, dir, quota luôn trên màn hình

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ hiển thị — nhưng Có nhẹ nếu statusline chạy script ngoài lạ mà bạn paste mù từ internet)
> **Nói nôm na:** `/statusline` cấu hình dòng thông tin nhỏ hiện thường trực (dưới prompt hoặc chân terminal): `work · default · /repo/api · 84% cache · 132k` — khỏi gõ `/status` 20 lần/ngày. Hiểu `/statusline` là hiểu "dán taplo lên kính lái" — `/status` là mở nắp capo xem, statusline là đồng hồ luôn trước mặt.

## Khi nào dùng

- Dùng khi bạn muốn acc/model/cwd/quota hiện thường trực mà không phải gõ `/status` nhiều lần trong ngày.
- Dùng **trước khi** không muốn lặp lại `/status` (đầu ngày, đầu session): set statusline 1 lần, thấy `[acc]` đổi là nhận ra nhầm tài khoản ngay.
- Không dùng `/statusline` thay cho việc tự để mắt trạng thái bất thường — dòng hiển thị có, nhưng bạn vẫn phải nhìn.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Thanh trạng thái hiện thường trực dưới prompt theo đúng mẫu đã set.
- Biến `{acc}`/`{model}`/`{cwd}` đổi theo session, thấy ngay khi nhầm tài khoản.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các trục trặc hay gặp khi cấu hình và dùng thanh trạng thái — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Biến hiện trống (`{quota}` = rỗng) | Bản CLI cũ chưa có biến đó | Update CLI; bỏ biến đó khỏi mẫu tạm |
| Mỗi Enter chậm 1-2s | Exec nặng | `/statusline` xem exec nào chậm → xoá/cache |
| Sang máy mới mất statusline | Local scope không đi theo | Set lại (copy mẫu từ note cá nhân) |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng trên màn hình, "Vì sao" cho biết lỗi ở bản CLI hay ở cấu hình, "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/statusline` gắn đồng hồ cố định lên kính lái: thông tin quan trọng luôn trước mắt, nhầm tài khoản hay hết quota là thấy ngay.

## Tham khảo

- [../status/README.md](../../auth-settings/status/README.md)
- [../theme/README.md](../../auth-settings/theme/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /statusline sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
