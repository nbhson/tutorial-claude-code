# FAQ 08 — Lỗi Thường Gặp & Troubleshooting

| Triệu chứng | Check → Fix |
|---|---|
| `Unknown command: /cd` (hoặc lệnh mới vắng) | `/status` version cũ → `claude update` (và check provider có hỗ trợ lệnh đó không) |
| Hook không chạy | `/hooks`: đúng event? matcher case? folder trusted? (xem FAQ 05) |
| MCP disconnected | `/mcp reconnect <name>`; token/URL/OAuth (xem FAQ 04) |
| Permission deny liên tục | `/permissions` xem merged rules + auto-mode denials; pre-approve read-only hay dùng |
| Context đầy, Claude quên rule | `/context` → `/compact [focus]` hoặc `/clear` + paste plan; tách phase |
| Claude đọc hàng trăm file | Scope hẹp lại / ném sang subagent; dặn "chỉ files mày sẽ sửa/đọc" |
| Sửa 2 lần vẫn sai | Dừng argue → double-Esc rewind → re-prompt sạch |
| Reviewer dễ dãi/khắt khe | Calibration 3 diffs lịch sử; định nghĩa finding explicit (bỏ qua style) |
| Flaky test đoán sai | Dặn "flaky thì ghi flaky, dừng đoán"; human verify failures thật |
| 2 bản Claude xung đột / PATH lỗi / settings parse lỗi | `claude doctor` → gỡ bản thừa, sửa JSON |
| Cloud thiếu config local | Cấu hình lại MCP/vars/setup script trong cloud environment |
| Muốn gửi bug | `/bug` + `/status` + `claude doctor` output |

Thứ tự debug chuẩn: `/status → claude doctor → /context+/cost+/usage → /hooks+/mcp+/permissions → /debug → /bug`.
