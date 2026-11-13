claude mcp add --transport stdio github -- npx -y @modelcontextprotocol/server-github
claude mcp add --transport http linear --url https://mcp.linear.app/mcp --headers "Authorization: Bearer ${LINEAR_TOKEN}"
# secrets qua ${VAR}, không hardcode. Scope: project (.mcp.json team) | local (chỉ bạn) | user (~/.claude/)
claude mcp login github                  # OAuth đăng nhập server cần auth (≥ w26/2026)
claude mcp logout github                 # đăng xuất / token hết hạn thì login lại
# MCP protocol 2026-07-28 từ CLI ≥2.1.292. Validate server trước khi tin: claude plugin details/eval
