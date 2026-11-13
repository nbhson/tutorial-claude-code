# Tạo (branch mới từ HEAD hiện tại):
git worktree add ../myrepo-worktrees/feat-login -b feat/login

# Tạo từ branch remote/main mới nhất:
git fetch origin
git worktree add ../myrepo-worktrees/feat-pay -b feat/pay origin/main

# Liệt kê + kiểm tra:
git worktree list
git worktree list --porcelain

# Mở session trong worktree:
cd ../myrepo-worktrees/feat-login && claude
# Hoặc từ repo chính cho phép truy cập:
claude --add-dir ../myrepo-worktrees/feat-login

# Dọn (sau merge):
git worktree remove ../myrepo-worktrees/feat-login        # worktree sạch
git worktree remove --force ../myrepo-worktrees/feat-login # có changes chưa commit (cẩn thận!)
git worktree prune    # dọn metadata worktree đã xóa tay
