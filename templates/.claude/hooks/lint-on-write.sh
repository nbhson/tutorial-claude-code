#!/bin/bash
# lint-on-write.sh — PostToolUse hook cho Edit|Write. Đọc JSON từ stdin, lint file vừa đổi.
# Input JSON có file path (CLAUDE_FILE_PATHS hoặc tool_input.file_path tùy version) — script này
# xử lý cả 2 dạng để tương thích rộng.
set -euo pipefail
INPUT=$(cat)
FILES=$(echo "$INPUT" | python3 -c "
import json,sys,os
raw=sys.stdin.read()
try: d=json.loads(raw)
except Exception: print(''); raise SystemExit
paths=[]
v=os.environ.get('CLAUDE_FILE_PATHS','')
if v: paths=v.split()
ti=d.get('tool_input') or {}
for k in ('file_path','path','filename'):
    if ti.get(k): paths.append(ti[k])
print('\n'.join(dict.fromkeys(paths)))
" <<< "$INPUT")

[ -z "${FILES:-}" ] && exit 0
echo "$FILES" | while read -r f; do
  case "$f" in
    *.ts|*.tsx|*.js|*.jsx) npx --no-install prettier --check "$f" 2>/dev/null || npx prettier --write "$f" ;;
    *.py) ruff check "$f" 2>/dev/null || true ;;
  esac
done
exit 0
