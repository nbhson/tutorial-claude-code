# /statusline — Thanh trạng thái tuỳ biến: acc, model, dir, quota luôn trên màn hình

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ hiển thị — nhưng Có nhẹ nếu statusline chạy script ngoài lạ mà bạn paste mù từ internet)

> Nói nôm na: `/statusline` cấu hình dòng thông tin nhỏ hiện thường trực (dưới prompt hoặc chân terminal): `work · default · /repo/api · 84% cache · 132k` — khỏi gõ `/status` 20 lần/ngày. Hiểu `/statusline` là hiểu "dán taplo lên kính lái" — `/status` là mở nắp capo xem, statusline là đồng hồ luôn trước mặt.

## Khi nào dùng

- Dùng /statusline khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /statusline **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /statusline thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/statusline`
`/statusline set <mẫu>`
`/statusline exec <lệnh>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/statusline set "[{acc}] {model} · {cwd}"
# Sáng: "[work] default · /repo" ✓
# Trưa vọc side-project xong quên đổi: "[personal] default · /repo" ← thấy ngay!
# → /login --account work trước khi push code công ty bằng quota túi
```

Kết quả mong đợi:

- Claude trả đúng việc của /statusline (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Biến hiện trống (`{quota}` = rỗng) | Bản CLI cũ chưa có biến đó | Update CLI; bỏ biến đó khỏi mẫu tạm |
| Mỗi Enter chậm 1-2s | Exec nặng | `/statusline` xem exec nào chậm → xoá/cache |
| Sang máy mới mất statusline | Local scope không đi theo | Set lại (copy mẫu từ note cá nhân) |

## Tham khảo

- [../status/README.md](../../auth-settings/status/README.md)
- [../theme/README.md](../../auth-settings/theme/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /statusline sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
