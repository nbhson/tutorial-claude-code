# /exit — Thoát Claude Code: đóng session, giữ nguyên auth và config

> Loại Built-in · Nhóm Auth · Nguy hiểm Không (chỉ đóng CLI; history + token + code giữ nguyên — muốn xoá auth phải `/logout`)

> Nói nôm na: `/exit` (alias: `Ctrl+C` 2 lần, `/quit`, gõ `exit`) thoát hẳn Claude Code về shell. Token vẫn lưu, lần sau mở `claude` là vào ngay không cần login. Hiểu `/exit` là hiểu "đóng cửa đi về" — khác `/clear` (ở lại nhưng quên việc cũ) và `/logout` (về và rút chìa).

## Khi nào dùng

- Dùng /exit khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /exit **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /exit thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/exit`
`/quit`
`Ctrl+C` ×2
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Đang dở task refactor, 18h rồi:
/exit
# → "Session abc123 saved."

# Sáng mai:
claude --resume
# → "Resumed session abc123 (47 messages). Tiếp tục?"
```

Kết quả mong đợi:

- Claude trả đúng việc của /exit (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `--resume` báo `no session found` | Hôm qua đóng X terminal, checkpoint hỏng | `claude --resume --list` xem còn gì; rút kinh nghiệm `/exit` |
| `Ctrl+C` 1 lần thoát luôn (không ở lại) | Bấm 2 lần quá nhanh | Dùng `/exit` gõ tay khi muốn chắc; 1 lần Ctrl+C = huỷ lệnh, đợi 1s rồi mới bấm tiếp nếu muốn thoát |
| Exit nhưng tiến trình node còn treo | MCP server con không dọn kịp | `ps aux \| grep claude` rồi kill tay; bản mới tự dọn tốt hơn |

## Tham khảo

- [../logout/README.md](../../auth-settings/logout/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../status/README.md](../../auth-settings/status/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /exit sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
