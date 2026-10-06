# /voice — Nói thay vì gõ (giữ Space để nói, thả để gửi)

> Loại Built-in · Nhóm Nhập liệu & Trợ năng · Nguy hiểm Không (chỉ đổi cách nhập; nhưng Có nhẹ nếu bạn đọc to secret/mã OTP nơi đông người)

> Nói nôm na: `/voice` bật/tắt voice dictation trong terminal: giữ `Space` để nói, thả ra là transcript thành prompt gửi đi. Sinh ra cho lúc mỏi tay, đang đi bộ với mobile, hoặc ý dài nói nhanh hơn gõ. Hiểu `/voice` là hiểu "nhắn voice như chat app, nhưng nó biến thành chữ trước khi gửi".

## Khi nào dùng

- Dùng /voice khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /voice **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /voice thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/voice`
Giữ `Space`
`/terminal-setup`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/voice
# → Voice ON
# (giữ Space) "đọc file src/auth/login.ts, tóm tắt nó làm gì, có verify JWT không" (thả)
# → transcript: "đọc file src/auth/login.ts, tóm tắt nó làm gì, có verify JWT không" ✓
# → Enter → model làm, bạn vừa đi vừa nghe kết quả
/voice
# → Voice OFF khi về bàn
```

Kết quả mong đợi:

- Claude trả đúng việc của /voice (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Giữ Space không thu, thả ra trống | OS chưa cấp quyền mic (lần đầu Deny) | Settings OS → cho terminal quyền mic; `/terminal-setup` kiểm tra lại |
| Transcript toàn sai từ chuyên môn | Nói nhanh + từ lạ (`webhook`, `idempotency`) | Nói chậm, đánh vần tên riêng; hoặc gõ tay đoạn có từ chuyên môn |
| Thu cả tiếng quạt/đồng nghiệp | Mic mặc định là mic xa/kém chống ồn | Đổi mic gần (tai nghe) trong settings OS; vào chỗ yên |

## Tham khảo

- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../mobile/README.md](../../auth-settings/mobile/README.md)
- [../btw/README.md](../../code-repo/btw/README.md)
- [../background/README.md](../../session-context/background/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /voice sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
