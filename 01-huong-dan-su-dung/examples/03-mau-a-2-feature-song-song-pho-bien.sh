# Setup (5 phút, 1 lần):
git fetch origin
git worktree add ../myrepo-worktrees/feat-a -b feat/a origin/main
git worktree add ../myrepo-worktrees/feat-b -b feat/b origin/main
git worktree list   # xác nhận 3 entries (main + 2 worktrees)

# Terminal 1 (feature A):
cd ../myrepo-worktrees/feat-a && claude
# > "implement login rate-limit theo plan plans/xxx.md, chạy focused test"

# Terminal 2 (feature B):
cd ../myrepo-worktrees/feat-b && claude
# > "migrate users table thêm last_login_at (skill add-table), test local"

# Xong mỗi bên: /diff → commit → push → gh pr create → merge → dọn:
git worktree remove ../myrepo-worktrees/feat-a
git branch -d feat/a
