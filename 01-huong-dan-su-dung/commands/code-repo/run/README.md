# /run — mở app thật và lái nó để thấy change chạy được

> Loại Built-in · Nhóm Model–Mode–Code · Mức rủi ro Thấp
> **Nói nôm na:** `/run` mở app thật (dev server, mobile simulator, CLI...) rồi tự lái để bạn thấy change chạy được bằng mắt. Đi cặp với `/verify`.

## Khi nào dùng

- Dùng `/run` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/run` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/run` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/run`
`/run <tên-app>`
`/run --record`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/run --record
# → dev server lên → mở /login → điền test@test.com/test1234 → bấm Đăng nhập
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/run` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| `/run` báo "no recipe" rồi hỏi 3 câu mỗi lần | Chưa `--record` nên không có skill lưu | Chạy 1 lần `/run --record`, commit `.claude/skills/run-*/` |
| Dev server timeout 60s không lên | Thiếu `.env`, deps chưa install, port bận | Đọc log cuối; `cp .env.example .env`; `npm i`; `lsof -i :3000` kill |
| PASS nhưng mở tay thấy trang trắng | Recipe chỉ check `/healthz`, không check đúng route | Sửa SKILL.md thêm bước vào đúng route + screenshot; chạy lại |

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../review/README.md](../../code-repo/review/README.md)
- [../security-review/README.md](../../code-repo/security-review/README.md)
- [../../knowledge-system/doctor/README.md](../../knowledge-system/doctor/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/run` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
