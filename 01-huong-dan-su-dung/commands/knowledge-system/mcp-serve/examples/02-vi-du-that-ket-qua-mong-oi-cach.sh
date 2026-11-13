# Extension cần đọc file workspace qua MCP thay vì fs trực tiếp
# (để được grep thông minh + tôn trọng .gitignore):
# 1. Mở server chỉ-đọc:
claude mcp serve --tools read,grep,glob --restricted

# 2. Phía extension config MCP trỏ vào lệnh trên (.mcp.json như mẫu Dạng 5)
# 3. Test từ terminal:
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | claude mcp serve --tools read,grep,glob
