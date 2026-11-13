# /stats — Tiền đi đâu: token, chi phí, hạn mức hôm nay

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ xem số, không sửa, không gửi đi)
> **Nói nôm na:** `/stats` hiện bảng tiêu thụ: hôm nay/tuần này đốt bao nhiêu token (in/out, cache-hit), quy ra tiền, còn bao nhiêu quota, việc nào ngốn nhất. Mở mỗi sáng để biết "hôm nay còn bắn được bao nhiêu", cuối tuần để biết "tuần này đắt vì đâu". Hiểu 1 câu: `/stats` là đồng hồ xăng — `/insights` mới là bác sĩ.

## Khi nào dùng

- Dùng mỗi sáng để biết còn quota, cuối tuần để biết tuần này đắt vì đâu.
- Dùng **trước khi** nhận việc lớn: biết còn xăng mới dám nhận refactor dài.
- Không dùng thay `/insights`: `/stats` là đồng hồ xăng, `/insights` mới là bác sĩ.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Bảng token in/out/cache + quy ra tiền/quota %.
- Cache-hit cao (70%) là dấu hiệu tốt.

**Kiểm tra nhanh:** đối chiếu với `/cost` cùng nguồn; nếu 0 token thì kiểm tra account đang login.

> **Tóm gọn 1 câu:** `/stats` là đồng hồ xăng của phiên làm việc: nhìn một cái biết còn bao nhiêu quota, tuần này đốt tiền vào việc nào — còn chẩn bệnh thì giao cho `/insights`.

## Lỗi thường gặp

Bảng dưới là mấy lần "đồng hồ báo sai" hay gặp — so triệu chứng của bạn với cột đầu rồi xử theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/stats` trống (0 token) | Nhầm profile/account, hoặc log mới xoá | Kiểm tra account đang login; đúng `~/.claude/` |
| Tiền hiển thị 0$ dù đã dùng | Plan unlimited/team tính khác | Xem quota % thay vì $; hỏi admin team |
| `--by-task` gom sai việc | Session đặt tên trùng/không tên | Đặt tên session rõ (`refactor-auth` thay vì `untitled-12`) |

> **Cách đọc bảng này:** mỗi dòng là một con số "không như bạn nghĩ"; cột "Vì sao" cho biết lỗi nằm ở account, ở gói hay ở cách đặt tên, cột "Cách sửa" là bước kiểm tra cụ thể.

## Tham khảo

- [../insights/README.md](../../knowledge-system/insights/README.md)
- [../cost/README.md](../../session-context/cost/README.md)
- [../usage/README.md](../../session-context/usage/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _xem % quota thay vì $ nếu dùng gói team/unlimited — số tiền có thể hiện 0._
