# 1. Untracked files KHÔNG theo worktree — stash/commit WIP trước:
git stash push -m "wip-main" && git worktree add ../myrepo-worktrees/feat-x -b feat/x

# 2. Dependencies phải cài lại mỗi worktree (node_modules/.venv không share):
cd ../myrepo-worktrees/feat-x && pnpm install --frozen-lockfile
# Mẹo: pnpm store shared + Docker layer cache để đỡ tải lại nặng.

# 3. Env files + ports đụng nhau:
cp /path/to/main/.env ../myrepo-worktrees/feat-x/.env   # copy tay, KHÔNG commit .env!
PORT=3001 pnpm dev                                       # mỗi worktree 1 port

# 4. Submodules + LFS không tự init:
git submodule update --init --recursive
git lfs pull   # nếu repo dùng LFS
