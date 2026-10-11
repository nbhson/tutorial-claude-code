# /restart — Khởi động lại CLI giữ nguyên session (kèm gợi ý lên bản mới)

> **Loại:** Built-in · **Nhóm:** Session & Hệ thống · **Mức rủi ro:** Không (giữ session; nhưng "Có" nhẹ nếu bạn restart giữa lúc tool đang ghi file — chờ nó xong hẳn rồi hẵng restart)
> **Nói nôm na:** `/restart` (bí danh `/update` ở một số bản) khởi động lại tiến trình Claude Code mà KHÔNG mất hội thoại: update bản mới, nạp lại config/MCP/hooks, sửa treo lag — xong quay lại đúng chỗ đang làm. Bản mới còn gợi ý nâng cấp version nếu có. Hiểu `/restart` là hiểu "khởi động lại máy mà không mất tab đang mở".

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

- CLI khởi động lại, nạp lại config/MCP/hooks; hội thoại (n messages) được phục hồi nguyên.
- Nếu có bản mới, `/restart` đề nghị update luôn.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/update` báo unknown command | Bản bạn không có bí danh này | Dùng `/restart` (gợi ý nâng cấp nằm trong đó) |
| Restart xong session trống | Snapshot fail (disk đầy / crash đúng lúc ghi) | `/resume` tìm session ID gần nhất; dọn disk; đừng restart khi máy báo disk full |
| Restart xong vẫn lag | Bệnh ở model/provider mạng, không phải tiến trình local | Đổi model nhẹ (`/model haiku`, nay là Haiku 5.5, ≥2.1.293), check mạng; `/status` xem provider |

## Tham khảo

- [../status/README.md](../../auth-settings/status/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../clear/README.md](../../session-context/clear/README.md)
- [../resume/README.md](../../session-context/resume/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _luôn chờ tool đang ghi file chạy xong hẳn trước khi `/restart` — cắt ngang dễ làm hỏng thao tác đang dở._
