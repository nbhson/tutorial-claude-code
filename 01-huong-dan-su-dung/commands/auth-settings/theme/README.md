# /theme — Đổi giao diện: sáng/tối, tương phản cao, mù màu

> Loại Built-in · Nhóm Settings · Mức rủi ro Không (chỉ đổi màu — không đụng code, auth, hay permissions)
> **Nói nôm na:** `/theme` đổi bảng màu CLI: tối (mặc định), sáng (ra nắng), tương phản cao (mắt kém), thân thiện mù màu. Hiểu `/theme` là hiểu "đổi áo" — mặc gì thì làm việc vẫn thế, nhưng nhìn lâu đỡ mỏi.

## Khi nào dùng

- Dùng khi đổi môi trường ánh sáng (ra nắng, phòng tối) hoặc muốn tương phản cao / thân thiện mù màu cho đỡ mỏi mắt.
- Dùng **trước khi** demo trình diễn (màn hình lóa, máy chiếu): đổi `/theme light` sớm để diff đọc được, khỏi sửa giữa lúc demo.
- Không dùng `/theme` thay cho việc tự bảo trì theme terminal bên ngoài — nó chỉ đổi bảng màu CLI, không sửa theme terminal.

## Cách gọi

```bash
`/theme`
`/theme <tên>`
`/theme --list`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Đang theme dark, ra sân demo với khách, màn hình lóa:
/theme light
# → diff đọc được ngay, demo tiếp không mất mặt
# Về văn phòng: /theme dark (1 giây)
```

Kết quả mong đợi:

- Claude trả đúng việc của /theme (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Đổi theme mà màu không đổi | Terminal ép 16 màu hoặc `NO_COLOR` set | Kiểm tra terminal truecolor; `unset NO_COLOR` |
| Picker theme trống | Themes dir bị xoá | Reinstall CLI hoặc copy themes từ máy khác |
| Theme không nhớ sau restart | Sửa file tay sai scope | Đổi bằng `/theme` (lưu local đúng chỗ) thay vì sửa tay |

## Tham khảo

- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../statusline/README.md](../../auth-settings/statusline/README.md)
- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /theme sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
