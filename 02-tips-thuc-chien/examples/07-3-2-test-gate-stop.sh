#!/usr/bin/env bash
# hooks/test-gate.sh — test đỏ không cho kết thúc turn (tối đa 8 blocks là giới hạn)
set -euo pipefail
SCOPE="${TEST_SCOPE:-payments}"
pnpm --filter "$SCOPE" test 2>&1 | tail -n 25
[[ "${PIPESTATUS[0]:-0}" != "0" ]] && { echo "BLOCKED: test $SCOPE còn đỏ. Fix rồi mới kết thúc turn." >&2; exit 2; }
exit 0
