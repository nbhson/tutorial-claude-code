# Debug tay:
echo '{"tool":"Bash","input":{"command":"git push origin main"}}'    | .claude/hooks/block-main-push.sh; echo "exit=$?"   # kỳ vọng 2
echo '{"tool":"Bash","input":{"command":"git push origin feat/x"}}'  | .claude/hooks/block-main-push.sh; echo "exit=$?"   # kỳ vọng 0
