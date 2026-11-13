#!/bin/bash
# .claude/hooks/lint-on-write.sh — chỉ lint file vừa sửa, đừng lint cả repo (chậm 8s+)
set -euo pipefail
INPUT="$(cat)"
FILES="$(echo "$INPUT" | jq -r '.input.file_path // .input.path // empty')"
[ -z "$FILES" ] && exit 0
echo "$FILES" | tr ' ' '\n' | grep -E '\.(ts|tsx|js|jsx)$' | while read -r f; do
  [ -f "$f" ] || continue
  npx prettier --write "$f" >/dev/null 2>&1 || true
  npx eslint "$f" --max-warnings 0
done
# eslint fail → exit nonzero → PostToolUseFailure → Claude thấy lỗi, fix ngay.
