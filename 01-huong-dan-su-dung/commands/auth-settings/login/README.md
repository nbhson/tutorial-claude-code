# /login — Đăng nhập tài khoản: OAuth trình duyệt, chọn plan, lưu token máy local

> Loại Built-in · Nhóm Auth · Mức rủi ro Không (chỉ mở flow xác thực; nhưng Có nhẹ nếu login nhầm tài khoản cá nhân trên máy công ty — token lưu local ai cầm máy cũng dùng được)
> **Nói nôm na:** `/login` mở quy trình đăng nhập Claude Code: sinh URL OAuth (hoặc mở sẵn trình duyệt), bạn duyệt quyền trên web, CLI nhận token và lưu vào máy local, từ đó mọi session dùng quota của tài khoản đó. Hiểu `/login` là hiểu "cắm chìa khoá" — làm 1 lần, dùng nhiều tháng cho tới khi token hết hạn hoặc `/logout`.

## Khi nào dùng

- Dùng khi máy chưa đăng nhập (mới cài, token hết hạn, vừa bị logout) hoặc muốn đổi sang tài khoản/plan khác.
- Dùng **trước khi** bắt đầu task thật (đầu ngày, đầu session): login đúng tài khoản có quota trước, tránh giữa task mới hết hạn mức.
- Không dùng `/login` thay cho việc tự kiểm tra tài khoản đang dùng: login xong vẫn nên `/status` xem mình đang là ai.

## Cách gọi

```bash
`/login`
`/login --sso`
`/login --api-key`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Vừa cài xong theo bài 01, mở terminal:
claude

# Trong session gõ:
/login
# → Trình duyệt tự mở, bấm "Authorize Claude Code"
# → Terminal báo: "✓ Signed in as ban@gmail.com (Pro)"
```

Kết quả mong đợi:

- Claude trả đúng việc của /login (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Trình duyệt mở nhưng bấm Authorize xong CLI vẫn chờ | Callback localhost bị chặn (firewall/VPN) hoặc mở nhầm profile trình duyệt | Copy URL sang trình duyệt khác; tắt VPN thử; dùng device-code (mở trên máy khác, nhập mã) |
| `No browser detected` trên máy có GUI | Biến `BROWSER` unset hoặc chạy qua tmux/SSH | Set `export BROWSER=open` (macOS) rồi `/login` lại; hoặc dùng device-code |
| `Token expired, please re-authenticate` liên tục | Refresh token bị thu hồi (đổi pass, admin revoke) hoặc đồng hồ máy lệch | `/logout` rồi `/login` lại từ đầu; `sudo ntpdate` đồng bộ giờ |

## Tham khảo

- [../logout/README.md](../../auth-settings/logout/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /login sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
