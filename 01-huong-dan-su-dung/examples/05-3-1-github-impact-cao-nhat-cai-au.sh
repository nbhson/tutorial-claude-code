# Bước 1: đảm bảo gh CLI login (dùng token sẵn có):
gh auth login && gh auth status   # phải thấy Logged in

# Bước 2: thêm server (project scope để share team):
claude mcp add --transport stdio github --scope project -- npx @anthropic/mcp-github@latest

# Bước 3: verify trong session:
/mcp
# Test: "liệt kê 5 PRs mở gần nhất của repo này + tóm tắt mỗi PR 1 dòng"
