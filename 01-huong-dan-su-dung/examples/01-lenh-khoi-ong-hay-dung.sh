claude                     # session interactive
claude "fix failing tests" # 1-shot prompt
claude -p "summarize diff" # print mode, non-interactive (CI/scripts, bài 12)
claude --continue          # tiếp tục session gần nhất
claude --resume <id|name>  # resume theo id/name (không truyền id → mở picker)
claude --agent explore     # chạy cả session dưới 1 subagent persona (bài 06)
claude --add-dir ../shared # truy cập thêm thư mục ngoài CWD
claude --cloud             # ném session lên cloud (cần GitHub + /web-setup)
