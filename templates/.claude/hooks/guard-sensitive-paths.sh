#!/bin/bash
# guard-sensitive-paths.sh — PreToolUse hook cho Write. Block ghi vào paths nhạy cảm.
set -euo pipefail
INPUT=$(cat)
TARGET=$(echo "$INPUT" | python3 -c "
import json,sys
try: d=json.loads(sys.stdin.read())
except Exception: print(''); raise SystemExit
ti=d.get('tool_input') or {}
print(ti.get('file_path', ti.get('path','')))")
case "$TARGET" in
  *src/generated/*|*.pem|*.key|.env*|*db/migrations/*)
    echo "BLOCKED: ghi vào '$TARGET' cần human xác nhận (guard-sensitive-paths)." >&2
    exit 2 ;;
esac
exit 0
