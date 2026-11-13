# /pr-comments — xử lý comment review PR: kéo về, sửa từng cái, resolve

> [!WARNING]
> **Đã gỡ trong v2.1.91** — lệnh `/pr-comments` không còn tồn tại trong Claude Code. Thay vào đó, hãy hỏi trực tiếp Claude để xem PR comments (không cần lệnh chuyên dụng). Trang này giữ lại để tham khảo cách workflow PR review từng hoạt động.

> Loại Built-in (đã gỡ v2.1.91) · Nhóm Tri thức & Hệ thống · Mức rủi ro Không
> **Nói nôm na:** `/pr-comments` từng kéo toàn bộ review comments của 1 PR về local, liệt kê từng thread, cùng bạn sửa từng cái rồi resolve/reply hàng loạt. Cần MCP GitHub hoặc `gh` CLI. Từ v2.1.91 lệnh đã bị gỡ.

## Khi nào dùng

- *(Lịch sử)* Dùng `/pr-comments` khi PR của bạn có nhiều comment review cần xử lý từng cái rồi resolve — tới khi bị gỡ ở v2.1.91.
- **Hiện tại:** để xử lý PR comments, hãy hỏi trực tiếp Claude (vd: "đọc các unresolved comments của PR này và sửa giúp tôi").
- Không dùng nó thay cho việc tự hiểu góp ý: nó kéo thread về và hỗ trợ sửa, quyết định vẫn ở bạn.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Kéo về đủ thread, gom theo file, kèm trạng thái resolved/unresolved.
- Sửa xong có `git diff` để bạn xem trước khi push và resolve hàng loạt.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/pr-comments`: các trục trặc hay gặp khi kéo và xử lý comment PR, kèm cách xử lý ngay.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Không kéo được comments | Chưa login `gh` / MCP github auth expired | `gh auth login` hoặc `/mcp reconnect github` |
| Hiện PR sai | Nhánh local không link PR nào | Truyền số rõ `/pr-comments 248` |
| Fix xong test fail | Sửa 1 chỗ vỡ chỗ khác | Chạy test file đó ngay sau mỗi fix, đừng dồn cuối |

> **Cách đọc bảng này:** cột "Triệu chứng" là dấu hiệu bạn thấy, "Vì sao" giải thích gốc rễ, "Cách sửa" là lệnh/bước áp dụng được ngay.

> **Tóm gọn 1 câu:** `/pr-comments` đã bị gỡ từ v2.1.91 — nhưng quy trình vẫn còn: gom góp ý review, bạn trả từng cái và dán dấu "đã xử lý" thông qua việc hỏi trực tiếp Claude thay vì một lệnh chuyên dụng.

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../../knowledge-system/agents/README.md](../../knowledge-system/agents/README.md)
- [../../knowledge-system/mcp/README.md](../../knowledge-system/mcp/README.md)
- [../../knowledge-system/plugin/README.md](../../knowledge-system/plugin/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/pr-comments` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
