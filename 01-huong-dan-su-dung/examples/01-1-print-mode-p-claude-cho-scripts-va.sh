# Non-interactive, output text/JSON — giữ guardrails chặt chẽ
claude -p "review diff và in findings dạng JSON" \
  --output-format json \
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"
