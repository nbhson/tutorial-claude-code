# /subtask — Giao việc phụ cho subagent tách nhánh, báo về ngay đây

> Loại Built-in (v2.1.212+) · Nhóm Song song & Ủy thác · Nguy hiểm Thấp (chạy trong session, quyền kế thừa; nhưng Có nếu việc phụ có ghi/xoá mà bạn không dặn giới hạn)

> Nói nôm na: `/subtask` (từ bản v2.1.212+) fork một subagent làm side task NHỎ rồi báo kết quả về NGAY TRONG session này: tra 1 hàm, đọc 3 file, thử 1 hướng... Bạn không phải rời terminal, không detach như `/background`. Hiểu `/subtask` là hiểu "nhờ đứa bên cạnh tra hộ 1 cái, 2 phút sau nó đưa giấy lại".

## Khi nào dùng

- Dùng /subtask khi bạn đang làm việc với code/repo (xem diff, review, verify, chạy batch, khởi tạo).
- Dùng /subtask **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /subtask thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/subtask <việc>`
`/subtask <việc> --readonly`
`/subtask <việc> --model <tên>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Đang viết middleware, quên verifyJWT trả về gì:
# (không mở file khác, nhờ subagent tra)
/subtask tìm hàm verifyJWT trong src/, cho signature + file:dòng --readonly --model haiku
# → 1 phút sau: "src/auth/jwt.ts:12 — verifyJWT(token: string): JWTPayload { sub, exp }"
# → bạn viết tiếp luôn, không mất mạch
```

Kết quả mong đợi:

- Claude trả đúng việc của /subtask (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| `/subtask` báo unknown command | CLI <2.1.212 | Update CLI mới nhất (`/restart` offer); tạm dùng `/background` hoặc tra tay |
| Subtask sửa luôn file chính | Quên `--readonly`, dặn "thử" mơ hồ | Rollback (`git checkout <file>`); lần sau readonly + file scratch rõ ràng |
| Kết quả về chậm (10 phút việc 2 phút) | Giao việc quá rộng ("tóm tắt cả module") | Chia nhỏ ("chỉ 3 file X, 5 dòng"); rộng → background |

## Tham khảo

- [../background/README.md](../../session-context/background/README.md)
- [../fork/README.md](../../session-context/fork/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- [../tasks/README.md](../../session-context/tasks/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /subtask sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
