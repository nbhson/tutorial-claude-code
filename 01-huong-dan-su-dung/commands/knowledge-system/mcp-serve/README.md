# /mcp-serve — Biến Claude Code thành MCP server cho app khác gọi (claude mcp serve)

> Loại CLI (`claude mcp serve`) · Nhóm MCP & Tích hợp · Mức rủi ro Trung bình (mở stdio server cho tiến trình khác gọi; restricted mode chặn background agents + remote isolation — nhưng Có nếu bạn expose tools ghi/xoá cho client lạ)
> **Nói nôm na:** `mcp-serve` (`claude mcp serve`) chạy Claude Code ở chế độ MCP stdio server: app khác (IDE, agent khác, script của bạn) gọi tools của Claude Code qua giao thức MCP thay vì chat. Chế độ restricted mặc định chặn background agents + cô lập remote (remote isolation) để client lạ không lái máy bạn đi lung tung. Từ bản ≥2.1.292, server negotiate protocol `2026-07-28`. Hiểu `mcp-serve` là hiểu "lật mặt bàn: Claude Code từ người gọi tools thành người PHỤC VỤ tools".

## Khi nào dùng

- Dùng khi app/IDE/agent khác cần gọi tool của Claude Code qua giao thức MCP thay vì chat.
- Dùng **trước khi** tự viết tích hợp riêng: `claude mcp serve` phơi sẵn tool read/grep/glob.
- Không dùng thay cấu hình bảo mật: restricted mode mặc định chặn background + cô lập remote, đừng tắt chỉ vì lười.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- `tools/list` từ client trả danh sách tool đúng; client gọi tool chạy.
- Restricted: background call bị từ chối (đúng thiết kế).

**Kiểm tra nhanh:** chạy lại lệnh `echo '...' | claude mcp serve ...` ở trên, stdout phải là JSON hợp lệ, không lẫn log.

## Lỗi thường gặp

Mục này là "sổ bệnh án" của `claude mcp serve`: client không thấy tool, JSON vỡ, call bị chặn — kèm cách xử lý từng trường hợp.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Client báo "tools not found" | `--tools` sai tên (viết hoa/thiếu) hoặc bản cũ chưa có tool đó | `tools/list` kiểm tra tên chính xác; update CLI cả 2 phía |
| JSON-RPC vỡ (parse error) | Log debug lẫn vào stdout | Chuyển log ra stderr/file; giữ stdout chỉ JSON |
| Background call bị từ chối | Restricted block background agents (đúng thiết kế) | Đổi client sang gọi đồng bộ; đừng tắt restricted chỉ vì lười |

> **Cách đọc bảng này:** "Triệu chứng" là phía client báo, "Vì sao" thường nằm ở tên tool, stdout/stderr hoặc restricted mode, "Cách sửa" là thao tác cụ thể cả 2 phía.

> **Tóm gọn 1 câu:** `claude mcp serve` là lật Claude Code từ khách gọi đồ thành bếp phục vụ đồ — ai gọi cũng được nhưng cửa hậu (background) vẫn khoá chặt.

## Tham khảo

- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../background/README.md](../../session-context/background/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _giữ stdout chỉ JSON, đẩy log ra stderr — trộn là vỡ JSON-RPC._
