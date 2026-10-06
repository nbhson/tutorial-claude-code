# /vim — Chế độ vim: normal/insert, hjkl, soạn prompt như soạn code

> Loại Built-in · Nhóm Settings · Nguy hiểm Không (chỉ đổi cách soạn phím — nhưng Có nhẹ nếu normal-mode bấm nhầm `shift+y` duyệt permission lúc đang tưởng mình soạn text)

> Nói nôm na: `/vim` bật/tắt chế độ soạn kiểu vim trong khung nhập: `Esc` về normal (`hjkl` di chuyển, `w/b` nhảy từ, `dd` xoá dòng), `i/a/o` vào insert gõ tiếp. Hiểu `/vim` là hiểu "khung chat cũng là buffer vim" — tay vim khỏi rời home row.

## Khi nào dùng

- Dùng /vim khi bạn cần chỉnh môi trường/tài khoản/cài đặt (login, IDE, config, remote, sandbox).
- Dùng /vim **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /vim thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/vim`
`/vim on`
`/vim off`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
/vim on
# Gõ spec 20 dòng (insert) → Esc → /auth → nhảy tới chỗ cần sửa
# → cw sửa từ, yy p nhân bản đoạn, i gõ tiếp, Enter gửi
# → prompt dài mà sửa nhanh như sửa code
```

Kết quả mong đợi:

- Claude trả đúng việc của /vim (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `Esc` không về normal | Terminal/tmux ăn Esc | Fix terminal-setup; dùng `Ctrl+[` tạm |
| `hjkl` gõ ra chữ thay vì di chuyển | Đang insert (chưa Esc) hoặc vim off | `Esc` trước; `/vim --status` kiểm tra |
| `dd` tưởng xoá file | Hiểu nhầm scope — chỉ xoá dòng prompt | Yên tâm, nhưng đọc lại mục cơ chế để chắc |

## Tham khảo

- [../keybindings/README.md](../../auth-settings/keybindings/README.md)
- [../terminal-setup/README.md](../../auth-settings/terminal-setup/README.md)
- [../ide/README.md](../../auth-settings/ide/README.md)
- [../../01-cai-dat-va-xac-thuc.md](../../../01-cai-dat-va-xac-thuc.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /vim sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
