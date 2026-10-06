# /add-dir — Mở thêm thư mục vào session: đa root, so sánh chéo, mở rộng attack surface

> Loại Built-in · Nhóm Settings · Nguy hiểm Có (mỗi dir thêm vào là thêm CLAUDE.md + hooks + MCP lạ vào context — càng nhiều dir, attack surface càng rộng; trust từng cái như `/cd`)

> Nói nôm na: `/add-dir` gắn thêm 1 (hoặc nhiều) thư mục vào session hiện tại mà KHÔNG bỏ dir cũ: làm ở `api` nhưng vẫn đọc được `shared`, so sánh 2 repo cạnh nhau, sửa bug xuyên package. Hiểu `/add-dir` là hiểu "mở thêm phòng" — nhà cũ vẫn giữ, nhà mới thêm vào. Khác `/cd` (dọn sang phòng mới, bỏ phòng cũ).

## Khi nào dùng

- Dùng /add-dir khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /add-dir **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /add-dir thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/add-dir <path>`
`/add-dir <p1> <p2>...`
`/add-dir --list`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Đang ở api, stack trace chỉ vào shared/lib.ts:
/add-dir ../shared
# → "Added shared · CLAUDE.md loaded (env flag on)"

# Đọc chéo:
# Read packages/shared/src/lib.ts → thấy hàm sai
# Edit ở shared, test ở api (Bash vẫn chạy main=api)
npm test
```

Kết quả mong đợi:

- Claude trả đúng việc của /add-dir (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Add rồi mà luật dir phụ không áp | CLAUDE.md chưa load (thiếu env flag) | `/status` kiểm tra → bật flag → remove + add lại |
| `Blocked by Cd deny rule` khi add | Dir nằm trong deny | Đúng thiết kế; cần thật thì sửa settings (chịu trách nhiệm) |
| Trust prompt lặp lại mỗi session | Mới `Trust once`, chưa remember | Trust & remember; hoặc session mới ở máy khác chưa có trust store |

## Tham khảo

- [../cd/README.md](../../auth-settings/cd/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /add-dir sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
