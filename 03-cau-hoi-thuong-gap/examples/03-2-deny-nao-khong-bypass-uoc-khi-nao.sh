# ✅ Sandbox dùng 1 lần, không secrets thật:
claude -p "migrate test" --dangerously-skip-permissions
# ❌ Máy dev / máy có .env thật — thay bằng:
# --safe-mode (cân bằng an toàn hơn) hoặc --permission-mode dontAsk + allowlist hẹp (FAQ 10)
