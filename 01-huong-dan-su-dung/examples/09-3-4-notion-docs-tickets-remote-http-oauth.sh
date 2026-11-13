claude mcp add --transport http notion --scope user https://mcp.notion.com/mcp
claude mcp login notion   # hoặc lần đầu OAuth: /mcp → notion: authorize → browser → approve
# Test: "tìm docs Notion về API conventions của team, tóm tắt 10 dòng"

# Servers team hay dùng (pattern tương tự):
# Linear/Jira/Slack: remote HTTP/SSE + OAuth, scope user (mỗi người token riêng).
# Fetch/Brave Search: web grounding (check provider có hỗ trợ web search không — bài 10).
