# 11 — Git worktrees, checkpoints & parallel sessions sạch

> **Bài này cho ai:** dev muốn mở 2–3 session Claude Code song song không giẫm chân, hoặc tech lead chuẩn hóa cách làm việc song song + cứu session lỡ sửa sai cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](./01-cai-dat-va-xac-thuc.md)); nên đọc [bài 02 — Bề mặt](./02-cac-be-mat-terminal-ide-web-desktop.md) và [bài 06 — Subagents](./06-subagents-agent-teams-parallel.md) trước.
> **Đọc xong bạn làm được:** tạo/dọn worktree theo quy ước, chạy 3 workflow song song copy-paste; chọn đúng lúc rewind / `/branch` / `/fork` / cứ tiếp tục trong 30 giây; ghép worktree + subagent + checkpoint thành pipeline song song.
> **Thời gian:** ~30 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Git worktree | 1 repo, nhiều thư mục checkout song song, mỗi cái 1 branch | `git worktree add ../myrepo-worktrees/feat-login -b feat/login` → verify bằng `git worktree list` |
| Checkpoint / Rewind | Điểm lưu cả code + hội thoại để quay lại khi làm hỏng — như save-game | `Esc Esc` lúc prompt rỗng → chọn checkpoint trước turn bị sai |
| `/branch` | Rẽ 1 bản copy hội thoại để thử hướng khác, giữ bản chính | `/branch thu-y-mao-hiem` → không ưng thì `/resume` về mạch chính |
| `/fork` | Fork session kế thừa full conversation cho side task | Side task chạy subagent mà không làm bẩn mạch chính (fork mode mặc định từ Week 33) |

2 vấn đề song song của agent work:

```text
Vấn đề 1 — Giẫm chân: 2 sessions cùng sửa 1 working dir → conflict, đè file, test flaky.
  → Giải pháp: worktrees (mỗi session 1 checkout riêng, branch riêng).
Vấn đề 2 — Đi sai đường: agent sửa 15 turns vẫn sai, càng sửa càng nát.
  → Giải pháp: checkpoints (undo cả code + conversation về điểm trước khi nát).
```

Git là nguồn sự thật cuối (commit/PR), checkpoints là chỗ hoàn tác local nhanh, worktrees là cách ly không gian — 3 lớp phối hợp, không thay nhau.

---

## 1. Worktrees — song song không giẫm chân

```bash
git worktree add ../myfeature-worktrees/feat-x -b feat/x
claude --add-dir ../myfeature-worktrees/feat-x
# xong việc:
git worktree remove ../myfeature-worktrees/feat-x
```

- Agent view tự đưa mỗi dispatched session vào worktree riêng.
- `/batch` chia việc lớn thành 5–30 subagents, mỗi đứa 1 worktree + 1 PR.
- Subagents bạn spawn cũng có thể xin worktree riêng.
- Quy ước team: thư mục `../<repo>-worktrees/<ten>`, branch `feat/<ten>`, dọn worktree sau merge.

### 1.1. Lệnh worktree căn bản (copy-paste cả đoạn)

```bash
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
```

### 1.2. Vì sao quy ước folder/branch?

```text
../<repo>-worktrees/<ten>  → ngoài repo chính (không pollute git status, .gitignore không cần sửa).
feat/<ten>                 → branch tách main, PR riêng từng worktree.
dọn sau merge              → worktree tồn tại = branch tồn tại = nợ. Merge xong xóa cả 2.
```

---

## 2. Workflow làm việc với worktree (3 mẫu copy-paste)

### Mẫu A — 2 feature song song (phổ biến nhất)

```bash
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
```

### Mẫu B — Thử 2 phương án, giữ cái thắng (spike)

```bash
git worktree add ../myrepo-worktrees/spike-1 -b spike/option-1 origin/main
git worktree add ../myrepo-worktrees/spike-2 -b spike/option-2 origin/main

# Terminal 1: thử JWT-blacklist. Terminal 2: thử server-sessions.
# Mỗi bên implement + test + đo (perf/complexity). So sánh:

# Giữ spike-2, bỏ spike-1:
git worktree remove --force ../myrepo-worktrees/spike-1
git branch -D spike/option-1
# Đổi tên spike-2 thành feat/: git branch -m spike/option-2 feat/sessions
```

### Mẫu C — Agent fan-out (`/batch` / agent view tự tạo worktrees)

```text
# Bạn không tạo tay — Claude tự tạo mỗi subagent 1 worktree + 1 PR:
# > "/batch migrate 50 files từ pages/ sang app/: mỗi subagent 5 files, 1 worktree, 1 PR, chạy focused test"

# Bạn làm: /agents (tab Running) theo dõi → review từng PR → merge → worktrees tự dọn.
# Kill khi fan-out lỗi: Ctrl+X Ctrl+K ×2 trong 3s (dừng hết background subagents).
# Kiểm tra khi batch đang chạy: git worktree list → thấy N entries batch-xxx.
# Đừng xóa tay khi batch đang chạy — batch tự dọn khi xong.
```

---

## 3. Checkpoints — hoàn tác cả code + hội thoại

- **Double-Esc** (prompt rỗng) → rewind menu: khôi phục code + hội thoại về điểm trước đó.
- `/rewind` tương đương gõ lệnh. **Từ Week 26, `/rewind` resume được cả điểm trước khi `/clear`.**
- `/branch` để thử "what-if" mà không mất mạch chính; `/fork` để side task kế thừa full conversation.
- Quy tắc: **sửa 2 lần vẫn sai → đừng cãi tiếp, rewind + re-prompt sạch** (rẻ hơn nhiều turn cãi nhau — quá 15 turn không tiến triển thì dừng, `/clear`, chia nhỏ).
- Checkpoint = hoàn tác local; **Git mới là history thật** — đã commit/push thì dùng git revert/PR mới.

### 3.1. 3 lệnh + khi nào dùng

| Lệnh | Làm gì | Khi nào |
|---|---|---|
| Double-Esc (prompt rỗng) | Mở rewind menu (chọn checkpoint) | Nhanh nhất, dùng hàng ngày |
| `/rewind` | Tương đương menu bằng lệnh | Muốn gõ rõ ràng / môi trường không có Esc (mobile) |
| `/branch <ten>` | Fork conversation (thử what-if, giữ mạch chính) | Thử hướng khác mà không mất mạch đang đúng 50% |
| `/fork` | Side task chạy subagent kế thừa full conversation | Việc phụ cần context chính nhưng không được đụng mạch |

```text
# Ví dụ /branch:
# Đang refactor đúng 50%, muốn thử 1 ý mạo hiểm:
# > /branch thu-y-mao-hiem
# → thử trong branch. Không ưng → /resume mạch chính. Ưng → tiếp tục branch.
```

### 3.2. Cơ chế (checkpoint lưu gì?)

```text
Mỗi checkpoint = snapshot (file changes từ harness + conversation turns).
Rewind = restore cả 2 về điểm đó (code quay lại + turns sau điểm đó biến mất khỏi context).
Khác git checkout: git chỉ restore code; rewind restore cả "trí nhớ" agent về trước khi nát.
Khác /clear: /clear xóa hết bắt đầu mới; rewind giữ lại phần đúng trước điểm nát.
```

---

## 4. Khi nào rewind, khi nào tiếp tục?

| Tình huống | Rewind? | Về đâu? |
|---|---|---|
| Cùng 1 lỗi fail 2–3 lần dù 3 fixes khác nhau | Có | Trước fix 1, re-prompt với thông tin mới |
| Lan scope, diff phình (đụng 10 files khi chỉ cần 2) | Có | Trước khi lan + giao lại scope hẹp |
| Hiểu nhầm yêu cầu từ đầu (agent làm "đúng" prompt nhưng sai ý) | Có | Đầu task + viết lại prompt (mục tiêu + scope + verify + non-goals) |
| Sai 1 dòng, còn lại 9 steps đúng | Không | Sửa trực tiếp hoặc bảo agent sửa dòng X thành Y |
| Muốn thử hướng khác song song | Không (dùng `/branch`) | Fork, giữ mạch chính |
| Task đã commit/push PR rồi | Không (dùng git) | Checkpoint là local — `git revert`/PR mới |

**Re-prompt mẫu sau rewind:** "Test X fail với [paste lỗi đầy đủ]. Lần trước thử A, B, C đều fail. Hãy đọc [file] lại từ đầu, đề xuất root cause KHÁC trước khi sửa."

### 4.1. Rewind vs git — khi nào dùng cái nào?

| Nhu cầu | Dùng | Vì sao |
|---|---|---|
| Undo code CHƯA commit + cả "trí nhớ" agent | Rewind/Double-Esc | Git không restore conversation |
| Undo code ĐÃ commit/push | `git revert` / PR mới | Checkpoint local only |
| Thử hướng khác giữ mạch chính | `/branch` | Rewind mất mạch cũ |
| Bắt đầu mới hoàn toàn | `/clear` | Rewind giữ phần đúng — không cần thì clear |
| So sánh 2 phương án song song | 2 worktrees | Rewind/branch là tuần tự, worktree là song song |
| Mất file do `rm` nhầm chưa commit | Rewind HOẶC `git checkout -- <file>` | Cả 2 được; git nhanh hơn nếu chỉ 1 file |

---

## 5. Kết hợp: song song an toàn

```text
main conversation (quyết định)
 ├─ worktree A + subagent explorer (research)
 ├─ worktree B + subagent implementer (thử phương án 2)
 └─ worktree C (bạn code tay phần critical)
→ so sánh → merge cái thắng → remove worktrees thua
```

Kill switch khi fan-out lỗi: `Ctrl+X Ctrl+K` 2 lần trong 3s dừng hết background subagents.
Theo dõi: `/agents` (Running/Library), `/tasks`.

### 5.1. Walkthrough kết hợp (20 phút)

```bash
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
```

### 5.2. Pitfalls + fix

| Pitfall | Fix |
|---|---|
| Quên dọn worktree → 10 worktrees tồn | Merge xong remove ngay; `git worktree list` cuối tuần |
| 2 sessions cùng dir (không worktree) → conflict | Task song song = worktree riêng, không ngoại lệ |
| Rewind sau khi đã push | Checkpoint local only → git revert/PR mới |
| `/branch` xong quên mạch chính tên gì | `/rename` mạch chính trước khi branch |
| Xóa worktree đang có session mở | Đóng session trước, hoặc `cd` ra rồi remove lại |
| Worktree + `--add-dir` nhầm (load CLAUDE.md sai) | `export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` ([bài 01](./01-cai-dat-va-xac-thuc.md)) hoặc `cd` thẳng vào worktree |

### 5.3. Worktree gotchas (4 cái ai cũng vấp 1 lần)

```bash
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
```

### 5.4. Checklist parallel sessions sạch (dán vào team wiki)

- [ ] Mỗi session 1 worktree + 1 branch `feat/*` (không share working dir).
- [ ] `/rename` mỗi session trước khi fork/branch (không lạc mạch).
- [ ] Env copy tay + ports khác nhau + deps cài riêng mỗi worktree.
- [ ] Merge xong → remove worktree + xóa branch + `git worktree prune`.
- [ ] Sai 2 lần → rewind + re-prompt (không cãi tiếp).
- [ ] Đã push → git revert/PR mới (không rewind).
- [ ] Fan-out lỗi → Ctrl+X Ctrl+K ×2 + `/agents` kiểm tra.

---

## 6. Bài tập + link chéo

**Bài 1 (15 phút):** Tạo 2 worktrees (mẫu A). Mở 2 sessions, mỗi bên làm 1 task nhỏ. `git worktree list` + merge + dọn. Ghi thời gian so với làm tuần tự.

**Bài 2 (15 phút):** Cố ý giao task sai hướng, để agent làm 5 turns, rồi rewind + re-prompt sạch (tình huống 3). So sánh tokens (`/cost`) rewind sớm vs cãi tiếp.

**Bài 3 (25 phút):** Chạy fan-out mini: main + 1 explorer worktree + 1 implementer worktree. Theo dõi `/agents` + kill switch test (Ctrl+X Ctrl+K). Merge thắng, dọn thua. Thêm 1 lần `/fork` side task so với `/branch`.

**Link chéo:** [02 — Bề mặt](./02-cac-be-mat-terminal-ide-web-desktop.md) (`--add-dir`, agent view dispatch) · [04 — Slash commands](./04-slash-commands-toan-tap.md) (`/rewind /branch /fork /resume /rename`) · [06 — Subagents](./06-subagents-agent-teams-parallel.md) (`/batch`, fan-out, kill switch) · [10 — Permissions](./10-permissions-modes-availability.md) (trust/working dirs mỗi worktree) · [12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md) (CI checkout sạch tương đương worktree ephemeral).
