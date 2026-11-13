claude mcp list            # all servers + scope + status
claude mcp get github      # chi tiết 1 server (scope nào đang thắng?)
grep -ri "sk-\|token\|password" .mcp.json   # phải trống!
claude mcp remove postgres && claude mcp add --transport stdio postgres --scope local -- <cmd>
