# Test 1 file cụ thể (ưu tiên nhất, nhanh nhất)
pnpm --filter @acme/api test src/routes/auth.test.ts
# Test 1 package (khi đổi nhiều file trong package)
pnpm --filter @acme/api test
# Full check khi user yêu cầu rõ (chỉ chạy khi thật cần)
pnpm lint && pnpm test && pnpm build
