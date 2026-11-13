# CI review an toàn: pre-approve read-only + lệnh hẹp, mode dontAsk
claude -p "review diff" \
  --permission-mode dontAsk \
  --allowedTools "Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(npm test:*)" \
  --output-format json

# Background subagent research (read-only tuyệt đối):
claude -p "quét auth flow" \
  --permission-mode dontAsk \
  --allowedTools "Read Grep Glob" \
  --output-format json
