# /knowledge-system — nhóm 16 lệnh tra cứu, chẩn đoán và mở rộng hệ thống

> **Loại:** index nhóm lệnh · **Nhóm:** Tri thức & Hệ thống · **Mức rủi ro:** trung bình (đụng config: hooks, MCP, plugin, skill)
> **Nói nôm na:** nhóm này là nơi Claude "khám bệnh, mở rộng sức mạnh" — agents, MCP, hooks, skills, debug, doctor. Lệnh /hooks, /mcp, /plugin cấu hình ẩu làm mọi lệnh khác chạy sai, nên coi rủi ro là thật.

## Khi nào dùng

- Bạn muốn mở rộng sức mạnh Claude: cắm tool ngoài bằng /mcp, chạy subagent song song bằng /agents, biến rule hay quên thành luật cứng bằng /hooks.
- Bạn gặp lỗi lạ (treo, chậm, trả lời vô lý) và cần "khám tổng" bằng /doctor, /debug — không tự đoán.
- Bạn muốn dọn hệ thống tri thức: CLAUDE.md phình, skill ế, plugin lỗi — dùng /skill-doctor, /plugin-validate, /simplify.

> **Tóm gọn 1 câu:** Nhóm này là "bệnh viện + xưởng nâng cấp" cho Claude Code: khám bệnh (/doctor, /debug), cắm tay robot (/mcp, /hooks, /agents), và dọn kho tri thức (/skill-doctor, /simplify).

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

Kiểm tra lệnh có ở máy bạn không: mở session, gõ `/` rồi gõ tiếp chữ đầu lệnh — version/provider khác nhau hiện lệnh khác nhau.

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Bạn thấy session chạy chậm / trả lời lạ, không rõ vì sao:

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

- Mong đợi: /doctor audit repo — CLAUDE.md, permissions, MCP, hooks, plugin; báo từng mục đạt/chưa + gợi ý sửa.
- Kiểm tra (≤30 giây): đọc output, đếm số mục "cảnh báo"; sửa rồi /doctor lại, thấy số cảnh báo giảm.

> **Tóm gọn 1 câu:** ĐAU thì /doctor khám tổng trước, đừng tự bấm huyệt mò: một lệnh quét cả CLAUDE.md, permissions, MCP, hooks, plugin rồi sửa theo từng cảnh báo nó in ra.

## Lỗi thường gặp

Mục này là sổ khám bệnh của nhóm lệnh: ba bệnh hay gặp nhất khi cấu hình hooks/MCP/plugin/skill sai cách — đối chiếu triệu chứng của bạn với cột đầu, rồi làm theo cột cuối.

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Skill không load, /skill-doctor báo "chết lâm sàng" | Skill cũ, mất body, hoặc không ai dùng (vẫn tốn context mọi turn) | Đọc output /skill-doctor, xóa skill ế, tách checklist dài khỏi CLAUDE.md sang skill |
| MCP "disconnected" — tool ngoài không hiện, gọi tool báo lỗi | Cấu hình MCP sai, server không chạy, hoặc >~10 tool hiển thị | Gõ /mcp xem trạng thái, tắt server thừa, chạy lại; /doctor mục MCP |
| CLAUDE.md phình tốn token mỗi turn, hoặc plugin lỗi làm lệnh chạy sai | CLAUDE.md nạp lại mọi turn (phình >200 dòng); plugin/mod không audit | Trim CLAUDE.md <200 dòng, audit bằng /plugin-validate trước khi cài plugin |

> **Cách đọc bảng này:** mỗi dòng là một "bệnh" của hệ thống tri thức; cột "Vì sao" cho biết bệnh nằm ở skill, ở MCP hay ở CLAUDE.md/plugin, cột "Cách sửa" là lệnh/thao tác chữa cụ thể.

## Bộ 3 phải nhớ

> /mcp cắm tools ngoài | /hooks biến rule hay quên thành luật cứng | /doctor khám tổng khi lỗi lạ

## Các lệnh (16)

Bảng dưới liệt kê 16 lệnh trong nhóm — liếc cột **Mức rủi ro** trước khi gõ, rồi bấm vào tên lệnh để xem chi tiết. Giống danh bạ điện thoại: mỗi dòng một "người phụ trách", biết ai phụ trách việc gì là bấm đúng số ngay lần đầu.

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

> **Cách đọc bảng này:** xếp theo tên lệnh A→Z; cột "Mức rủi ro" là đèn giao thông (Không = chạy thẳng, Có = dừng đọc cấu hình trước), cột "Một dòng" đủ để quyết định có mở trang chi tiết hay không — cần chi tiết mới bấm vào tên lệnh.

## Sơ đồ quyết định (30 giây)

```text
Cần gì? -> Nhóm này cho gì? -> Lệnh nào?
Đọc 3 lệnh trong "Bộ 3" trước, còn lại tra khi cần.
Gõ / trong session để xem lệnh nào hiện ở máy bạn.
```

## Cách dùng nhóm này cho đúng

> 📄 **Code ví dụ:** [`examples/03-cach-dung-nhom-nay-cho-ung.sh`](examples/03-cach-dung-nhom-nay-cho-ung.sh)

## Tham khảo

- [← Về index tất cả lệnh](../README.md)
- [04 — slash commands toàn tập](../../04-slash-commands-toan-tap.md)
- [Nhóm model-mode](../model-mode/README.md) · [Nhóm code-repo](../code-repo/README.md) · [Nhóm session-context](../session-context/README.md)

> Mẹo 1 dòng: _lỗi lạ thì /doctor trước, đừng đoán — nó audit CLAUDE.md, MCP, hooks, plugin một lần._
