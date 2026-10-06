# /config — Trung tâm cài đặt: alias /settings, tabs Account/Permissions/MCP/Env

> Loại Built-in · Nhóm Settings · Nguy hiểm Có (sửa sai settings.json là mất phanh (permissions), mất tools (MCP), hoặc khoá luôn session — backup trước khi sửa tay)

> Nói nôm na: `/config` (alias `/settings` — gõ cái nào cũng ra cùng 1 màn hình) là bảng điều khiển toàn bộ Claude Code: xem/sửa model, permissions, MCP servers, hooks, env, account mặc định... theo từng scope (project/local/managed). Hiểu `/config` là hiểu "phòng máy" — mọi lệnh khác (`/permissions`, `/mcp`, `/hooks`...) chỉ là cửa tắt vào từng tab của phòng này.

## Khi nào dùng

- Dùng /config khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /config **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /config thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/config`
`/settings`
`/config <tab>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/config --scope managed
# → {"deny": ["Bash(sudo:*)", "MCP(external-*赤)"], "region": "eu-west", ...}
# → À, công ty cấm sudo + MCP ngoài. Khỏi thắc mắc, khỏi tìm cách gỡ (gỡ không được).

/config --scope project
# → baseline team: deny rm-rf, allow test/lint (đi theo git, đã có sẵn)
```

Kết quả mong đợi:

- Claude trả đúng việc của /config (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Sửa settings tay xong config "bay về default" | JSON sai cú pháp, fail parse | Restore `.bak`; dùng UI sửa; `python3 -m json.tool settings.json` check |
| Allow rồi mà vẫn bị chặn | Managed deny đè (thiết kế) | `/config --scope managed` xem ai chặn; xin admin, đừng cố gỡ |
| `/settings` tưởng lệnh khác `/config` | Không — cùng 1 handler | Nhớ 1 là đủ; bài này gộp chung |

## Tham khảo

- [../status/README.md](../../auth-settings/status/README.md)
- [../login/README.md](../../auth-settings/login/README.md)
- [../logout/README.md](../../auth-settings/logout/README.md)
- [../cd/README.md](../../auth-settings/cd/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /config sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
