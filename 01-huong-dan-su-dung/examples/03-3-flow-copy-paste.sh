# 1 — Đọc hiểu, không cho sửa (an toàn tuyệt đối):
claude --permission-mode plan "đọc apps/api/src/routes/login.ts, giải thích flow auth, không sửa gì"

# 2 — Shared lib ngoài repo (monorepo tách folder):
claude --add-dir ../shared-contracts
# > "Đọc types trong ../shared-contracts, đối chiếu apps/api usage, báo mismatch."
# Load CLAUDE.md của add-dir: export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 (bài 01)

# 3 — CI one-shot review:
claude -p "review git diff main...HEAD, in tối đa 10 findings" \
  --output-format text --permission-mode dontAsk --allowedTools "Read, Grep, Glob, Bash"
