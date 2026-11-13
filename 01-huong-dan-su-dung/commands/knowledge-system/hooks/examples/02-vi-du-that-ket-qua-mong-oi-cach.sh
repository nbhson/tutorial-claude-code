#!/bin/bash
# lint-stop.sh — model báo xong thì kiểm, fail bắt làm tiếp (tối đa 3 vòng)
COUNT_FILE=/tmp/lint-loop-count
COUNT=$(cat $COUNT_FILE 2>/dev/null || echo 0)
if [ "$COUNT" -ge 3 ]; then echo 0 > $COUNT_FILE; exit 0; fi
if ! uvx ruff check . 2>/dev/null; then
  echo $((COUNT+1)) > $COUNT_FILE
  echo "LINT FAIL — sửa các lỗi trên rồi mới được dừng" >&2
  exit 2   # exit 2 = chặn model dừng, trả stderr về cho nó sửa tiếp
fi
