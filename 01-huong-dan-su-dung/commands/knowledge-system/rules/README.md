# /rules — Quản lý quy ước modular: luật nào áp dụng cho file/thư mục nào

> Loại Built-in · Nhóm Tri thức & Hệ thống · Mức rủi ro Không (nhưng Có nếu rules mâu thuẫn nhau — model làm lúc đúng lúc sai khó debug)
> **Nói nôm na:** `/rules` quản lý các file quy ước nhỏ (rules files) thay vì nhồi tất cả vào 1 file CLAUDE.md khổng lồ. Mỗi rule có `paths` (áp dụng cho đâu) + `frontmatter` (mô tả, độ ưu tiên), và chỉ được lazy-load khi bạn chạm vào file khớp pattern. Hiểu `/rules` là hiểu "luật giao thông theo khu vực" — vào khu nào thì tuân luật khu đó.

## Khi nào dùng

- Dùng khi CLAUDE.md bắt đầu phình và bạn muốn tách luật theo khu vực file.
- Dùng **trước khi** luật chồng chéo: mỗi rule 1 phạm vi `paths`, lazy-load khi chạm file khớp.
- Không dùng thay review: rules mâu thuẫn làm model lúc đúng lúc sai, cần tự kiểm.

## Cách gọi

```bash
/rules              # xem/quản lý rules
/rules show         # kiểm tra paths + nội dung
/rules add <file>   # thêm rule mới
```

> Gõ `/` trong session để xem lệnh có hiện ở môi trường của bạn không (một số lệnh version-gated / provider-gated).

## Ví dụ thật + kết quả mong đợi + cách kiểm tra

Prompt thật (paste vào Claude Code):

```bash
# Bước 1: tạo 4 file rules
/rules add python
/rules add api
/rules add frontend
/rules add sql
```

Kết quả mong đợi:

- Rule nạp đúng khi sửa file khớp `paths`; file ngoài phạm vi không tốn context.
- Mâu thuẫn được xử bằng `priority` hoặc paths cụ thể hơn thắng.

**Kiểm tra nhanh:** `/rules show` xem glob; thử sửa 1 file khớp pattern để thấy rule áp dụng.

## Lỗi thường gặp

| Triệu chứng | Vì sao | Cách sửa |
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

> Mẹo 1 dòng: _rule <200 dòng lành hơn 1 rule 1000 dòng — tách theo thư mục._
