# /knowledge-system — nhóm 16 lệnh tra cứu, chẩn đoán và mở rộng hệ thống

> **Loại:** index nhóm lệnh · **Nhóm:** Tri thức & Hệ thống · **Mức rủi ro:** trung bình (đụng config: hooks, MCP, plugin, skill)
> **Nói nôm na:** nhóm này là nơi Claude "khám bệnh, mở rộng sức mạnh" — agents, MCP, hooks, skills, debug, doctor. Lệnh /hooks, /mcp, /plugin cấu hình ẩu làm mọi lệnh khác chạy sai, nên coi rủi ro là thật.

## Khi nào dùng

- Bạn muốn mở rộng sức mạnh Claude: cắm tool ngoài bằng /mcp, chạy subagent song song bằng /agents, biến rule hay quên thành luật cứng bằng /hooks.
- Bạn gặp lỗi lạ (treo, chậm, trả lời vô lý) và cần "khám tổng" bằng /doctor, /debug — không tự đoán.
- Bạn muốn dọn hệ thống tri thức: CLAUDE.md phình, skill ế, plugin lỗi — dùng /skill-doctor, /plugin-validate, /simplify.

## Cách gọi

```bash
# go / trong session, go chu dau lenh de loc
/mcp
/hooks
/doctor
```

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn thấy session chạy chậm / trả lời lạ, không rõ vì sao:

```bash
/doctor
```

- Mong đợi: /doctor audit repo — CLAUDE.md, permissions, MCP, hooks, plugin; báo từng mục đạt/chưa + gợi ý sửa.
- Kiểm tra (≤30 giây): đọc output, đếm số mục "cảnh báo"; sửa rồi /doctor lại, thấy số cảnh báo giảm.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Skill không load, /skill-doctor báo "chết lâm sàng" | Skill cũ, mất body, hoặc không ai dùng (vẫn tốn context mọi turn) | Đọc output /skill-doctor, xóa skill ế, tách checklist dài khỏi CLAUDE.md sang skill |
| MCP "disconnected" — tool ngoài không hiện, gọi tool báo lỗi | Cấu hình MCP sai, server không chạy, hoặc >~10 tool hiển thị | Gõ /mcp xem trạng thái, tắt server thừa, chạy lại; /doctor mục MCP |
| CLAUDE.md phình tốn token mỗi turn, hoặc plugin lỗi làm lệnh chạy sai | CLAUDE.md nạp lại mọi turn (phình >200 dòng); plugin/mod không audit | Trim CLAUDE.md <200 dòng, audit bằng /plugin-validate trước khi cài plugin |

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
# 1. Hoc 3 lenh tru truoc (xem "Bo 3 phai nho" o tren)
# 2. Con lai tra khi gap viec that, dung hoc het 1 luc
# 3. Loi la trong nhom nay -> /status -> /doctor -> doc lenh tuong ung
```

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm model-mode](../model-mode/README.md) · [Nhóm code-repo](../code-repo/README.md) · [Nhóm session-context](../session-context/README.md)

> Mẹo 1 dòng: _lỗi lạ thì /doctor trước, đừng đoán — nó audit CLAUDE.md, MCP, hooks, plugin một lần._
