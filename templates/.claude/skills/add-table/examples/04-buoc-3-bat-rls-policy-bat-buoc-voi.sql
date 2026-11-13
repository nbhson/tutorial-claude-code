  -- Bật Row Level Security: không bật = mọi role đọc được hết
  ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
  -- Policy: user chỉ đọc/sửa dòng của chính mình
  CREATE POLICY "profiles_owner_all" ON profiles
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  -- Policy: service_role bypass khi chạy job nền (nếu cần)
  -- CREATE POLICY "profiles_service_all" ON profiles FOR ALL TO service_role USING (true);
