/permissions              # 1. dirs hẹp? deny rm-rf/sudo/.env có?
git grep -E 'ghp_|sk-ant_' -- .mcp.json .claude/   # 2. secrets sạch?
/mcp                      # 3. servers thừa? tắt cái không dùng
/hooks                    # 4. hooks lạ? đọc scripts
/doctor                   # 5. điểm security? đỏ thì vá trước
# → grep RỖNG + doctor không cảnh báo đỏ = repo sạch để làm việc
