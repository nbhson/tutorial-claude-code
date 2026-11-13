# /plan — Chế độ lập kế hoạch: chỉ đọc + viết plan, cấm sửa code cho tới khi duyệt

> Loại Built-in · Nhóm Model & Mode · Mức rủi ro Không (bản thân plan mode an toàn — cấm ghi/sửa file; nguy hiểm chỉ khi bạn duyệt plan ẩu rồi cho chạy bypass sau đó)
>
> **Nói nôm na:** `/plan` (và mode `plan` trong vòng xoay Shift+Tab) khóa Claude Code ở trạng thái "chỉ được nhìn, không được chạm": đọc file, search, vẽ kiến trúc, viết plan từng bước — nhưng mọi Edit/Write/Bash ghi đều bị chặn. Bạn duyệt plan rồi mới cho thực thi. Đây là phanh an toàn số 1 cho task lớn.

## Khi nào dùng

- Dùng /plan trước task lớn để khóa ghi: chỉ đọc + vạch plan, duyệt xong mới cho sửa code.
- Dùng /plan **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /plan thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Claude chỉ đọc file, search, vẽ kiến trúc và trả plan từng bước — mọi Edit/Write/Bash ghi đều bị chặn.
- Bạn duyệt plan xong mới cho thực thi; đổi sang mode khác bằng Shift+Tab khi cần ghi.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

> **Tóm gọn 1 câu:** `/plan` là phòng vẽ bản đồ trước khi phá tường: chỉ xem, chỉ vẽ kế hoạch, chìa khóa sửa code bị thu hồi đến khi bạn duyệt — muốn động tay thì mở khóa bằng Shift+Tab.

## Lỗi thường gặp

Bảng dưới là những lúc "phòng vẽ bản đồ" không khóa như bạn tưởng — đối chiếu triệu chứng với cột đầu rồi xử theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/plan` xong model vẫn sửa file | Chưa thật sự ở plan mode (mới gõ text, chưa Enter lệnh) | Kiểm tra status bar hiện `plan`; gõ lại `/plan` |
| Ở plan nhưng cần ghi 1 file plan ra đĩa | Plan chặn ghi là đúng | Bảo "hiển thị plan dạng markdown để tôi copy", hoặc tạm Shift+Tab về `acceptEdits` ghi 1 file rồi quay lại plan |
| Duyệt plan rồi model làm ẩu 10 bước | Duyệt cả cục + effort thấp | Duyệt 1–2 bước; `/effort high` cho bước khó |

> **Cách đọc bảng này:** mỗi dòng là một kiểu "lộ trình trượt"; cột "Vì sao" cho biết bạn chưa vào mode đúng, mode khóa đúng nhưng bạn cần ghi, hay duyệt ẩu — cột "Cách sửa" là bước xử lý từng loại.

## Tham khảo

- [../goal/README.md](../../model-mode/goal/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /plan sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
