# Trước khi cài plugin lạ:
/plugin    # mở Browse, đọc: commands? agents? skills? hooks? MCP? permissions xin gì?
# Plugin xin (Read + Bash(*) + network) mà việc chỉ là "format" → KHÔNG CÀI

# Sau khi cài, rà nhanh:
ls .claude/hooks/ && cat .claude/hooks/*.sh
git grep -E 'curl|rm -rf|sudo|exfil|ngrok' -- .claude/
# → git grep RỖNG = không có script nào exfil ra ngoài
