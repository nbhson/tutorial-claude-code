# /usage — Breakdown tiêu thụ: skill, subagent, plugin, MCP nào đốt token + quota còn bao nhiêu

> Loại Built-in · Nhóm Session & Context · Mức rủi ro Không (chỉ đọc thống kê, không xóa/sửa gì)
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

- Claude trả đúng việc của /usage (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/usage` trống / chỉ có tổng | Bản CLI cũ chưa có breakdown per-MCP | Update `npm i -g @anthropic-ai/claude-code` |
| Rate limits trống khi dùng API key | Pay-as-you-go không có quota 5h/weekly kiểu subscription | Đúng hành vi; xem dashboard billing thay vì quota |
| Subagent tên lạ ngốn nhiều | Plugin/agent-teams tự spawn agent phụ | Xem bài subagents/agent-teams để nhận diện; tắt plugin nếu không cần |

## Tham khảo

- [../cost/README.md](../../session-context/cost/README.md)
- [../context/README.md](../../session-context/context/README.md)
- [../compact/README.md](../../session-context/compact/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /usage sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
