#!/bin/bash
# .claude/hooks/block-main-push.sh — block push main/master, force-push, xóa branch remote
set -euo pipefail
INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.input.command // empty')"
if echo "$CMD" | grep -Eq 'git[[:space:]]+push([^&|;]*[[:space:]]|^)(origin[[:space:]]+)?(HEAD:)?(main|master)([[:space:]]|$)'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: không push trực tiếp main. Mở PR từ branch feat/*."}'; exit 2
fi
if echo "$CMD" | grep -Eq '\-\-force($|[[:space:]])|-f([[:space:]]|$)|--force-with-lease'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: force-push bị cấm. Dùng rebase thường."}'; exit 2
fi
if echo "$CMD" | grep -Eq 'git[[:space:]]+push[[:space:]]+[^ ]*[[:space:]]+--delete|:heads/'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: xóa branch remote cần xác nhận tay."}'; exit 2
fi
exit 0
# Test với: git push -f, git push --force, git push --force-with-lease, git push origin HEAD:main.
