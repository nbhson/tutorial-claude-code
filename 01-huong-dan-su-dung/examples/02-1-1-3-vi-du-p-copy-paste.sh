# Ví dụ 1 — review JSON (parse bằng jq cho step sau)
claude -p "review git diff main...HEAD, output JSON: {findings: [{severity, file, line, msg, fix}]}" \
  --output-format json --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash" | jq '.findings'

# Ví dụ 2 — healthcheck MCP (≥2.1.205): gắn vào CI warmup, MCP down → fail fast
claude -p "/mcp" --output-format text
