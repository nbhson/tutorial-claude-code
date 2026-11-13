# Cách A — native (khuyến nghị):
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # installer thường tự thêm
claude --version && which -a claude

# Cách B — Homebrew:
brew install --cask claude-code
