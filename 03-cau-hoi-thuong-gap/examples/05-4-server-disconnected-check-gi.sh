echo ${GITHUB_TOKEN:+token-set}
curl -sI https://mcp.linear.app/mcp | head -3
/mcp reconnect linear
claude mcp get linear   # soi config sai chỗ nào
