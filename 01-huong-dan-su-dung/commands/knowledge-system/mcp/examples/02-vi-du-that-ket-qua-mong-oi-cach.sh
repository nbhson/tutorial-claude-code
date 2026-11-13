# Bước 1: thêm server (DSN qua env, không hardcode pass)
/mcp add db -- npx -y @bytebase/dbhub --dsn "${DB_DSN}"

# Bước 2: kiểm tra tools
/mcp show db
# → query, list_tables, describe_table

# Bước 3: dùng ngay trong chat
