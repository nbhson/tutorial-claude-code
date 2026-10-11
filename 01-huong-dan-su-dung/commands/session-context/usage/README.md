# /usage — Phân bổ token: skill, subagent, plugin, MCP nào đốt nhiều nhất + quota còn bao nhiêu

> **Loại:** Built-in · **Nhóm:** Session & Context · **Mức rủi ro:** Không (chỉ đọc thống kê, không xóa/sửa gì)
> **Nói nôm na:** `/usage` là "camera giám sát chi tiết": không chỉ cho biết tốn bao nhiêu (như `/cost`), mà cho biết **tốn vào việc gì** — skill nào, subagent nào, plugin nào, MCP server nào — kèm rate limits / quota còn lại.

## Khi nào dùng

- Dùng `/usage` khi bạn muốn biết token/quota bị đốt vào skill, subagent, plugin hay MCP nào.
- Dùng `/usage` sau một việc tốn kém (Explore cả repo) để tìm chỗ tối ưu cho lần sau.
- Không dùng `/usage` như hoá đơn tiền — nó nghiêng về phân bổ và rate limit, tiền thì xem `/cost`/dashboard.

## Cách gọi

```bash
`/usage`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bạn bảo: "Tìm hiểu codebase giúp tôi" (quá chung chung)
/usage
# → Explore 5 runs, 500K in. Mỗi run đọc cả repo vì không biết trọng tâm.

# Fix: hỏi hẹp + giới hạn
Hãy chỉ explore thư mục src/payments/, trả về tối đa 10 file quan trọng nhất, không đọc tests.
# → /usage lần sau: Explore 1 run, 60K. Tiết kiệm 88%.
```

Kết quả mong đợi:

- Bảng phân bổ token theo skill/subagent/plugin/MCP, kèm rate limit/quota còn lại.
- Chỉ ra chỗ đốt token để lần sau hỏi hẹp hơn.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/usage` trống / chỉ có tổng | Bản CLI cũ chưa có bảng phân bổ theo MCP | Update `npm i -g @anthropic-ai/claude-code` |
| Rate limits trống khi dùng API key | Pay-as-you-go không có quota 5h/weekly kiểu subscription | Đúng hành vi; xem dashboard billing thay vì quota |
| Subagent tên lạ ngốn nhiều | Plugin/agent-teams tự spawn agent phụ | Xem bài subagents/agent-teams để nhận diện; tắt plugin nếu không cần |

## Tham khảo

- [../cost/README.md](../../session-context/cost/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _thấy Explore đọc cả repo thì siết phạm vi ("chỉ src/payments/, tối đa 10 file") — `/usage` lần sau sẽ nhẹ hơn._
