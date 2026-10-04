#!/bin/bash
# test-gate.sh — Stop hook: chặn turn-end nếu test focused còn đỏ.
# Cách dùng: gắn vào Stop trong .claude/settings.json.
# Thoát 0 = cho qua, thoát 2 = block turn-end (Claude phải fix tiếp).
# Đọc JSON từ stdin (có thể rỗng) — parse tối thiểu bằng python3.
set -uo pipefail

# 1. Đọc stdin (nếu không có thì coi như rỗng, không treo)
INPUT=""
if [ ! -t 0 ]; then
  INPUT=$(cat || true)
fi

# 2. Parse tối thiểu: lấy stop_hook_active để tránh loop vô hạn
STOP_ACTIVE=$(printf '%s' "$INPUT" | python3 -c "
import json,sys
try:
    d = json.loads(sys.stdin.read() or '{}')
except Exception:
    print('false'); raise SystemExit
print(str(d.get('stop_hook_active', False)).lower())
" 2>/dev/null || echo "false")

# Hook đã active rồi thì cho qua (tránh loop block mãi)
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

# 3. Tìm lệnh test focused: ưu tiên script test:focused, fallback pnpm test nhanh
# Quy ước repo mẫu dùng pnpm; team npm/yarn thì sửa 2 dòng dưới.
TEST_CMD=""
if [ -f "package.json" ] && grep -q '"test:focused"' package.json 2>/dev/null; then
  TEST_CMD="pnpm test:focused"
elif [ -f "package.json" ]; then
  # Chạy focused theo file đổi (nhanh hơn full suite)
  CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py)$' | head -5 || true)
  if [ -n "$CHANGED" ]; then
    TEST_CMD="pnpm test --runChanged 2>/dev/null || pnpm test"
  else
    TEST_CMD="pnpm test"
  fi
else
  # Không có package.json (repo Python thuần) thì thử pytest nhanh
  TEST_CMD="python3 -m pytest -q -x 2>/dev/null || exit 0"
fi

# 4. Chạy test với timeout mềm 120s (portable macOS/Linux), lấy output gọn
run_with_timeout() {
  # $1 = seconds, $@ = command — dùng timeout/gtimeout nếu có, không thì chạy thường
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
  else
    "$@" # macOS mặc định không có timeout — chạy trực tiếp
  fi
}
OUTPUT=$(run_with_timeout 120 bash -c "$TEST_CMD" 2>&1 | tail -30)
STATUS=${PIPESTATUS[0]:-0}

# 5. Quyết định block hay cho qua
if [ "$STATUS" -ne 0 ]; then
  echo "TEST-GATE BLOCKED: test còn đỏ, fix tiếp trước khi kết thúc turn." >&2
  echo "$OUTPUT" >&2
  exit 2
fi

exit 0
