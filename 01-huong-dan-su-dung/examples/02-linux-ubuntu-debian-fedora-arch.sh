# Ubuntu/Debian (Fedora: dnf install curl git gh; Arch: pacman -S curl git github-cli):
sudo apt update && sudo apt install -y curl git gh
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version && claude doctor
