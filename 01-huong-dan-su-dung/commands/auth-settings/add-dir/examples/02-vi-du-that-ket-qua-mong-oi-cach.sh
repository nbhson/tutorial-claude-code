# Đang ở api, stack trace chỉ vào shared/lib.ts:
/add-dir ../shared
# → "Added shared · CLAUDE.md loaded (env flag on)"

# Đọc chéo:
# Read packages/shared/src/lib.ts → thấy hàm sai
# Edit ở shared, test ở api (Bash vẫn chạy main=api)
npm test
