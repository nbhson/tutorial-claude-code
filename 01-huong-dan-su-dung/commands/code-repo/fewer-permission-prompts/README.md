# /fewer-permission-prompts — quét transcripts, đề xuất allowlist read-only cho đỡ hỏi

> Loại Built-in · Nhóm Quyền & Ma sát · Mức rủi ro Thấp
> **Nói nôm na:** `/fewer-permission-prompts` (tên cũ `less-permission-prompts` ở bản v2.1.111) quét transcripts rồi đề xuất allowlist READ-ONLY để máy đỡ hỏi lặp. Nó không tự mở quyền ghi/chạy — chỉ gợi ý, bạn duyệt từng cái. Cứ coi như trợ lý ghi nhớ thói quen: "việc này anh hỏi hoài thì làm thẻ ra vào nhé" — nhưng thẻ nào bạn vẫn phải gật đầu mới có hiệu lực.

## Khi nào dùng

- Dùng `/fewer-permission-prompts` khi bạn thấy bị hỏi xin quyền lặp lại nhiều lần cho cùng loại lệnh read-only.
- Quét **sau vài ngày dùng thật** để đủ mẫu transcript — quét ngay ngày đầu sẽ ít đề xuất.
- Không dùng nó để mở quyền ghi/chạy: nó chỉ đề xuất allowlist read-only, bạn vẫn duyệt từng cái.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Danh sách đề xuất allowlist read-only kèm số lần bị hỏi, mỗi mục là một lựa chọn Yes/No.
- Không quyền ghi hay chạy nào được tự thêm vào cấu hình.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các tình huống quét/duyệt không ra kết quả như mong — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Quét báo "no patterns" dù bị hỏi nhiều | Transcripts bị xóa (`/clear` nhiều) hoặc mới dùng 1–2 ngày, chưa đủ mẫu | Dùng 1 tuần rồi quét lại; đừng clear liên tục nếu muốn máy học |
| Tên cũ chạy, tên mới không | Bản quá cũ chưa có tên mới | Update CLI; dùng tên nào máy nhận |
| Yes rồi mà vẫn hỏi y hệt | Duyệt vào scope khác (local vs project) | `/permissions` xem scope; chuyển scope đúng |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là hiện tượng bạn gặp, "Vì sao" chỉ nguyên nhân (dữ liệu, bản CLI, scope), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/fewer-permission-prompts` học từ thói quen của bạn để bớt hỏi lặp — nhưng nó chỉ đề xuất read-only, mỗi thẻ ra vào vẫn cần bạn gật đầu.

## Tham khảo

- [../../model-mode/permissions/README.md](../../model-mode/permissions/README.md)
- [../../knowledge-system/doctor/README.md](../../knowledge-system/doctor/README.md)
- [../../auth-settings/sandbox/README.md](../../auth-settings/sandbox/README.md)
- [../../auth-settings/status/README.md](../../auth-settings/status/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/fewer-permission-prompts` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
