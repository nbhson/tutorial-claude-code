# /branch — Tạo nhánh thử nghiệm what-if từ conversation hiện tại

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (không xóa/sửa file; chỉ copy context sang nhánh thử nghiệm — an toàn nếu kết hợp git riêng)
> **Nói nôm na:** `/branch` giống `/fork` nhưng mang ngữ nghĩa "thử giả thuyết": tách 1 nhánh what-if để trả lời "nếu làm theo cách B thì sao?", trong khi nhánh chính vẫn đi cách A. Hãy hình dung như phòng thí nghiệm tách khỏi dây chuyền chính: làm thử thoải mái, dây chuyền chính vẫn chạy.

## Khi nào dùng

- Dùng `/branch` khi bạn muốn thử một giả thuyết "nếu làm cách B thì sao?" mà nhánh chính vẫn đi cách A.
- Dùng `/branch` cho câu hỏi what-if ngắn, chỉ đọc để có số liệu trước khi quyết định.
- Không dùng `/branch` như fork cho hướng dài — nhánh thử vẫn chung filesystem, muốn tách code phải dùng git riêng.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Có một nhánh hội thoại mới chạy giả thuyết; nhánh chính (cách A) vẫn nguyên.
- Câu trả lời của nhánh thử để lấy số liệu tham khảo, không tự động sửa file.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Nhánh thử sửa hỏng code nhánh chính | Chung filesystem | Dùng `git worktree` riêng; hoặc chỉ cho nhánh thử quyền đọc (`--permission-mode plan`) |
| Không phân biệt `/branch` và `/fork` | Ngữ nghĩa gần nhau, dễ lẫn | What-if ngắn, chỉ để lấy số liệu → `/branch`; rẽ hướng dài, muốn tách code → `/fork`. Về kỹ thuật hai lệnh gần như nhau |
| Picker đầy nhánh thử cũ | Không dọn | Đặt tên ngày + bỏ resume nhánh thua; xóa `.jsonl` nếu nhạy cảm |

> **Cách đọc bảng này:** dò cột **Triệu chứng** theo thứ bạn đang gặp, cột **Vì sao** cho biết gốc rễ, cột **Cách sửa** là việc cần làm ngay.

## Tham khảo

- [../fork/README.md](../../session-context/fork/README.md)
- [../rewind/README.md](../../session-context/rewind/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- [../rename/README.md](../../session-context/rename/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _what-if ngắn chỉ để lấy số liệu thì dùng `/branch`; rẽ hướng dài cần tách code thật thì dùng `/fork` kèm `git worktree`._

> **Tóm gọn 1 câu:** `/branch` cho bạn một căn phòng riêng để hỏi "nếu làm cách B thì sao" mà không ai đụng vào hội thoại chính.
