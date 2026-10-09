# /cd — Chuyển thư mục làm việc: giữ prompt cache, trust prompt, Cd permission

> Loại Built-in · Nhóm Settings · Mức rủi ro Có (chuyển vào thư mục untrusted là tự rước CLAUDE.md + hooks + MCP lạ vào session — đọc kỹ trust prompt trước khi Yes)
> **Nói nôm na:** `/cd` đổi working directory của session đang chạy mà không mất context: history chat giữ nguyên, prompt cache giữ được phần lớn (đỡ tốn tiền nạp lại), nhưng Claude sẽ hỏi trust prompt nếu thư mục mới chưa từng tin tưởng. Hiểu `/cd` là hiểu "chuyển phòng làm việc trong cùng toà nhà" — người (context) vẫn là mình, nhưng phòng mới có luật mới. Khác `add-dir` (mở thêm phòng, giữ phòng cũ) và khác `cd` của shell (shell đổi là mất hết).

## Khi nào dùng

- Dùng khi bạn cần đổi nơi làm việc của session đang chạy mà không mất history/prompt cache: từ root xuống `packages/api`, từ repo này sang repo kia.
- Dùng **trước khi** task bắt đầu ăn sâu vào một thư mục mới (đầu task, đầu session, trước việc chạy test đúng dir) — cần ≥2.1.169; chọn đúng `/cd` sớm rẻ hơn sửa path lộn xộn sau.
- Không dùng `/cd` thay cho đọc kỹ trust prompt: thư mục untrusted có CLAUDE.md/hooks/MCP lạ — bạn vẫn phải tự đọc trước khi Yes.

## Cách gọi

```bash
`/cd <đường-dẫn>`
`/cd ..`
`/cd -`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

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

**Kiểm tra nhanh:**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
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
