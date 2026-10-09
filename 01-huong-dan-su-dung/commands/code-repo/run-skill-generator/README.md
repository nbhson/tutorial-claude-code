# /run-skill-generator — ghi recipe "cách chạy app" thành skill tái dùng

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không
> **Nói nôm na:** `/run-skill-generator` là wizard ghi lại "cách chạy app này" thành recipe ở `.claude/skills/run-<tên>/SKILL.md`: lệnh start, port, check sống, bước lái thử.

## Khi nào dùng

- Dùng `/run-skill-generator` khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng `/run-skill-generator` **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng `/run-skill-generator` thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi

```bash
`/run-skill-generator`
`/run-skill-generator <tên>`
`/run --record`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

**Prompt thật (paste vào Claude Code):**

```bash
/run-skill-generator web
# → đoán lệnh start/port/check sống → chạy thử PASS → ghi .claude/skills/run-web/SKILL.md
git add .claude/skills/run-web/ && git commit -m "chore: add run-web recipe"
```

**Kết quả mong đợi:**

- Claude trả đúng việc của `/run-skill-generator` (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

**Verify (30 giây):**

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
|---|---|---|
| Generator đoán sai lệnh start | Monorepo nhiều `package.json` | Trả lời tay đúng lệnh + `workingDir`; ghi rõ trong SKILL.md |
| Chạy thử PASS nhưng `/run` sau fail | Env đổi (hết hạn token test, DB seed bị xóa) | Recipe dùng seed/fixture cố định; smoke check báo rõ thiếu gì |
| Ghi đè nhầm recipe đang dùng tốt | Chạy generator cùng tên mà không Diff | Luôn chọn Diff trước Yes; rollback `.claude/skills/run-<tên>/` |

## Tham khảo

- [../verify/README.md](../../code-repo/verify/README.md)
- [../init/README.md](../../code-repo/init/README.md)
- [../../knowledge-system/doctor/README.md](../../knowledge-system/doctor/README.md)
- [../../knowledge-system/mcp/README.md](../../knowledge-system/mcp/README.md)

- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi `/run-skill-generator` sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
