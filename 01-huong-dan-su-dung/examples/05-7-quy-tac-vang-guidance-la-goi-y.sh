# Ví dụ enforcement cứng cho secret: .claude/hooks/block-secrets.sh
# (PreToolUse Write|Edit) → exit 2 khi match AKIA... / private key — kể cả
# bypassPermissions cũng không qua. Bật onFailure: "block" (≥2.1.295): hook
# lỗi/timeout thì chặn — guardrail phải fail closed. Viết hook: bài 07.
