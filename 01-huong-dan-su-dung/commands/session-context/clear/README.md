# /clear — Xóa sạch lịch sử hội thoại, bắt đầu phiên mới trắng tinh

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (không xóa/sửa file code, chỉ xóa conversation context trong bộ nhớ phiên hiện tại; không thể undo)
> **Nói nôm na:** `/clear` là nút "reset não" của Claude Code: xóa toàn bộ lịch sử hội thoại khỏi context window, giữ nguyên file trên đĩa, giữ nguyên CLAUDE.md / memory, và cho bạn một phiên trắng để bắt đầu task mới.

## Khi nào dùng

- Dùng `/clear` khi bạn cần reset não cho một task hoàn toàn mới và không muốn kéo rác hội thoại cũ sang.
- Dùng `/clear` **trước khi** đổi hẳn chủ đề — xóa sớm rẻ hơn để model trộn hai task vào nhau.
- Không dùng `/clear` như cách "dọn code" — nó chỉ xóa trí nhớ hội thoại trong phiên, file trên đĩa giữ nguyên.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Context về gần 0: model không còn nhớ hội thoại cũ; file trên đĩa và `CLAUDE.md`/memory giữ nguyên.
- Prompt ngay sau `/clear` là turn đầu của phiên trắng.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/clear` xong model vẫn "nhớ" chuyện cũ | Nhớ từ `CLAUDE.md` / memory file, không phải từ conversation | Sửa `CLAUDE.md` / `~/.claude/CLAUDE.md`, không phải lỗi clear |
| Gõ `/clear` báo `unknown command` | Bản CLI quá cũ hoặc gõ trong `--print` non-interactive | Update `npm i -g @anthropic-ai/claude-code`, hoặc mỗi lần gọi CLI đã là session mới nên không cần clear |
| Clear xong `/resume` vẫn thấy đoạn cũ | Transcript `.jsonl` vẫn lưu, resume đọc từ đĩa | Đúng hành vi; muốn quên hẳn thì không resume session đó nữa, bắt session mới |

> **Cách đọc bảng này:** thấy hiện tượng lạ ở cột **Triệu chứng** thì nhìn sang **Vì sao** để hiểu nguyên nhân, rồi áp **Cách sửa** — cả 3 dòng đều là "clear không sạch như tưởng".

## Tham khảo

- [../compact/README.md](../../session-context/compact/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _đổi hẳn task thì `/clear`; còn cùng task mà phình thì `/compact` — đừng để rác task cũ trộn sang việc mới._

> **Tóm gọn 1 câu:** `/clear` là nút reset não — xóa trí nhớ hội thoại cho task mới tinh tươm, còn file và cấu hình vẫn nằm nguyên trên đĩa.
