# /sandbox — Hộp cát: dependency status, chạy thử cách ly, nổ thì không sao

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chính nó là phanh — chạy trong cát thì nổ cũng không văng ra ngoài; nhưng Có nếu bạn tin "đã sandbox" rồi chạy bừa lệnh phá hoại mà sandbox cấu sai)

> Nói nôm na: `/sandbox` quản lý môi trường chạy cách ly: kiểm tra dependency status (cái gì thiếu/hỏng trong cát), chạy lệnh thử trong cát trước khi chạy thật, xoá cát làm lại khi bẩn. Hiểu `/sandbox` là hiểu "phòng thí nghiệm có kính chống nổ" — thuốc mới thử trong này, nổ thì lau kính chứ không sập nhà.

## Khi nào dùng

- Dùng /sandbox khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /sandbox **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /sandbox thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/sandbox`
`/sandbox on`
`/sandbox off`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/sandbox status
# → "node 20 ✓ · network: blocked · mounts: /repo (rw)"
/sandbox on
# → chạy thử:
npm install lib-la-chua-ai-nghe
npm test
# → lib gọi về server lạ? network blocked → fail + log, máy thật an toàn
# → ưng thì tắt cát cài thật, không ưng thì /sandbox reset
```

Kết quả mong đợi:

- Claude trả đúng việc của /sandbox (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `command not found` trong cát dù ngoài có | Toolchain cát thiếu | `status` xem thiếu gì; cài vào image cát hoặc chạy ngoài |
| Lệnh cần mạng fail trong cát | Network blocked (đúng thiết kế) | Allowlist registry cần thiết, hoặc chạy ngoài khi đã tin |
| File ghi trong cát "mất" sau reset | Reset xoá state cát | Copy kết quả ra `/repo` (mount chung) trước khi reset |

## Tham khảo

- [../config/README.md](../../auth-settings/config/README.md)
- [../remote-env/README.md](../../auth-settings/remote-env/README.md)
- [../teleport/README.md](../../auth-settings/teleport/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /sandbox sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
