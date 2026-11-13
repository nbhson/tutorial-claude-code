# Bước 1: tạo 2 worktrees (mẫu B):
git fetch origin
git worktree add ../myrepo-worktrees/opt-1 -b spike/opt-1 origin/main
git worktree add ../myrepo-worktrees/opt-2 -b spike/opt-2 origin/main

# Bước 2: main conversation giao việc:
# > "spawn explorer trong ../myrepo-worktrees/opt-1 research phương án 1, trả 15 dòng.
# >  Đồng thời tao tự thử phương án 2 ở opt-2."

# Bước 3: so sánh — mỗi bên focused test + /diff review. Chọn thắng.

# Bước 4: merge + dọn:
# PR thắng → merge → git worktree remove <thua> + git branch -D <thua>
git worktree list   # xác nhận sạch
