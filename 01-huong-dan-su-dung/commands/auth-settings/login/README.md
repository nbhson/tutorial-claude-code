# /login — Đăng nhập tài khoản: OAuth trình duyệt, chọn plan, lưu token máy local

> Loại Built-in · Nhóm Auth · Mức rủi ro Không (chỉ mở flow xác thực; nhưng Có nhẹ nếu login nhầm tài khoản cá nhân trên máy công ty — token lưu local ai cầm máy cũng dùng được)
> **Nói nôm na:** `/login` mở quy trình đăng nhập Claude Code: sinh URL OAuth (hoặc mở sẵn trình duyệt), bạn duyệt quyền trên web, CLI nhận token và lưu vào máy local, từ đó mọi session dùng quota của tài khoản đó. Hiểu `/login` là hiểu "cắm chìa khoá" — làm 1 lần, dùng nhiều tháng cho tới khi token hết hạn hoặc `/logout`.

## Khi nào dùng

- Dùng khi máy chưa đăng nhập (mới cài, token hết hạn, vừa bị logout) hoặc muốn đổi sang tài khoản/plan khác.
- Dùng **trước khi** bắt đầu task thật (đầu ngày, đầu session): login đúng tài khoản có quota trước, tránh giữa task mới hết hạn mức.
- Không dùng `/login` thay cho việc tự kiểm tra tài khoản đang dùng: login xong vẫn nên `/status` xem mình đang là ai.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Trình duyệt mở trang xác thực; duyệt xong terminal báo `✓ Signed in as <email> (<plan>)`.
- Token lưu vào `~/.claude/`; các session sau dùng luôn quota tài khoản vừa login.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Trình duyệt mở nhưng bấm Authorize xong CLI vẫn chờ | Callback localhost bị chặn (firewall/VPN) hoặc mở nhầm profile trình duyệt | Copy URL sang trình duyệt khác; tắt VPN thử; dùng device-code (mở trên máy khác, nhập mã) |
| `No browser detected` trên máy có GUI | Biến `BROWSER` unset hoặc chạy qua tmux/SSH | Set `export BROWSER=open` (macOS) rồi `/login` lại; hoặc dùng device-code |
| `Token expired, please re-authenticate` liên tục | Refresh token bị thu hồi (đổi pass, admin revoke) hoặc đồng hồ máy lệch | `/logout` rồi `/login` lại từ đầu; `sudo ntpdate` đồng bộ giờ |

> **Cách đọc bảng này:** "Triệu chứng" là thông báo lỗi trên màn hình, "Vì sao" chỉ nguyên nhân phía mạng/tài khoản, "Cách sửa" là hướng đi thay thế — đọc đúng hàng đang dính, có hàng phải thử nhiều phương án.

> **Tóm gọn 1 câu:** `/login` là cắm chìa khoá vào máy — làm một lần dùng nhiều tháng, và login xong nhớ `/status` xem mình đang là ai.

## Tham khảo

- [../logout/README.md](../../auth-settings/logout/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /login sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
