#!/bin/bash
set -euo pipefail
BRANCH="$(git branch --show-current 2>/dev/null || echo '?')"
STATUS="$(git status --short 2>/dev/null | head -5 || true)"
jq -n --arg b "$BRANCH" --arg s "$STATUS" \
  '{additionalContext: ("Branch: \($b)\nGit status (top5):\n\($s)\nNhắc: chạy focused test sau sửa, không push main.")}'
