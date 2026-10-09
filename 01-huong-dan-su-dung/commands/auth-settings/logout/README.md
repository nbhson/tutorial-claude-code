# /logout — Đăng xuất: xoá token local, cắt session khỏi tài khoản

> Loại Built-in · Nhóm Auth · Mức rủi ro Có nhẹ (mất token local — session đang chạy đứt auth, cloud session pair cùng account cũng phải login lại; nhưng Không mất code/history trên máy)
> **Nói nôm na:** `/logout` đăng xuất tài khoản hiện tại: xoá access + refresh token khỏi `~/.claude/`, session đang mở mất quyền gọi model ngay lập tức. Dùng khi đổi tài khoản, trả máy share, hoặc nghi token lộ. Hiểu `/logout` là hiểu "rút chìa khoá" — ngược hoàn toàn với `/login`.

## Khi nào dùng

- Dùng khi trả máy/share máy, đổi tài khoản, hoặc nghi token đã lộ.
- Dùng **trước khi** mất quyền kiểm soát máy (trả máy công ty, cho mượn máy): logout sớm, đừng đợi lúc gấp mới nhớ.
- Không dùng `/logout` thay cho việc tự xoá data nhạy cảm trên máy share — logout chỉ rút chìa khoá, không quét sạch file.

## Cách gọi

```bash
`/logout`
`/logout --all`
`/logout --account <tên>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Làm xong, trước khi trả máy:
/logout --all
# → "Signed out of all accounts (2 profiles)."

# Kiểm tra chắc chắn:
/status
# → "Not signed in."
```

Kết quả mong đợi:

- Claude trả đúng việc của /logout (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/logout` xong `/status` vẫn hiện đã login | Có nhiều profile, mới logout 1 cái | `/logout --all` hoặc logout đúng `--account` đang active |
| Logout khi offline báo revoke failed | Không gọi được server để revoke | Không sao — token local đã xoá; có mạng thì login lại 1 lần rồi logout lại để revoke sạch |
| Login lại ngay mà báo `rate limited` | Logout/login liên tục kích hoạt chống abuse | Đợi 2-5 phút rồi login lại |

## Tham khảo

- [../login/README.md](../../auth-settings/login/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../exit/README.md](../../auth-settings/exit/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /logout sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
