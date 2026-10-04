---
name: add-table
description: Tạo DB table mới chuẩn Postgres gồm migration, RLS policy và test. Dùng khi user nói thêm bảng, tạo table, add-table.
disable-model-invocation: false
allowed-tools: Bash, Read, Write, Edit
---

# Add Table — nhận $ARGUMENTS (tên bảng, vd `profiles`)

> Ví dụ gọi: `/add-table profiles`.
> Stack mẫu: Postgres + file migration SQL trong `db/migrations/`.
> Comment trong file mẫu đều tiếng Việt để新人 cũng đọc được.

## Inputs

1. `$ARGUMENTS` = tên bảng snake_case (vd `profiles`, `org_members`).
   - Rỗng → hỏi user tên bảng + 3-5 cột chính, rồi dừng.
   - Tên phải snake_case số nhiều (vd `profiles`, không phải `Profile`).
2. Xác nhận DB driver của repo (mặc định Postgres; nếu repo dùng driver khác thì map lại).

## Steps (làm đúng thứ tự)

### Bước 1 — Khảo sát schema hiện tại (không đoán)

- Liệt kê migrations cũ để lấy convention đánh số:
  ```bash
  # Xem 5 migration gần nhất để đặt tên file tiếp theo
  ls -1 db/migrations/ | sort | tail -5
  ```
- Đọc 1 migration mẫu để copy header/style (vd `db/migrations/0001_init.sql`).
- Đọc file models/types hiện tại nếu có (vd `apps/api/src/db/schema.ts`).

### Bước 2 — Viết migration (file mới)

- Tên file: `db/migrations/<YYYYMMDDHHMMSS>_create_<ten_bang>.sql`.
- Nội dung bắt buộc:
  ```sql
  -- Migration: tạo bảng profiles (ví dụ mẫu, sửa cột cho đúng domain)
  CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(), -- khóa chính uuid
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- chủ sở hữu
    display_name text NOT NULL, -- tên hiển thị
    created_at timestamptz NOT NULL DEFAULT now(), -- thời gian tạo
    updated_at timestamptz NOT NULL DEFAULT now() -- thời gian sửa
  );
  CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id); -- index tra theo user
  ```
- Chạy check cú pháp (không apply mù):
  ```bash
  # Dry-run hoặc lint SQL tùy tool team (ví dụ dùng psql --dry-run / sqllint)
  pnpm db:migrate --dry-run
  ```

### Bước 3 — Bật RLS + policy (bắt buộc với Postgres)

- Sau `CREATE TABLE`, luôn thêm:
  ```sql
  -- Bật Row Level Security: không bật = mọi role đọc được hết
  ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
  -- Policy: user chỉ đọc/sửa dòng của chính mình
  CREATE POLICY "profiles_owner_all" ON profiles
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  -- Policy: service_role bypass khi chạy job nền (nếu cần)
  -- CREATE POLICY "profiles_service_all" ON profiles FOR ALL TO service_role USING (true);
  ```
- NEVER để bảng user-data public read (`USING (true)` cho anon) trừ khi có yêu cầu rõ ràng.

### Bước 4 — Viết test (bắt buộc)

- Tạo `db/__tests__/<ten_bang>.test.ts` kiểm tra 3 việc:
  1. Migration chạy lên/xuống không lỗi.
  2. Insert 1 row hợp lệ → đọc lại được.
  3. RLS: user A không đọc được row của user B (expect 0 rows / 403).
- Chạy focused test:
  ```bash
  # Chạy đúng file test vừa tạo, không chạy full suite
  pnpm test db/__tests__/profiles.test.ts
  ```

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
