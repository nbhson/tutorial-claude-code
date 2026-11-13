/config --scope managed
# → {"deny": ["Bash(sudo:*)", "MCP(external-*)"], "region": "eu-west", ...}
# → À, công ty cấm sudo + MCP ngoài. Khỏi thắc mắc, khỏi tìm cách gỡ (gỡ không được).

/config --scope project
# → baseline team: deny rm-rf, allow test/lint (đi theo git, đã có sẵn)
