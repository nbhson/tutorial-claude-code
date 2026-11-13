# Session & resume:
claude --fork <id>          # fork session thử what-if, giữ mạch chính

# Non-interactive (CI/scripts):
claude -p "review diff, in findings JSON" \
  --output-format json \    # text | json | stream-json
  --permission-mode dontAsk \
  --allowedTools "Read, Grep, Glob, Bash"
claude --init-only          # chỉ chạy Setup hooks, không mở session (CI warmup)

# Model & effort:
claude --model opus         # opus | sonnet | haiku (đổi giữa session: /model)
claude --effort high        # low | medium | high | xhigh | max | auto (≥2.1.205)
claude --agents '{"reviewer":{"prompt":"...","tools":["Read","Grep"]}}'  # agent inline JSON

# Dirs & sandbox:
claude --add-dir ../shared --add-dir /tmp/contracts
claude --sandbox            # bật OS sandbox (giới hạn FS/network)
claude --safe-mode          # chế độ an toàn thêm (w24/2026)
claude --restricted         # chạy giới hạn tối đa (w35/2026)

# Permissions:
claude --permission-mode plan   # default | acceptEdits | plan | auto | dontAsk | bypassPermissions
claude --disallowedTools "Bash, Write"

# Cloud:
claude --cloud "migrate table X, mở PR" [--model opus]
