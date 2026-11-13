# /permissions — Quản lý quyền tools: ai được đọc/ghi/chạy gì, hỏi khi nào

> Loại Built-in (alias /allowed-tools) · Nhóm Model & Mode · Mức rủi ro Có nếu cấu hình ẩu (allow-all / bypass trên máy thật = mất phanh; deny sai = kẹt việc)
>
> **Nói nôm na:** `/permissions` (alias `/allowed-tools`) là trung tâm phân quyền: quy định tool nào được chạy thẳng (allow), tool nào phải hỏi (ask), tool nào cấm hẳn (deny). Mọi mode Shift+Tab (default/acceptEdits/plan/auto/bypass) thực chất chỉ là preset đè lên bảng này. Hiểu bảng này là hiểu phanh của Claude Code.

## Khi nào dùng

- Dùng /permissions khi cần định hình allow/ask/deny — tool nào chạy thẳng, tool nào phải hỏi, tool nào cấm hẳn.
- Dùng /permissions **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /permissions thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.json`](examples/03-vi-du-that-ket-qua-mong-oi-cach.json)

Kết quả mong đợi:

- Bảng allow/ask/deny được cập nhật; tool đã allow chạy thẳng, không hỏi lại.
- Mọi mode Shift+Tab (default/acceptEdits/plan/auto/bypass) chỉ là preset đè lên bảng này.

**Kiểm tra nhanh:**

> 📄 **Code ví dụ:** [`examples/04-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/04-vi-du-that-ket-qua-mong-oi-cach.sh)

> **Tóm gọn 1 câu:** `/permissions` là bảng phanh-ga của Claude Code: allow là ga tự do, ask là phanh hỏi ý, deny là khóa số — mọi mode Shift+Tab chỉ là các preset bấm sẵn trên bảng này.

## Lỗi thường gặp

Bảng dưới là những lần "phanh gãy" hay "kẹt ga" hay gặp — đối chiếu triệu chứng của bạn với cột đầu rồi sửa theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Model báo `permission denied` khi chạy test | Thiếu allow `Bash(pytest/npm test:*)` | Thêm vào `settings.local.json` allow |
| Thêm allow ở local mà vẫn bị chặn | Managed policy deny ở trên (ổ khóa 🔒) | Không vượt được — ticket IT hoặc đi đường vòng an toàn |
| Bị hỏi Yes/No liên tục, mỏi tay | Bảng ask quá rộng / đang ở default với task lặp | Shift+Tab sang `acceptEdits`, hoặc allow các lệnh lặp |

> **Cách đọc bảng này:** mỗi dòng là một tình huống quyền bị bó hoặc lỏng quá; cột "Vì sao" cho biết rào chắn nằm ở allow, ở managed policy hay ở mode đang bật, cột "Cách sửa" là thao tác chỉnh bảng phanh cụ thể.

## Tham khảo

- [../plan/README.md](../../model-mode/plan/README.md)
- [../model/README.md](../../model-mode/model/README.md)
- [../effort/README.md](../../model-mode/effort/README.md)
- [../init/README.md](../../code-repo/init/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /permissions sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
