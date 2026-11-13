# Local stdio — Claude spawn process local (postgres xem mục 3.3)
claude mcp add --transport stdio playwright -- npx @playwright/mcp@latest

# Remote SSE / HTTP
claude mcp add --transport sse private-api https://api.example/mcp \
  --header "Authorization: Bearer TOKEN"
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Env + JSON + import từ Claude Desktop
claude mcp add <name> --env KEY=VALUE -- <cmd> [args...]
claude mcp add-json <name> '{"command":"npx","args":[...]}'
claude mcp add-from-claude-desktop
