claude                                  # mở session mới
claude "refactor auth/ theo docs/spec.md"  # vd: giao task ngay khi mở
claude -p "tóm tắt diff main...HEAD"    # vd: headless cho CI (không tương tác)
claude --continue                       # vd: quay lại session gần nhất
claude --resume <id>                    # vd: mở lại session cũ theo id
claude doctor                           # vd: khám duplicate install, settings lỗi
claude agents                           # vd: xem/quản lý subagents đã định nghĩa
claude update && claude --version       # vd: update trước, debug sau
