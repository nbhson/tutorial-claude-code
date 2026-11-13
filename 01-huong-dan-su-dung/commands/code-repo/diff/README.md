# /diff — xem diff tương tác: model sửa gì, từng dòng, duyệt trước khi nhận

> Loại Built-in · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/diff` mở interactive diff viewer: liệt kê mọi file model vừa sửa, từng hunk thêm/xóa, cho bạn duyệt/chỉnh/revert trước khi nhận. Không có `/diff` sau bước code = nhận hàng mù. Cứ coi như kiểm hàng trước khi ký nhận: từng món model làm đều bày ra bàn, đồng ý món nào mới nhận món đó.

## Khi nào dùng

- Dùng `/diff` ngay sau mỗi bước model sửa code, để thấy từng hunk thêm/xóa trước khi nhận.
- Mở `/diff` **sau mỗi bước nhỏ** — càng để nhiều bước mới xem càng khó tìm thủ phạm.
- Không dùng `/diff` thay cho việc bạn hiểu thay đổi: nó chỉ hiện cái đã đổi, việc đánh giá đúng/sai là của bạn.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Panel diff hiện từng hunk; bạn chọn giữ hay bỏ từng phần.
- Không thay đổi nào bị nhận mà bạn chưa nhìn thấy.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các tình huống `/diff` hiển thị không như bạn mong — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/diff` trống dù model bảo đã sửa | Sửa ở worktree khác (`/batch`) hoặc file chưa flush | Kiểm tra worktree path; bảo model paste đường dẫn tuyệt đối |
| Diff quá lớn (50 file) đọc nản | Task quá to, model sửa lan | Bảo "tóm tắt 10 bullet + chỉ hiện file quan trọng"; chia task nhỏ |
| `/diff` hiện cả file bạn sửa tay | Gộp chung thay đổi người + model | Dùng `git diff` tay để phân biệt, hoặc commit phần bạn trước |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng trên panel, "Vì sao" chỉ nguyên nhân (worktree khác, task to, thay đổi lẫn lộn), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/diff` là bàn kiểm hàng trước khi ký nhận: mỗi hunk model sửa đều bày ra để bạn duyệt — không nhận món nào mù.

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../code-review/README.md](../../code-repo/code-review/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/diff` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
