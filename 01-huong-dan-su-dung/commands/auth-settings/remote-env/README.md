# /remote-env — Cấu hình môi trường cho session remote/cloud (env, region, runtime)

> Loại Built-in · Nhóm Remote · Mức rủi ro Có nhẹ (env chứa secret — set sai rò rỉ vào log/transcript; nhưng Không đụng code local)
> **Nói nôm na:** `/remote-env` xem/sửa biến môi trường và cấu hình runtime của phía remote (cloud session sau `/teleport`, runner CI): `API_KEY`, `DATABASE_URL`, `NODE_ENV`, region... Local `.env` KHÔNG tự bay sang remote (bị deny) nên phải cấp lại ở đây. Hiểu `/remote-env` là hiểu "soạn vali cho chuyến đi" — teleport bê người, remote-env bê đồ.

## Khi nào dùng

- Dùng khi session remote/cloud báo thiếu biến môi trường (`XXX is not defined`) hoặc cần đổi region/runtime phía remote.
- Dùng **trước khi** teleport sang làm ở remote: soát env bằng `/remote-env diff` từ đầu, khỏi vỡ build giữa chừng mới cuống.
- Không dùng `/remote-env` thay cho việc tự giữ secret an toàn — env remote vẫn là bề mặt rò rỉ, đừng set hết mọi thứ lên.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Xem/sửa env + runtime phía remote; `diff` chỉ ra biến còn thiếu.
- Biến set xong áp cho process remote mới; process đang chạy phải restart.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các sự cố hay gặp khi cấu hình env cho session remote — gặp đúng triệu chứng dưới đây thì làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `DATABASE_URL is not defined` trên cloud dù local có | `.env` không bay theo (đúng thiết kế) | `/remote-env set` lại phía remote |
| Set rồi mà process cũ không nhận | Process đang chạy giữ env cũ | Restart process/session remote sau khi set |

> **Cách đọc bảng này:** đọc theo hàng — cột "Triệu chứng" là thứ bạn thấy trên màn hình, "Vì sao" chỉ gốc rễ, "Cách sửa" là việc cần làm ngay.

> **Tóm gọn 1 câu:** `/remote-env` là chỗ cấp "đồ dùng" cho chuyến đi cloud — env không tự bay theo, thiếu thứ gì thì set lại ngay phía đó.

## Tham khảo

- [../teleport/README.md](../../auth-settings/teleport/README.md)
- [../mobile/README.md](../../auth-settings/mobile/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /remote-env sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
