  -- Migration: tạo bảng profiles (ví dụ mẫu, sửa cột cho đúng domain)
  CREATE TABLE IF NOT EXISTS profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(), -- khóa chính uuid
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- chủ sở hữu
    display_name text NOT NULL, -- tên hiển thị
    created_at timestamptz NOT NULL DEFAULT now(), -- thời gian tạo
    updated_at timestamptz NOT NULL DEFAULT now() -- thời gian sửa
  );
  CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id); -- index tra theo user
