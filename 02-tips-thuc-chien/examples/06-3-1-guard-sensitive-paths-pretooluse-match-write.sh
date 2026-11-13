#!/usr/bin/env bash
# hooks/guard-paths.sh — block writes vào vùng cấm
set -euo pipefail
FILE=$(cat | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")case "$FILE" in
  *migrations/*|*.pem|*.key|.env*|*generated*|*dist/*)
    echo "BLOCKED: $FILE là vùng cấm. Muốn sửa cần human duyệt + ghi lý do vào PR." >&2
    exit 2 ;;
esac
exit 0
