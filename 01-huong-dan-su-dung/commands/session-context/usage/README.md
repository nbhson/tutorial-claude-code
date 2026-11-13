# /usage — Phân bổ token: skill, subagent, plugin, MCP nào đốt nhiều nhất + quota còn bao nhiêu

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (chỉ đọc thống kê, không xóa/sửa gì)
> **Nói nôm na:** `/usage` là "camera giám sát chi tiết": không chỉ cho biết tốn bao nhiêu (như `/cost`), mà cho biết **tốn vào việc gì** — skill nào, subagent nào, plugin nào, MCP server nào — kèm rate limits / quota còn lại.

## Khi nào dùng

- Dùng `/usage` khi bạn muốn biết token/quota bị đốt vào skill, subagent, plugin hay MCP nào.
- Dùng `/usage` sau một việc tốn kém (Explore cả repo) để tìm chỗ tối ưu cho lần sau.
- Không dùng `/usage` như hoá đơn tiền — nó nghiêng về phân bổ và rate limit, tiền thì xem `/cost`/dashboard.

## Cách gọi

> 📄 **Code ví dụ:** [`examples/01-cach-goi.sh`](examples/01-cach-goi.sh)

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

> 📄 **Code ví dụ:** [`examples/02-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/02-vi-du-that-ket-qua-mong-oi-cach.sh)

Kết quả mong đợi:

- Bảng phân bổ token theo skill/subagent/plugin/MCP, kèm rate limit/quota còn lại.
- Chỉ ra chỗ đốt token để lần sau hỏi hẹp hơn.

Verify (30 giây):

> 📄 **Code ví dụ:** [`examples/03-vi-du-that-ket-qua-mong-oi-cach.sh`](examples/03-vi-du-that-ket-qua-mong-oi-cach.sh)

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/usage` trống / chỉ có tổng | Bản CLI cũ chưa có bảng phân bổ theo MCP | Update `npm i -g @anthropic-ai/claude-code` |
| Rate limits trống khi dùng API key | Pay-as-you-go không có quota 5h/weekly kiểu subscription | Đúng hành vi; xem dashboard billing thay vì quota |
| Subagent tên lạ ngốn nhiều | Plugin/agent-teams tự spawn agent phụ | Xem bài subagents/agent-teams để nhận diện; tắt plugin nếu không cần |

> **Cách đọc bảng này:** mỗi dòng là một kiểu "bảng usage trống hoặc lạ" — **Vì sao** cho biết đó là hạn chế của bản CLI hay hành vi đúng, **Cách sửa** là cách cập nhật hoặc truy nguồn khác.

## Tham khảo

- [../cost/README.md](../../session-context/cost/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _thấy Explore đọc cả repo thì siết phạm vi ("chỉ src/payments/, tối đa 10 file") — `/usage` lần sau sẽ nhẹ hơn._

> **Tóm gọn 1 câu:** `/usage` là camera an ninh chi tiêu: không chỉ nói tốn bao nhiêu mà chỉ luôn tốn vào việc gì — Skill, subagent, plugin hay MCP nào.
