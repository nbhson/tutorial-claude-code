# 1. Copy cả khung sang repo thật (đứng ở root repo đích)
cp -r /path/to/tutorial-claude-code/templates/.claude ./
cp /path/to/tutorial-claude-code/templates/CLAUDE.md ./
cp /path/to/tutorial-claude-code/templates/.mcp.json ./
# Tùy chọn: copy workflow CI mẫu (chỉ khi dùng GitHub Actions)
# cp -r /path/to/tutorial-claude-code/templates/.github ./

# 2. Cho quyền chạy hooks (bắt buộc trên macOS/Linux)
chmod +x .claude/hooks/*.sh
./.claude/hooks/lint-on-write.sh --help 2>/dev/null || echo "hook ok (chờ stdin JSON)"

# 3. Kiểm tra Claude nhận đủ config
# Mở Claude Code trong repo đích rồi gõ lần lượt: /agents, /hooks, /mcp
# Cả 3 đều hiện đúng như bảng trên là đạt. Thiếu cái nào -> sửa file tương ứng rồi gõ lại.
