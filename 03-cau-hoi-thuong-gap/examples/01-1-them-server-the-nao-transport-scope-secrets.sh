# stdio (chạy local):
claude mcp add --transport stdio github -- npx -y @modelcontextprotocol/server-github
# http remote (SaaS) + scope project cho team:
claude mcp add --scope project --transport http linear --url https://mcp.linear.app/mcp --headers "Authorization: Bearer ${LINEAR_TOKEN}"
