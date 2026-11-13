# /fork — Tách conversation hiện tại thành nhánh mới, giữ bản gốc nguyên vẹn

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (không xóa/sửa file; chỉ copy context sang session mới — bản gốc giữ nguyên)
> **Nói nôm na:** `/fork` là "rẽ nhánh không sợ hỏng": copy toàn bộ (hoặc 1 phần) context hiện tại sang 1 conversation mới để thử hướng khác, trong khi bản gốc vẫn an toàn.

## Khi nào dùng

- Dùng `/fork` khi bạn muốn thử một hướng khác mà không sợ làm hỏng conversation gốc.
- Dùng `/fork` **trước khi** bắt đầu thí nghiệm dài, và `/compact` trước nếu session đã nặng.
- Không dùng `/fork` để cách ly file — hai nhánh chung filesystem, cần `git worktree` nếu muốn tách code thật.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).
> Fork mode (subagent hưởng nguyên context) bật mặc định từ ≥2.1.232, tắt bằng `CLAUDE_CODE_FORK_SUBAGENT=0`.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Có session mới mang context bản gốc để thử hướng khác; bản gốc vẫn còn nếu hướng thử thua.
- Hai nhánh chung filesystem — muốn tách code phải dùng `git worktree`/`git branch`.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Fork xong 2 nhánh sửa cùng file loạn | Chung filesystem, không cách ly file | Dùng `git worktree` / `git branch` riêng cho mỗi hướng |
| Fork từ session 80% RAM, nhánh mới đã đầy | Copy nguyên history nặng | `/compact` trước khi fork, hoặc fork sớm hơn |
| Không biết đang ở nhánh nào | Quên rename sau fork | `/rename` ngay sau fork; kiểm tra picker `/resume` |

> **Cách đọc bảng này:** dòng nào cũng xoay quanh một sự thật: fork chỉ chia trí nhớ, không chia đĩa — **Vì sao** nói về chung filesystem, **Cách sửa** là cách tách thật hoặc đặt nhãn.

## Tham khảo

- [../branch/README.md](../../session-context/branch/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../rename/README.md](../../session-context/rename/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _fork khi session còn nhẹ; session đã ~80% thì `/compact` trước để nhánh mới không đầy ngay._

> **Tóm gọn 1 câu:** `/fork` cho bạn một bản sao không sợ hỏng để đi thử hướng khác — bản gốc vẫn nằm đó nếu hướng thử thua.
