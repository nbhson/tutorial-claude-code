# 1. Rotate NGAY (vô hiệu token cũ) — làm trước, dọn sau
# 2. Xóa approvals/project choices cũ:
claude mcp reset-project-choices
# 3. Rà còn sót:
git grep -E 'ghp_|sk-ant_|xoxb-|AKIA' -- .mcp.json .claude/ .
# 4. Dọn history (nếu đã push): BFG/filter-repo + force-push + báo team rotate tiếp
