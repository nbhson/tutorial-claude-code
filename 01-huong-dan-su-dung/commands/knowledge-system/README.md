# Nhóm: Tri thức & Hệ thống (16 lệnh)

> Tra cứu, chẩn đoán, mở rộng: agents, MCP, hooks, skills, debug, doctor.

## Bộ 3 phải nhớ

> /mcp cắm tools ngoài | /hooks biến rule hay quên thành luật cứng | /doctor khám tổng khi lỗi lạ

## Các lệnh (16)

| Lệnh | Mức rủi ro | Một dòng |
|---|---|---|
| [/agents](./agents/README.md) | Có nếu batch ẩu | Quản lý subagent chạy song song, context riêng |
| [/bug](./bug/README.md) | Có nếu ẩu | Đóng gói bug report gửi Anthropic sau khi review |
| [/claude-api](./claude-api/README.md) | Không | Migrate SDK, mẫu gọi Anthropic API, managed agents |
| [/debug](./debug/README.md) | Không | Chẩn đoán session đang bệnh: treo, chậm, trả lời lạ |
| [/doctor](./doctor/README.md) | Không | Audit repo: CLAUDE.md, permissions, MCP, hooks, plugin |
| [/hooks](./hooks/README.md) | Có | Tự động hoá việc máy kiểm được, chạy shell ngoài model |
| [/insights](./insights/README.md) | Không | Phân tích thói quen dùng, gợi ý tiết kiệm token |
| [/mcp](./mcp/README.md) | Có nếu cấu hình ẩu | Kết nối tool ngoài: database, GitHub, browser... |
| [/mcp-serve](./mcp-serve/README.md) | Trung bình | Biến Claude Code thành MCP server cho app khác |
| [/memory](./memory/README.md) | Không | Quản lý bộ nhớ dài hạn giữa các session |
| [/plugin](./plugin/README.md) | Có | Cài bundle skill + agent + hook + MCP một lần |
| [/plugin-validate](./plugin-validate/README.md) | Không | Audit plugin/mod trước khi cài |
| [/rules](./rules/README.md) | Không | Quy ước modular theo file/thư mục |
| [/simplify](./simplify/README.md) | Không | Làm code gọn hơn, giữ nguyên tính năng |
| [/skill-doctor](./skill-doctor/README.md) | Không | Báo cáo skill ngốn context / chết lâm sàng |
| [/stats](./stats/README.md) | Không | Token, chi phí, hạn mức hôm nay |

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

```bash
# 1. Học 3 lệnh trụ trước (xem "Bộ 3 phải nhớ" ở trên)
# 2. Còn lại tra khi gặp việc thật, đừng học hết 1 lúc
# 3. Lỗi lạ trong nhóm này -> /status -> /doctor -> đọc lệnh tương ứng
```

[← Về index tất cả lệnh](../README.md)
