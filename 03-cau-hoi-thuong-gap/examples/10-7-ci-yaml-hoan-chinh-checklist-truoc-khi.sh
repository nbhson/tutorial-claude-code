# 1. Allowlist hẹp? (không bypass ngoài sandbox)
/permissions
# 2. Secrets từ env? (git grep rỗng?)
git grep -E 'ghp_|sk-ant_' -- .mcp.json .claude/ .
# 3. Chạy tay 1 lần xanh với đúng flags CI?
claude -p "<task>" --output-format json --permission-mode dontAsk --allowedTools "Read Grep Glob ..."
# 4. Headless-safe? (hooks không prompt)
/hooks
# 5. Verify gắn chưa? (ai check output? tests? human?)
/verify
