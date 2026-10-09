# /restart — Khởi động lại CLI giữ nguyên session (kèm offer bản mới)

> Loại Built-in · Nhóm Session & Hệ thống · Mức rủi ro Không (giữ session; nhưng Có nhẹ nếu bạn restart giữa lúc tool đang ghi file — chờ nó xong hẳn rồi hẵng restart)
> **Nói nôm na:** `/restart` (bí danh `/update` ở một số bản) khởi động lại tiến trình Claude Code mà KHÔNG mất hội thoại: update bản mới, nạp lại config/MCP/hooks, sửa treo lag — xong quay lại đúng chỗ đang làm. Bản mới còn offer nâng cấp version nếu có. Hiểu `/restart` là hiểu "khởi động lại máy mà không mất tab đang mở".

## Khi nào dùng

- Dùng `/restart` khi CLI bắt đầu treo/lag, MCP timeout, hoặc cần nạp lại config/MCP/hooks.
- Dùng `/restart` sau khi update bản mới, và chờ tool đang ghi file xong hẳn trước khi restart.
- Không dùng `/restart` giữa lúc tool đang chạy lệnh dài — cắt ngang có thể làm fail thao tác đang ghi.

## Cách gọi

```bash
`/restart`
`/update`
`/exit` + mở lại
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Gõ mãi mới ra chữ, MCP timeout liên tục:
# 1. Chờ tool đang chạy xong (không restart giữa chừng!)

# 2. Restart
/restart
# → "Session saved (58 messages). Restarting… Back in 4s. 58 messages restored."

# 3. Kiểm tra còn lag không: hỏi 1 câu ngắn
```

Kết quả mong đợi:

- Claude trả đúng việc của /restart (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/update` báo unknown command | Bản bạn không có bí danh này | Dùng `/restart` (offer update nằm trong đó) |
| Restart xong session trống | Snapshot fail (disk đầy / crash đúng lúc ghi) | `/resume` tìm session ID gần nhất; dọn disk; đừng restart khi máy báo disk full |
| Restart xong vẫn lag | Bệnh ở model/provider mạng, không phải tiến trình local | Đổi model nhẹ (`/model haiku`), check mạng; `/status` xem provider |

## Tham khảo

- [../status/README.md](../../auth-settings/status/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /restart sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
