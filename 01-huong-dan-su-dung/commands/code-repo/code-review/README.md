# /code-review — skill review bằng subagent mới (fresh eyes) soi diff/PR

> Loại Skill/Workflow · Nhóm Code & Repo · Mức rủi ro Không
> **Nói nôm na:** `/code-review` là skill gọi 1 subagent hoàn toàn mới (không biết lịch sử chat, không bênh code cũ) để soi diff hoặc PR: đọc từng hunk, check bug/logic/bảo mật/test, trả báo cáo critical/high/low. Cứ coi như mời một reviewer khách: chưa nghe ai chèo kéo, nên chỉ nhìn code nói lên điều gì thì phán điều đó.

## Khi nào dùng

- Dùng `/code-review` khi cần "mắt mới": một subagent không biết lịch sử chat, soi diff/PR như người ngoài cuộc.
- Chạy **trước khi mở PR** hoặc trước khi nhận một thay đổi lớn, để bắt bug/logic/bảo mật sớm.
- Không dùng nó thay cho `/verify`: review chỉ đọc và nhận xét, không build chạy thật.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Báo cáo gom theo mức critical/high/low, mỗi mục có file:dòng cụ thể.
- Không sửa code (chỉ đọc + nhận xét).

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này nói về các trục trặc hay gặp khi chạy review — tra đúng triệu chứng rồi làm theo cột "Cách sửa".

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/code-review` báo `skill not found` | Bản cũ chưa có skills, hoặc skill chưa cài | Update CLI; kiểm tra `/skills` list; dùng `gh pr diff \| claude --print` thủ công |
| Review PR báo `gh: not authenticated` | Chưa `gh auth login` | `gh auth login` rồi chạy lại |
| Báo cáo chung chung, không có file:dòng | Diff quá lớn (>2000 dòng) hoặc effort thấp | Chia PR nhỏ; `/effort high`; chỉ định thư mục cụ thể |

> **Cách đọc bảng này:** đọc theo hàng — "Triệu chứng" là thông báo/chất lượng bạn nhận được, "Vì sao" chỉ nguyên nhân (bản CLI, auth, diff to), "Cách sửa" là việc cần làm.

> **Tóm gọn 1 câu:** `/code-review` là mắt mới không bênh ai — mời vào soi trước khi mở PR để bug bị chặn ở cửa, chứ không lọt ra tay người dùng.

## Tham khảo

- [../review/README.md](../../code-repo/review/README.md)
- [../ultrareview/README.md](../../code-repo/ultrareview/README.md)
- [../diff/README.md](../../code-repo/diff/README.md)
- [../verify/README.md](../../code-repo/verify/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/code-review` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
