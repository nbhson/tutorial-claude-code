# Cài native:
curl -fsSL https://claude.ai/install.sh | bash
claude --version

# Soi + dọn duplicate:
which -a claude
npm ls -g @anthropic-ai/claude-code 2>/dev/null
claude doctor   # phát hiện duplicate install, settings parse lỗi, PATH lỗi

# Dọn: giữ native, gỡ npm
npm uninstall -g @anthropic-ai/claude-code
hash -r
which claude    # giờ chỉ còn 1
claude update
