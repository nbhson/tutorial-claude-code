/hooks    # xem tất cả hooks theo events — hook không list = config sai file/JSON parse lỗi
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | ./scripts/guard-no-push-main.sh
# → phải ra {"decision":"block",...}
