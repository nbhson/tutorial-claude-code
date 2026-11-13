# Vừa /teleport cloud, chạy build:
npm run build
# → "Error: DATABASE_URL is not defined"

# So rồi cấp:
/remote-env diff
# → "Missing on remote: DATABASE_URL, STRIPE_KEY"
# Lưu ý: endpoint CLOUD, đừng paste localhost sang:
