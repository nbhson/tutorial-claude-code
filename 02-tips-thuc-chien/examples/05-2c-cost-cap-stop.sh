#!/usr/bin/env bash
set -euo pipefail
DAILY_CAP_USD="${DAILY_CAP_USD:-20}"
LEDGER_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/ledger"
PRICE_INPUT_PER_1K="${PRICE_INPUT_PER_1K:?điền giá input/1K hiện tại}"
PRICE_OUTPUT_PER_1K="${PRICE_OUTPUT_PER_1K:?điền giá output/1K hiện tại}"

mkdir -p "$LEDGER_DIR"; LEDGER="$LEDGER_DIR/cost-$(date +%F).jsonl"
INPUT=$(cat)
# Stop hook nhận usage tùy version — parse defensive
TOKENS_IN=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('input_tokens',0))" 2>/dev/null || echo 0)
TOKENS_OUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)

COST=$(python3 -c "print($TOKENS_IN/1000*$PRICE_INPUT_PER_1K + $TOKENS_OUT/1000*$PRICE_OUTPUT_PER_1K)")
echo "{\"ts\":\"$(date -Is)\",\"in\":$TOKENS_IN,\"out\":$TOKENS_OUT,\"cost_usd\":$COST}" >> "$LEDGER"
TOTAL=$(python3 -c "import json; print(sum(json.loads(l).get('cost_usd',0) for l in open('$LEDGER')))")
if python3 -c "import sys; sys.exit(0 if $TOTAL > float('$DAILY_CAP_USD') else 1)"; then
  echo "Cost-cap: hôm nay đã $TOTAL USD (cap $DAILY_CAP_USD). Session tiếp nên /clear + model rẻ cho explore." >&2
  # Không block (exit 0) — chỉ cảnh báo. Muốn chặn cứng thì exit 2, ping Slack bằng curl nếu cần.
fi
exit 0
