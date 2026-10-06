# /rules — Quản lý quy ước modular: luật nào áp dụng cho file/thư mục nào

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Không (nhưng Có nếu rules mâu thuẫn nhau — model làm lúc đúng lúc sai khó debug)

> Nói nôm na: `/rules` quản lý các file quy ước nhỏ (rules files) thay vì nhồi tất cả vào 1 file CLAUDE.md khổng lồ. Mỗi rule có `paths` (áp dụng cho đâu) + `frontmatter` (mô tả, độ ưu tiên), và chỉ được lazy-load khi bạn chạm vào file khớp pattern. Hiểu `/rules` là hiểu "luật giao thông theo khu vực" — vào khu nào thì tuân luật khu đó.

## Khi nào dùng

- Dùng /rules khi bạn cần tra cứu/chẩn đoán/mở rộng hệ tri thức (agents, MCP, hooks, skills, debug, doctor).
- Dùng /rules **trước khi** task phình to (đầu task, đầu session, trước việc nguy hiểm) — rẻ hơn sửa sai sau.
- Không dùng /rules thay cho đọc code/review tay — nó là trợ lý, không phải người chịu trách nhiệm cuối.

## Cách gọi (copy-paste)

```bash
`/rules`
`/rules show`
`/rules add <file>`
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ prompt thật + kết quả mong đợi + verify

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: tạo 4 file rules
/rules add python
/rules add api
/rules add frontend
/rules add sql
```

Kết quả mong đợi:

- Claude trả đúng việc của /rules (không lan man), nêu rõ bước tiếp theo.
- Lệnh chỉ-đọc thì không sửa file; lệnh ghi/chạy thì liệt kê file sẽ chạm trước.

Verify (30 giây):

```bash
# trong session: /status hoặc /context để chắc mode/context còn sạch
```

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách fix |
|---|---|---|
| Tạo rule mà model không tuân | Paths sai/không khớp file đang sửa | `/rules show` kiểm tra glob; test `docs/*` vs `docs/**/*` |
| Hai rules đánh nhau | Mâu thuẫn nội dung, không priority | Thêm `priority: high` cho ngoại lệ; paths cụ thể hơn thắng |
| Rule nạp chậm/không ổn định | Body quá dài (>500 dòng), model bỏ qua phần cuối | Tách rule lớn thành 2-3 rules nhỏ, mỗi cái <200 dòng |

## Tham khảo

- [../memory/README.md](../../knowledge-system/memory/README.md)
- [../doctor/README.md](../../knowledge-system/doctor/README.md)
- [../init/README.md](../../code-repo/init/README.md)
- [../agents/README.md](../../knowledge-system/agents/README.md)
- Bài tổng quan: `01-huong-dan-su-dung/04-slash-commands-toan-tap.md`

> Mẹo 1 dòng: _chưa chắc thì gọi /rules sớm — 1 lệnh đúng lúc rẻ hơn 10 prompt sửa sai._
