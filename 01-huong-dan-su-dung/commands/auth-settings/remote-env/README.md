# /remote-env — Cấu hình môi trường cho session remote/cloud (env, region, runtime)

> Loại Built-in · Nhóm Remote · Nguy hiểm Có nhẹ (env chứa secret — set sai rò rỉ vào log/transcript; nhưng Không đụng code local)

> Nói nôm na: `/remote-env` xem/sửa biến môi trường và cấu hình runtime của phía remote (cloud session sau `/teleport`, runner CI): `API_KEY`, `DATABASE_URL`, `NODE_ENV`, region... Local `.env` KHÔNG tự bay sang remote (bị deny) nên phải cấp lại ở đây. Hiểu `/remote-env` là hiểu "soạn vali cho chuyến đi" — teleport bê người, remote-env bê đồ.

## Khi nào dùng

- Dùng /remote-env khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /remote-env **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /remote-env thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/remote-env`
`/remote-env set <K> <V>`
`/remote-env unset <K>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Vừa /teleport cloud, chạy build:
npm run build
# → "Error: DATABASE_URL is not defined"

# So rồi cấp:
/remote-env diff
# → "Missing on remote: DATABASE_URL, STRIPE_KEY"
# Lưu ý: endpoint CLOUD, đừng paste localhost sang:
```

Kết quả mong đợi:

- Claude trả đúng việc của /remote-env (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `DATABASE_URL is not defined` trên cloud dù local có | `.env` không bay theo (đúng thiết kế) | `/remote-env set` lại phía remote |
| Set rồi mà process cũ không nhận | Process đang chạy giữ env cũ | Restart process/session remote sau khi set |

## Tham khảo

- [../teleport/README.md](../../auth-settings/teleport/README.md)
- [../mobile/README.md](../../auth-settings/mobile/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /remote-env sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
