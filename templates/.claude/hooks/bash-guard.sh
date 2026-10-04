#!/usr/bin/env bash
# bash-guard.sh — PreToolUse guard mẫu cho Bash (bài 15 mục 7, bài 16 mục 7).
# Chạy: nhận tool input JSON qua stdin, lấy trường "command".
# Logic: tách segments trên && || ; | (tôn trọng quotes) → strip VAR=
#   assignments đầu mỗi segment → match deny patterns từ file cấu hình
#   (DENY_FILE, mặc định cùng thư mục: bash-deny-patterns.txt).
# Block: in lý do ra stderr + exit 2. Fail-open: parse lỗi → exit 0.
# Ghi chú: đây là GUARD (chặn cứng), không phải guidance (gợi ý).

set -u
DENY_FILE="${BASH_GUARD_DENY_FILE:-$(dirname "$0")/bash-deny-patterns.txt}"

# --- Đọc command từ JSON stdin (fail-open nếu parse lỗi) ---
CMD=""
if command -v python3 >/dev/null 2>&1; then
  CMD="$(python3 -c 'import json,sys
try:
  print(json.load(sys.stdin).get("command",""))
except Exception:
  print("")' 2>/dev/null)" || CMD=""
else
  # Không có python3: không parse được → fail-open (exit 0).
  exit 0
fi
[ -z "$CMD" ] && exit 0

# --- Tách segments trên && || ; | (tôn trọng single/double quotes) ---
# Kết quả: mỗi segment 1 dòng, đưa vào vòng match bên dưới.
split_segments() {
  python3 -c '
import sys
s = sys.stdin.read()
segs, cur, q = [], [], None
i = 0
while i < len(s):
  c = s[i]
  if q:
    cur.append(c)
    if c == q: q = None
    i += 1
    continue
  if c in ("\"", chr(39)):
    q, cur = c, cur + [c]
    i += 1
    continue
  if s.startswith("&&", i) or s.startswith("||", i):
    segs.append("".join(cur)); cur = []; i += 2
    continue
  if c in ";|":
    segs.append("".join(cur)); cur = []; i += 1
    continue
  cur.append(c); i += 1
segs.append("".join(cur))
print("\n".join(x.strip() for x in segs if x.strip()))
' 2>/dev/null
}

# --- Strip VAR= assignments đầu segment (TZ=.. FOO=bar ...) ---
strip_env_prefix() {
  # Lặp bỏ các token dạng NAME= ở đầu dòng (tôn trọng giá trị đã quote).
  echo "$1" | sed -E 's/^([A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:]]+)[[:space:]]+)+//'
}

SEGMENTS="$(printf '%s' "$CMD" | split_segments)" || exit 0
[ -z "$SEGMENTS" ] && exit 0
[ -f "$DENY_FILE" ] || exit 0  # thiếu file cấu hình → fail-open (log ở CI)

# --- Match từng segment với từng deny pattern (regex, grep -E) ---
while IFS= read -r seg; do
  CLEAN="$(strip_env_prefix "$seg")"
  while IFS= read -r pat; do
    # Bỏ comment (#...) và dòng trống trong file cấu hình.
    pat_trim="$(printf '%s' "$pat" | sed -E 's/#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$pat_trim" ] && continue
    if printf '%s' "$CLEAN" | grep -E -q "$pat_trim" 2>/dev/null; then
      echo "bash-guard: BLOCK segment [$CLEAN] match deny [$pat_trim]" >&2
      exit 2
    fi
  done < "$DENY_FILE"
done <<< "$SEGMENTS"

exit 0
