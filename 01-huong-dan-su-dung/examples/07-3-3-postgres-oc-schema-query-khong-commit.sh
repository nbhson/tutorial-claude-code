export PGPASSWORD_DEV="..."   # đặt ngoài file, trong shell/cloud env
claude mcp add --transport stdio postgres --scope local --env PGPASSWORD="$PGPASSWORD_DEV" -- \
  npx @modelcontextprotocol/server-postgres@latest "postgresql://dev@localhost:5432/acme_dev"

# Verify:
# > "liệt kê tables trong DB + đếm rows mỗi table, chỉ đọc không viết"
