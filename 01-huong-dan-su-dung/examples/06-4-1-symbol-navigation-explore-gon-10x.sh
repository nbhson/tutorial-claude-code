# Prompt mẫu copy-paste (so với grep: 60 kết quả cả comment/log/test cũ → 8 refs thật):
"find references của refreshToken (dùng LSP), chỉ liệt kê call sites thật trong src/, bỏ test snapshot và comment."

# Rename an toàn — server rename đúng def + refs, không sót, không sửa nhầm chuỗi "login" trong log:
"rename symbol loginWithSSO thành loginWithOIDC (dùng LSP rename), liệt kê files đổi, không chạm test snapshot."

# Explore multi-file — explorer đi theo graph thật, không đọc 300 files:
"Từ handler POST /login trong apps/api, jump qua domain + db layers (LSP definition), trả về ≤10 files sẽ sửa + 1 dòng/file vì sao."
