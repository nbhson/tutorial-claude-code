#!/bin/bash
# cost-ledger.sh — Stop hook. Append 1 dòng vào daily ledger (mở rộng: parse logs ra tokens/$).
set -euo pipefail
LEDGER="${CLAUDE_PROJECT_DIR:-.}/.claude-cost-ledger.csv"
[ -f "$LEDGER" ] || echo "date,session,tokens_in,tokens_out,usd_note" > "$LEDGER"
echo "$(date +%F),session-end,?,? (nối parser logs của bạn ở đây)" >> "$LEDGER"
# Quá cap ngày → ping Slack (điền webhook + ngưỡng của bạn):
# TOTAL=$(...); [ "$TOTAL" -gt 50 ] && curl -s -X POST "$SLACK_WEBHOOK" -d '{"text":"Claude cost vượt cap"}'
exit 0
