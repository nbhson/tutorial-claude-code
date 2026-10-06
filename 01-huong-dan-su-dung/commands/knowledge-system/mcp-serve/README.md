# /mcp-serve — Biến Claude Code thành MCP server cho app khác gọi (claude mcp serve)

> Loại CLI (`claude mcp serve`) · Nhóm MCP & Tích hợp · Nguy hiểm Trung bình (mở stdio server cho tiến trình khác gọi; restricted mode chặn background agents + remote isolation — nhưng Có nếu bạn expose tools ghi/xoá cho client lạ)

> Nói nôm na: `mcp-serve` (`claude mcp serve`) chạy Claude Code ở chế độ MCP stdio server: app khác (IDE, agent khác, script của bạn) gọi tools của Claude Code qua giao thức MCP thay vì chat. Chế độ restricted mặc định chặn background agents + cô lập remote (remote isolation) để client lạ không lái máy bạn đi lung tung. Hiểu `mcp-serve` là hiểu "lật mặt bàn: Claude Code từ người gọi tools thành người PHỤC VỤ tools".

## Khi nào dùng

- Dùng /mcp-serve khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /mcp-serve **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /mcp-serve thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`claude mcp serve`
`claude mcp serve --tools <list>`
`claude mcp serve --restricted`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Extension cần đọc file workspace qua MCP thay vì fs trực tiếp
# (để được grep thông minh + tôn trọng .gitignore):
# 1. Mở server chỉ-đọc:
claude mcp serve --tools read,grep,glob --restricted

# 2. Phía extension config MCP trỏ vào lệnh trên (.mcp.json như mẫu Dạng 5)
# 3. Test từ terminal:
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | claude mcp serve --tools read,grep,glob
```

Kết quả mong đợi:

- Claude trả đúng việc của /mcp-serve (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Client báo "tools not found" | `--tools` sai tên (viết hoa/thiếu) hoặc bản cũ chưa có tool đó | `tools/list` kiểm tra tên chính xác; update CLI cả 2 phía |
| JSON-RPC vỡ (parse error) | Log debug lẫn vào stdout | Chuyển log ra stderr/file; giữ stdout chỉ JSON |
| Background call bị từ chối | Restricted block background agents (đúng thiết kế) | Đổi client sang gọi đồng bộ; đừng tắt restricted chỉ vì lười |

## Tham khảo

- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- [../permissions/README.md](../../model-mode/permissions/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../background/README.md](../../session-context/background/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /mcp-serve sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
