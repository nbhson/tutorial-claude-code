# /debug — Chẩn đoán session đang bệnh: treo, chậm, trả lời lạ

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (chỉ đọc + chẩn đoán, không sửa gì — muốn sửa thì sang `/doctor --fix`)
> **Nói nôm na:** `/debug` bật chế độ chẩn đoán cho session HIỆN TẠI: vì sao model trả lời lạ, tool treo, context đầy nhanh, MCP rớt... Nó thu thập log, transcript, token, latency rồi chỉ ra nghi phạm + hướng xử lý — nhưng không tự sửa (sửa là việc của bạn hoặc `/doctor`). Hiểu 1 câu: `/doctor` khám config, `/debug` khám session đang chạy, `/bug` báo lỗi tool cho Anthropic.

## Khi nào dùng

- Dùng khi session hiện tại có triệu chứng lạ: model trả lời lệch, tool treo, context đầy nhanh, MCP rớt.
- Dùng **trước khi** `/clear` bừa: chẩn đoán ra nguyên nhân rồi mới reset, tránh mất context quý.
- Không dùng để sửa — `/debug` chỉ đọc và chỉ nghi phạm; sửa là việc của bạn hoặc `/doctor --fix`.

## Cách gọi

```bash
/debug             # chẩn đoán session hiện tại
/debug --verbose   # kèm latency từng tool
/debug transcript  # xuất transcript để soi
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Triệu chứng: model quên chỉ thị đầu session, nói linh tinh.
/debug
# → "Context 92% — file legacy/dump.sql 40k token đang chiếm nửa."
# Nguyên nhân: bạn Read nhầm file dump vào context.

# Fix: /clear rồi làm tiếp, đừng Read file dump nữa (dùng head/Grep thay).
```

Kết quả mong đợi:

- Chỉ ra nghi phạm kèm số liệu (context %, file ngốn token, tool treo).
- Không tự sửa file; đưa hướng xử lý (thường là `/clear` hoặc bỏ Read file to).

**Kiểm tra nhanh:** chạy lại `/debug` sau fix, context % phải giảm; `/status` hoặc `/context` để chắc mode/context còn sạch.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
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

> Mẹo 1 dòng: _đọc kết quả rồi mới /clear — xoá sớm là mất manh mối._
