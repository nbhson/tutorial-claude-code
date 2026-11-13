# /batch — chạy song song nhiều task trong worktree tách, không đụng main

> Loại Built-in · Nhóm Song song & Ủy thác · Mức rủi ro Trung bình
> **Nói nôm na:** `/batch` tạo nhiều worktree + spawn subagent chạy song song các task độc lập (refactor A, fix test B, viết doc C). Giữ main sạch, dễ xem diff riêng. Hãy hình dung như giao mỗi thợ một gian phòng riêng: ai làm việc của mình, xong mới mang ra ghép — không ai chạm nồi của ai.

## Khi nào dùng

- Dùng `/batch` khi có ≥2 task độc lập và muốn mỗi task chạy trong worktree riêng, main branch vẫn sạch.
- Dùng khi một mạch không kịp, cần chạy song song nhiều nhánh refactor/fix/doc khác nhau.
- Không dùng `/batch` cho các task chung một file/config: chúng sẽ giẫm chân nhau rồi conflict.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Mỗi task chạy trong worktree riêng, main branch không bị đụng.
- Trả về diff/PR của từng nhánh để bạn duyệt.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các sự cố hay gặp khi chạy task song song — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Tạo worktree fail (branch đã tồn tại) | Dùng tên branch trùng | Dùng tên duy nhất hoặc `git worktree remove` nhánh cũ |
| Agent chạm nhầm file chung | Task không thật sự độc lập | Chia task rõ ràng; tránh sửa config chung cùng lúc |
| Dọn worktree quên → rác | Không dùng `--keep` rồi quên xóa | Sau khi merge, xóa worktree + branch; dùng `--keep` chỉ khi debug |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng bạn gặp, "Vì sao" chỉ gốc rễ (tên trùng, task đụng nhau, quên dọn), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/batch` là phân công theo gian phòng riêng: task nào độc lập thì nhánh riêng, main vẫn sạch — task nào đụng chung file thì đừng cho vào chung phòng.

## Tham khảo

- [../diff/README.md](../../code-repo/diff/README.md)
- [../subtask/README.md](../../code-repo/subtask/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/batch` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
