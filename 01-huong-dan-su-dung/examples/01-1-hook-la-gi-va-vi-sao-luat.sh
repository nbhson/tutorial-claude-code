mkdir -p .claude/hooks
cat > .claude/hooks/block-main-push.sh <<'EOS'
#!/bin/bash
set -euo pipefail
INPUT="$(cat)"
CMD="$(echo "$INPUT" | jq -r '.input.command // empty')"
if echo "$CMD" | grep -Eq 'git[[:space:]]+push.*(main|master)'; then
  echo '{"permissionDecision":"deny","reason":"BLOCKED: không push trực tiếp main. Mở PR."}'
  exit 2
fi
exit 0
EOS
chmod +x .claude/hooks/block-main-push.sh
# Verify: echo '{"input":{"command":"git push origin main"}}' | .claude/hooks/block-main-push.sh; echo "exit=$?"
