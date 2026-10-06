# /cd — Chuyển thư mục làm việc: giữ prompt cache, trust prompt, Cd permission

> Loại Built-in · Nhóm Settings · Nguy hiểm Có (chuyển vào thư mục untrusted là tự rước CLAUDE.md + hooks + MCP lạ vào session — đọc kỹ trust prompt trước khi Yes)

> Nói nôm na: `/cd` đổi working directory của session đang chạy mà không mất context: history chat giữ nguyên, prompt cache giữ được phần lớn (đỡ tốn tiền nạp lại), nhưng Claude sẽ hỏi trust prompt nếu thư mục mới chưa từng tin tưởng. Hiểu `/cd` là hiểu "chuyển phòng làm việc trong cùng toà nhà" — người (context) vẫn là mình, nhưng phòng mới có luật mới. Khác `add-dir` (mở thêm phòng, giữ phòng cũ) và khác `cd` của shell (shell đổi là mất hết).

## Khi nào dùng

- Dùng /cd khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /cd **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /cd thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/cd <đường-dẫn>`
`/cd ..`
`/cd -`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Sáng ở root:
/status
# → "cwd: /repo · cache hit 91%"

# Vào api sửa bug:
/cd packages/api
# → "cwd: /repo/packages/api · cache reused 84% · loaded api/CLAUDE.md (+12 rules)"
# → sửa code, chạy test ở đây (đường dẫn tương đối đúng luôn)
```

Kết quả mong đợi:

- Claude trả đúng việc của /cd (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `Blocked by Cd deny rule` | Path nằm trong deny (≥2.1.169) | Đúng thiết kế — đừng vào đó; cần thật thì sửa settings (và chịu trách nhiệm) |
| Trust prompt hỏi mỗi lần vào dù đã Trust | Chọn `Trust once` thay vì `Trust & remember`, hoặc trust store bị xoá | Chọn remember; kiểm tra config trust store còn không |
| `/cd` xong lệnh Bash vẫn chạy dir cũ | Dùng `cd` shell thay vì `/cd`, hoặc tool Bash có cwd riêng | Dùng `/cd`; `/status` xác minh cwd session |

## Tham khảo

- [../add-dir/README.md](../../auth-settings/add-dir/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../config/README.md](../../auth-settings/config/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /cd sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
