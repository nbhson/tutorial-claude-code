# Tips 05 — Parallel Agents: Nhân 3 Sức Mạnh Mà Không Loạn

## 1. Nguyên tắc fan-out

- **1 subagent = 1 task hẹp** + context cần thiết. Không có "QA agent chung chung".
- Trần **3–5 concurrent**. Hơn → cân nhắc worktrees + sessions riêng hoặc `/batch`.
- Việc song song thật sự độc lập mới fan-out (3 explorers 3 modules khác nhau). Việc nối tiếp nhau
  thì **chain** (explorer → planner → implementer), đừng parallel bừa.

## 2. Bộ 4 recipes chuẩn (copy từ bài 06 phần 1)

```
Explorer (Read/Grep/Glob): research, trả summary + file list ("chỉ files mày sẽ sửa/đọc")
Planner (Write scope plans/): plan markdown, không đụng source
Reviewer (Bash git-read-only + Read): rate diff correctness/coverage/style/security
Tester (Bash test-runner + Read): chạy tests liên quan, pass/fail + 1-line guess
```

Mỗi recipe kèm 1 hook bound nó (xem Tips 06): explorer + hook giới hạn scope, tester + hook giới hạn test command...

## 3. Writer/Reviewer tách context (pattern đắt giá nhất)

```
Main implement → xong → spawn reviewer FRESH (chưa thấy reasoning của writer)
→ reviewer trả gaps → main fix → re-review (nếu cần)
```

→ Reviewer không rationalize code của chính nó. Giữ vòng này cho mọi PR nontrivial.

## 4. Worktrees + `/batch` cho scale

- 2+ streams sửa cùng repo → mỗi stream 1 worktree (`../<repo>-worktrees/<ten>`).
- 1 change lớn lặp pattern (migrate 20 files, thêm test toàn repo) → `/batch` (5–30 worktree-subagents, mỗi đứa 1 PR).
- Agent teams (experimental): lead plan + teammates security/perf/tests song song — bật khi task đủ lớn.

## 5. Vận hành khi fan-out (đừng quên kill switch)

- Theo dõi: `/agents` (Running/Library), `/tasks`.
- Kill all background: `Ctrl+X Ctrl+K` ×2 trong 3s.
- Subagent spawn subagent: cho phép nhưng tiết chế (token cộng dồn theo cấp số nhân).
- Quy tắc kết thúc: subagent trả **quyết định + evidence**, không trả dump 200 dòng log.
