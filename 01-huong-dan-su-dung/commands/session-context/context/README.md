# /context — Kính hiển vi context window: đang đầy bao nhiêu, nặng ở đâu

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (lệnh chỉ đọc, không xóa/sửa gì cả — an toàn tuyệt đối)
> **Nói nôm na:** `/context` mở bảng trực quan dạng lưới: cho bạn thấy context window đã dùng bao nhiêu %, nặng ở chỗ nào (system, CLAUDE.md, history, tools, MCP), để quyết định nên `/compact`, `/clear` hay cứ làm tiếp.

## Khi nào dùng

- Dùng `/context` khi Claude trả lời chậm dần và bạn muốn biết context đang nặng ở chỗ nào.
- Dùng `/context` định kỳ (30–60 phút) để quyết định `/compact`, `/clear` hay cứ làm tiếp.
- Không dùng `/context` như số billing — nó đo dung lượng hội thoại hiện tại, không phải tiền tích lũy.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Bảng cho biết context window đã dùng bao nhiêu % và nặng ở nhóm nào (system, `CLAUDE.md`, history, tools, MCP).
- Từ số đó chọn `/compact` (cùng task) hay `/clear` (đổi task) hay cứ làm tiếp.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/context` báo % khác với `/cost` | `/context` đo RAM hiện tại, `/cost` đo tổng billing tích lũy | Không phải lỗi; đọc cả 2 với ý nghĩa khác nhau |
| % vọt từ 30% lên 75% sau 1 paste | Paste file log/ảnh lớn | `/compact bỏ log` hoặc đừng paste cả file, chỉ paste đoạn cần (`read` theo dòng) |
| Grid không hiện breakdown MCP | Bản CLI cũ hoặc MCP chưa trả output nào | Update CLI; breakdown chỉ hiện nhóm có số liệu >0 |

> **Cách đọc bảng này:** mỗi dòng là một chuyện "số liệu không như bạn nghĩ" — **Vì sao** giải thích hai con số đo hai thứ khác nhau, đừng vội nghi lệnh hỏng.

## Tham khảo

- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../cost/README.md](../../session-context/cost/README.md)
- [../usage/README.md](../../session-context/usage/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _thấy trả lời chậm dần là dấu hiệu context đầy — gõ `/context` trước khi model bắt đầu quên._

> **Tóm gọn 1 câu:** `/context` là đồng hồ xăng của phiên: nhìn một cái biết bình còn bao nhiêu và nặng ở khoang nào, từ đó chọn compact, clear hay cứ chạy tiếp.
