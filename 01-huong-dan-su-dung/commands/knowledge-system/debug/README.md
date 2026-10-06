# /debug — Chẩn đoán session đang bệnh: treo, chậm, trả lời lạ

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (chỉ đọc + chẩn đoán, không sửa gì — muốn sửa thì sang `/doctor --fix`)

> Nói nôm na: `/debug` bật chế độ chẩn đoán cho session HIỆN TẠI: vì sao model trả lời lạ, tool treo, context đầy nhanh, MCP rớt... Nó thu thập log, transcript, token, latency rồi chỉ ra nghi phạm + hướng xử lý — nhưng không tự sửa (sửa là việc của bạn hoặc `/doctor`). Hiểu 1 câu: `/doctor` khám config, `/debug` khám session đang chạy, `/bug` báo lỗi tool cho Anthropic.

## Khi nào dùng

- Dùng /debug khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /debug **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /debug thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/debug`
`/debug --verbose`
`/debug transcript`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Triệu chứng: model quên chỉ thị đầu session, nói linh tinh.
/debug
# → "Context 92% — file legacy/dump.sql 40k token đang chiếm nửa."
# Nguyên nhân: bạn Read nhầm file dump vào context.

# Fix: /clear rồi làm tiếp, đừng Read file dump nữa (dùng head/Grep thay).
```

Kết quả mong đợi:

- Claude trả đúng việc của /debug (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/debug` báo unknown | Bản CLI cũ | Update CLI; thử `Ctrl+O` trong IDE |
| Verbose không hiện latency | Tool chạy local quá nhanh (<10ms) | Bình thường — chỉ tool mạng/MCP mới có latency đáng kể |
| Transcript file quá to (>50MB) | Session dài 1 tuần không clear | Dùng `rg` grep thay vì mở hết; `/clear` thường xuyên hơn |

## Tham khảo

- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../bug/README.md](../../knowledge-system/bug/README.md)
- [../mcp/README.md](../../knowledge-system/mcp/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /debug sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
