# /memory — Quản lý bộ nhớ dài hạn: xem/sửa/xoá những gì Claude nhớ giữa các session

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (nhưng Có nếu lưu secret/API key vào memory — sẽ bị nạp lại mọi session sau)
> **Nói nôm na:** `/memory` mở trình quản lý bộ nhớ dài hạn (long-term memory): những sự thật, sở thích, quy ước dự án mà Claude tự ghi nhớ hoặc bạn dạy thủ công, để session sau tự động nạp lại mà không cần nhắc lại. Hiểu `/memory` là hiểu "não dài hạn" của Claude Code — khác với CLAUDE.md (file tĩnh trong repo) và khác context ngắn hạn (mất khi `/clear`).

## Khi nào dùng

- Dùng khi muốn Claude nhớ sở thích/quy ước dự án qua nhiều session.
- Dùng **trước khi** lặp lại hướng dẫn mỗi session: dạy 1 lần vào memory.
- Không dùng thay CLAUDE.md: memory là não dài hạn cá nhân, CLAUDE.md là file tĩnh trong repo.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Mục được lưu đúng scope (user/project) và nạp lại session sau.
- Không lưu secret — nhớ dai sẽ nạp lại mọi session.

**Kiểm tra nhanh:** `/memory show` thấy mục vừa thêm; hoặc mở session mới xem model có nhớ không.

> **Tóm gọn 1 câu:** `/memory` là cuốn sổ tay dai nhớ của Claude: dạy 1 lần, session sau tự nạp lại — chỉ nhớ điều ổn định, đừng ghi secret vào sổ vì nó đọc lại mỗi ngày.

## Lỗi thường gặp

Bảng dưới là những lần "sổ tay trục trặc" hay gặp nhất — nhìn cột triệu chứng trước, làm theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Dạy rồi mà session sau model quên | Lưu vào project memory repo A, đang mở repo B | Kiểm tra scope: chuyển mục đó sang user memory để theo mọi repo |
| Model cứ hỏi "có lưu không?" gây phiền | Auto-memory nhạy quá | Tắt đề xuất trong settings, chỉ thêm tay bằng `/memory add` |
| `/memory` báo empty dù đã dạy | Dạy trong session chưa duyệt Yes, hoặc nhầm profile `~/.claude` | Mở lại `/memory`, kiểm tra; đảm bảo đã bấm Yes khi model hỏi |

> **Cách đọc bảng này:** mỗi dòng là một tình huống "dạy rồi mà không nhớ"; cột "Vì sao" giải thích gốc rễ, "Cách sửa" là thao tác làm được ngay trong `/memory`.

## Tham khảo

- [../rules/README.md](../../knowledge-system/rules/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chỉ lưu sở thích ổn định; việc nhất thời để context, đừng nhét vào memory._
