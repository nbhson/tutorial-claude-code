# Trong session, hỏi trực tiếp (Claude tự liệt kê tools khả dụng):
# > "liệt kê tất cả tools mày đang có + 1 câu mô tả mỗi tool"
claude mcp list   # ngoài session: kiểm tra MCP tools đang expose

# Task nền: > "Chạy pnpm build ở background, báo tao khi xong"
# Claude dùng Bash(run_in_background) + BashOutput. Kill nếu kẹt: Ctrl+X Ctrl+K hai lần trong 3 giây.
