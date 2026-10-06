# /teleport — Chuyển session đang chạy giữa terminal local và cloud (hoặc máy ↔ máy)

> Loại Built-in · Nhóm Remote · Nguy hiểm Có nhẹ (session + file context di chuyển qua mạng — mạng lạ/VPN công ty có thể nhìn thấy metadata; nhưng Không mất code nếu làm đúng)

> Nói nôm na: `/teleport` "dịch chuyển tức thời" session đang chạy: đang làm trên terminal công ty, teleport sang cloud (hoặc sang laptop ở nhà) là tiếp tục đúng chỗ — history, todos, file đang sửa đi theo. Hiểu `/teleport` là hiểu "bê cả bàn làm việc sang phòng khác" — khác `/mobile` (điều khiển từ điện thoại) và `/remote-env` (cấu hình môi trường remote).

## Khi nào dùng

- Dùng /teleport khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /teleport **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /teleport thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/teleport`
`/teleport cloud`
`/teleport local`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# 17h55 ở công ty, task còn nửa:
git add -A && git commit -m "WIP: teleport checkpoint"
/teleport cloud
# → "Session live on cloud. Link: https://claude.ai/s/abc123"

# Về nhà, mở laptop:
/teleport local
# → "Pulled 12 new messages (cloud ran tests while you commuted)."
```

Kết quả mong đợi:

- Claude trả đúng việc của /teleport (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/teleport cloud` treo ở `Uploading...` | Diff quá lớn (node_modules/build lọt vào) hoặc mạng yếu | `git status` xem diff; thêm `.gitignore` đúng; commit bớt rồi teleport lại; thử region gần hơn |
| Kéo về báo `conflict: 3 files` | Cả 2 bên cùng sửa lúc xa nhau | Đọc diff từng file (`git diff`), chọn tay; đừng `--force` mù |
| `--list` thấy device `(offline)` | Máy kia sleep/tắt/mất mạng | Bật máy kia hoặc đi vòng qua cloud relay |

## Tham khảo

- [../mobile/README.md](../../auth-settings/mobile/README.md)
- [../remote-env/README.md](../../auth-settings/remote-env/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /teleport sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
