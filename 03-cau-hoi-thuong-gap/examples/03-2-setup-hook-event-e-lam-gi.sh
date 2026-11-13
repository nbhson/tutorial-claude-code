# CI job chuẩn: setup rồi review
claude -p "review diff" --init --output-format json --permission-mode dontAsk \
  --allowedTools "Read Grep Glob Bash(git diff:*)"

# Warm env đêm trước (không tốn task):
claude -p "" --init-only
