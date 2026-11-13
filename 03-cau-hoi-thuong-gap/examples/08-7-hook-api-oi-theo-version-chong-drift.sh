# dry-run mẫu — hook nhận cùng JSON thật từ stdin
echo '{"tool_name":"Bash","tool_input":{"command":"git push"}}' | ./scripts/guard-no-push-main.sh; echo "exit=$?"
