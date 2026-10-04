# 11 — Git Worktrees, Checkpoints & Parallel Sessions Sạch

## 1. Worktrees — song song không giẫm chân

Mỗi session 1 git checkout riêng → 2 agents sửa cùng repo không conflict file.

```bash
git worktree add ../myfeature-worktrees/feat-x -b feat/x
claude --add-dir ../myfeature-worktrees/feat-x
# xong việc:
git worktree remove ../myfeature-worktrees/feat-x
```

- Agent view tự đưa mỗi dispatched session vào worktree riêng.
- `/batch` chia việc lớn thành 5–30 subagents, mỗi đứa 1 worktree + 1 PR.
- Subagents bạn spawn cũng có thể xin worktree riêng.

Quy ước team: thư mục `../<repo>-worktrees/<ten>`, branch `feat/<ten>`, dọn worktree sau merge.

## 2. Checkpoints — undo cho cả code + conversation

- **Double-Esc** (prompt rỗng) → rewind menu: khôi phục code + conversation về điểm trước đó.
- `/rewind` tương đương gõ lệnh. `/branch` để thử "what-if" mà không mất mạch chính.
- Quy tắc: **sửa 2 lần vẫn sai → đừng argue tiếp, rewind + re-prompt sạch** (rẻ hơn 10 turns cãi nhau).
- Checkpoint = undo local; **Git mới là history thật** — commit/PR vẫn là source of truth.

## 3. Kết hợp: song song an toàn

```
main conversation (quyết định)
 ├─ worktree A + subagent explorer (research)
 ├─ worktree B + subagent implementer (thử phương án 2)
 └─ worktree C (bạn code tay phần critical)
→ so sánh → merge cái thắng → remove worktrees thua
```

Kill switch khi fan-out lỗi: `Ctrl+X Ctrl+K` 2 lần trong 3s dừng hết background subagents.
Theo dõi: `/agents` (Running/Library), `/tasks`.
