---
name: add-table
description: Tạo DB table mới chuẩn Postgres gồm migration, RLS policy và test. Dùng khi user nói thêm bảng, tạo table, add-table.
disable-model-invocation: false
allowed-tools: Bash, Read, Write, Edit
---

# Add Table — nhận $ARGUMENTS (tên bảng, vd `profiles`)

> Ví dụ gọi: `/add-table profiles`.
> Stack mẫu: Postgres + file migration SQL trong `db/migrations/`.
> Comment trong file mẫu đều tiếng Việt để người mới cũng đọc được.

Skill này giống một thầu xây bàn: khảo sát nền móng (schema cũ) → đổ bê tông (migration) → lắp khóa cửa (RLS) → nghiệm thu (test), đúng thứ tự, không bước nào bỏ qua.

## Inputs

1. `$ARGUMENTS` = tên bảng snake_case (vd `profiles`, `org_members`).
   - Rỗng → hỏi user tên bảng + 3-5 cột chính, rồi dừng.
   - Tên phải snake_case số nhiều (vd `profiles`, không phải `Profile`).
2. Xác nhận DB driver của repo (mặc định Postgres; nếu repo dùng driver khác thì map lại).

## Steps (làm đúng thứ tự)

### Bước 1 — Khảo sát schema hiện tại (không đoán)

- Liệt kê migrations cũ để lấy convention đánh số:
  > 📄 **Code ví dụ:** [`examples/01-buoc-1-khao-sat-schema-hien-tai-khong.sh`](examples/01-buoc-1-khao-sat-schema-hien-tai-khong.sh)
- Đọc 1 migration mẫu để copy header/style (vd `db/migrations/0001_init.sql`).
- Đọc file models/types hiện tại nếu có (vd `apps/api/src/db/schema.ts`).

### Bước 2 — Viết migration (file mới)

- Tên file: `db/migrations/<YYYYMMDDHHMMSS>_create_<ten_bang>.sql`.
- Nội dung bắt buộc:
  > 📄 **Code ví dụ:** [`examples/02-buoc-2-viet-migration-file-moi.sql`](examples/02-buoc-2-viet-migration-file-moi.sql)
- Chạy check cú pháp (không apply mù):
  > 📄 **Code ví dụ:** [`examples/03-buoc-2-viet-migration-file-moi.sh`](examples/03-buoc-2-viet-migration-file-moi.sh)

### Bước 3 — Bật RLS + policy (bắt buộc với Postgres)

RLS là chốt cửa cuối cùng của tầng dữ liệu: dù ai đó trèo qua các tầng trên mà lọt xuống, tầng này vẫn khóa theo user.

- Sau `CREATE TABLE`, luôn thêm:
  > 📄 **Code ví dụ:** [`examples/04-buoc-3-bat-rls-policy-bat-buoc-voi.sql`](examples/04-buoc-3-bat-rls-policy-bat-buoc-voi.sql)
- NEVER để bảng user-data public read (`USING (true)` cho anon) trừ khi có yêu cầu rõ ràng.

### Bước 4 — Viết test (bắt buộc)

- Tạo `db/__tests__/<ten_bang>.test.ts` kiểm tra 3 việc:
  1. Migration chạy lên/xuống không lỗi.
  2. Insert 1 row hợp lệ → đọc lại được.
  3. RLS: user A không đọc được row của user B (expect 0 rows / 403).
- Chạy focused test:
  > 📄 **Code ví dụ:** [`examples/05-buoc-4-viet-test-bat-buoc.sh`](examples/05-buoc-4-viet-test-bat-buoc.sh)

## Output format

```markdown
## Đã tạo bảng <ten_bang>

- Migration: `db/migrations/<file>.sql`
- RLS: ENABLED + policy `*_owner_all` (authenticated only)
- Test: `db/__tests__/<ten_bang>.test.ts` — PASS/FAIL
- Lệnh đã chạy: `<paste lệnh + kết quả 3 dòng cuối>`
- Rollback: `pnpm db:migrate:down` (ghi rõ 1 lệnh hoàn tác)
```

## Constraints

- NEVER tạo bảng không có RLS khi chứa `user_id` (dữ liệu user).
- NEVER đặt tên cột camelCase trong SQL — dùng snake_case.
- ALWAYS chạy focused test trước khi báo xong; fail → giữ migration, báo lỗi nguyên văn.

> **Tóm gọn 1 câu:** Tạo bảng = 4 bước không bỏ qua: khảo sát → migration → RLS khóa cửa → test nghiệm thu, và luôn kèm 1 lệnh rollback trong báo cáo.
