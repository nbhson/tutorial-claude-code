git worktree add ../myrepo-worktrees/feat-auth -b feat/auth
git worktree list
# → thấy 2 dòng: checkout gốc + ../myrepo-worktrees/feat-auth (feature riêng)
git worktree remove ../myrepo-worktrees/feat-auth   # xong việc
