# Mỗi stream 1 worktree (copy-paste, đổi tên)
git worktree add ../myrepo-worktrees/stream-refund -b feat/refund
git worktree add ../myrepo-worktrees/stream-cart -b feat/cart-promo
git worktree remove ../myrepo-worktrees/stream-cart  # mỗi stream 1 session riêng; xong thì remove
