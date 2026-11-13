# /init — quét codebase, sinh CLAUDE.md + settings chuẩn cho repo mới

> Loại Built-in · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/init` là "lễ nhập trạch" cho repo: Claude Code quét toàn bộ codebase rồi sinh `CLAUDE.md` (luật dự án: lệnh build/test, convention, việc cấm) + gợi ý `settings.json` baseline.

## Khi nào dùng

- Dùng `/init` ở repo chưa có `CLAUDE.md`, hoặc khi file cũ đã lệch hẳn so với code hiện tại.
- Chạy `/init` **ngay đầu dự án**, trước khi nhét thêm quy tắc thủ công — để máy tự điền phần nó đọc được từ code.
- Không dùng `/init` thay cho việc tự đọc code: nó chỉ tổng hợp những gì có trong repo, phần "việc cấm" bạn vẫn phải duyệt tay.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Sinh `CLAUDE.md` ngắn gọn dưới 200 dòng, có mục lệnh dev/build/test, cấu trúc thư mục và vài việc cấm.
- Claude liệt kê rõ file sẽ tạo trước khi ghi, để bạn duyệt chứ không tự ý đè file cũ.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các tình huống `/init` sinh kết quả chưa đúng — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/init` sinh lệnh test sai (`npm test` trong khi dùng pnpm) | Đoán sai package manager | Sửa tay CLAUDE.md 1 dòng; lần sau `/init` kèm gợi ý rõ package manager |
| CLAUDE.md quá dài (>200 dòng) | Repo lớn + verbose | Bảo "rút gọn còn 60 dòng, chỉ giữ lệnh + cấm + cấu trúc" |
| Init ở nhầm thư mục (sinh CLAUDE.md ở `~/`) | Quên `cd` vào repo | Xóa file nhầm, `cd` đúng repo, `/init` lại |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là kết quả bạn nhận được, "Vì sao" chỉ nguyên nhân (đoán sai, repo lớn, sai thư mục), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/init` là lễ nhập trạch của repo: quét một lượt, lập nhà luật CLAUDE.md — nhưng phần "việc cấm" bạn vẫn phải duyệt tay chứ máy không biết tự cấm.

## Tham khảo

- [../../model-mode/permissions/README.md](../../model-mode/permissions/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)
- [../../model-mode/model/README.md](../../model-mode/model/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/init` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
