#!/usr/bin/env bash
set -euo pipefail
CMD=$(cat | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))")

# Không phải git → cho qua
echo "$CMD" | grep -qE '(^|[;&| ])git ' || exit 0

echo "$CMD" | tr ';' '\n' | sed 's/&&/\n/g; s/||/\n/g' | while IFS= read -r line; do
  if echo "$line" | grep -qE 'git\s+push\b.*(--force-with-lease|--force\b|-f\b)'; then
    echo "BLOCKED: force-push bị cấm. Dùng PR + merge thay vì push -f." >&2; exit 2
  fi
  if echo "$line" | grep -qE 'git\s+push\b.*(\bmain\b|\bmaster\b|HEAD:main|HEAD:master)'; then
    echo "BLOCKED: push thẳng main/master bị cấm. Push feature branch + mở PR." >&2; exit 2
  fi
  if echo "$line" | grep -qE 'git\s+(branch\s+-D|branch\s+--delete|push\b.*--delete)'; then
    echo "BLOCKED: xóa branch cần human duyệt." >&2; exit 2
  fi
done
