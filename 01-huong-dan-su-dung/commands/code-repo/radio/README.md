# /radio — kênh dev trực tiếp: hỏi-đáp nhanh, tính khả dụng hạn chế theo provider

> Loại Built-in (version-gated) · Nhóm Session/Realtime · Mức rủi ro Thấp
> **Nói nôm na:** `/radio` mở kênh realtime với Claude trong session: hỏi nhanh, nghe giải thích, brainstorm mà không phá mạch code chính. History chính vẫn sạch.

## Khi nào dùng

- Dùng `/radio` khi bạn muốn một "kênh phụ" hỏi-đáp realtime, brainstorm phương án mà không chèn vào transcript chính.
- Bật `/radio` **trước khi** task phình to: gom câu hỏi nhỏ vào kênh này thay vì rải nhiều turn chính.
- Không dùng `/radio` để chốt thiết kế cuối: nó là kênh trao đổi, mọi quyết định vẫn nên ghi lại ở luồng chính.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

**Kết quả mong đợi:**

- Có phản hồi ngay trong kênh radio; transcript chính vẫn gọn.
- Bạn chủ động `/radio off` để đóng kênh khi trao đổi xong.

**Verify (30 giây):**

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `/radio`: các trục trặc khi mở kênh hỏi-đáp realtime và cách xử lý nhanh.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `unknown command: /radio` | Bản cũ hoặc provider không hỗ trợ | Update mới nhất; gõ `/` kiểm tra; vắng thì dùng `/btw` |
| Hỏi mà trả lời chung chung | Câu hỏi quá rộng | Hẹp scope: 1 file/1 luồng/1 quyết định |
| Transcript voice sai từ khóa | Mic/tiếng ồn | Gõ lại từ khóa (tên file/hàm) bằng text |

> **Cách đọc bảng này:** tra theo cột "Triệu chứng" trước, rồi đọc sang "Vì sao" và "Cách sửa" — mỗi dòng là một tình huống xử lý xong trong 1–2 phút.

> **Tóm gọn 1 câu:** `/radio` là tai nghe đàm thoại rời trong lúc tay vẫn đang code — hỏi nhanh trên kênh phụ, tắt đi thì luồng chính vẫn nguyên vẹn.

## Tham khảo

- [../btw/README.md](../../code-repo/btw/README.md)
- [../../session-context/fork/README.md](../../session-context/fork/README.md)
- [../../model-mode/plan/README.md](../../model-mode/plan/README.md)
- [../../session-context/export/README.md](../../session-context/export/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/radio` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
