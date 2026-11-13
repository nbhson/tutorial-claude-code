#!/bin/bash
set -euo pipefail
INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.input.file_path // .input.path // empty')"
case "$FILE" in *db/migrations/*|*prisma/migrations/*) ;; *) exit 0 ;; esac
if git ls-files --error-unmatch "$FILE" >/dev/null 2>&1; then
  echo "{\"permissionDecision\":\"deny\",\"reason\":\"BLOCKED: $FILE đã merge. Viết migration MỚI.\"}"; exit 2
fi
