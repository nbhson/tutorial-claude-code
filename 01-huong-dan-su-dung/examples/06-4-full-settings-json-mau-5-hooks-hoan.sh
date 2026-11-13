#!/bin/bash
set -euo pipefail
INPUT="$(cat)"
LEDGER="${CLAUDE_PROJECT_DIR:-.}/.claude/cost-ledger.csv"
[ -f "$LEDGER" ] || echo "date,tokens_in,tokens_out,note" > "$LEDGER"
echo "$(date +%F),$(echo "$INPUT" | jq -r '.usage.input_tokens // "?"'),$(echo "$INPUT" | jq -r '.usage.output_tokens // "?"'),stop-event" >> "$LEDGER"
# Quá cap → ping Slack webhook nếu có.
