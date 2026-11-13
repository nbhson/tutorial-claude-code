#!/usr/bin/env bash
# Lint file vừa edit. Đọc tool input từ stdin JSON, lấy file path.
set -euo pipefail
FILE=$(cat | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")

# Bỏ qua file không cần lint / ngoài project
case "$FILE" in
  ""|*.md|*.json|*generated*|*.min.js|*node_modules*|*.git/*) exit 0 ;;
esac

if [[ "$FILE" == *.ts || "$FILE" == *.tsx || "$FILE" == *.js ]]; then
  npx prettier --check "$FILE" 2>&1 || npx prettier --write "$FILE" 2>&1
  npx eslint "$FILE" 2>&1 || exit 2
fi

exit 0
# exit 0 = cho qua, exit 2 = báo lỗi cho agent (block + hiện output)
