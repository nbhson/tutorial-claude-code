claude -p "review diff origin/main...HEAD, chỉ báo security + sai logic, bỏ style. Trả JSON." \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(npm test:*)"
