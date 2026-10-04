#!/bin/bash
# block-main-push.sh — PreToolUse hook cho Bash. Block push main / force-push / xóa branch.
# Match theo intent (regex), không substring. Exit != 0 (hoặc JSON deny) để block.
set -euo pipefail
INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import json,sys
try: d=json.loads(sys.stdin.read())
except Exception: print(''); raise SystemExit
ti=d.get('tool_input') or {}
print(ti.get('command',''))")

echo "$CMD" | grep -Eq 'git[[:space:]]+push.*(--force|-f|--force-with-lease)' && \
  { echo "BLOCKED: force-push bị cấm (dù --force-with-lease)."; exit 2; }
echo "$CMD" | grep -Eq 'git[[:space:]]+push.*(HEAD:main|origin[[:space:]]+main|refs/heads/main)' && \
  { echo "BLOCKED: push trực tiếp main bị cấm. Mở PR."; exit 2; }
echo "$CMD" | grep -Eq 'git[[:space:]]+(branch[[:space:]]+-D|branch[[:space:]]+--delete|push[[:space:]]+.*--delete)' && \
  { echo "BLOCKED: xóa branch cần human xác nhận."; exit 2; }
exit 0
