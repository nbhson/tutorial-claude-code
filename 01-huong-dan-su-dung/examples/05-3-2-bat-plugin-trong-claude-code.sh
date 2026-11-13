# Verify sau khi bật (làm 1 lần):
# Hỏi: "jump to definition hàm login trong src/auth.ts"
# → phải trả về 1 file:dòng chính xác, không phải 20 kết quả grep
# Hỏi: "file này còn lỗi type nào?" → phải liệt kê diagnostics theo dòng
# Trả 20 kết quả grep là LSP chưa nhận project (thiếu tsconfig.json).
