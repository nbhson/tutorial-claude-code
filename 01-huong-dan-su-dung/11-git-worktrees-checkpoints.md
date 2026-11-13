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

Mục này nói về cách chia không gian làm việc: mỗi session một thư mục riêng, một branch riêng — như mỗi người một bàn làm việc, khỏi rớt tài liệu của nhau.

> 📄 **Code ví dụ:** [`examples/01-1-worktrees-song-song-khong-giam-chan.sh`](examples/01-1-worktrees-song-song-khong-giam-chan.sh)

- Agent view tự đưa mỗi dispatched session vào worktree riêng.
- `/batch` chia việc lớn thành 5–30 subagents, mỗi đứa 1 worktree + 1 PR.
- Subagents bạn spawn cũng có thể xin worktree riêng.
- Quy ước team: thư mục `../<repo>-worktrees/<ten>`, branch `feat/<ten>`, dọn worktree sau merge.

### 1.1. Lệnh worktree căn bản (copy-paste cả đoạn)

> 📄 **Code ví dụ:** [`examples/02-1-1-lenh-worktree-can-ban-copy-paste.sh`](examples/02-1-1-lenh-worktree-can-ban-copy-paste.sh)

### 1.2. Vì sao quy ước folder/branch?

```text
../<repo>-worktrees/<ten>  → ngoài repo chính (không pollute git status, .gitignore không cần sửa).
feat/<ten>                 → branch tách main, PR riêng từng worktree.
dọn sau merge              → worktree tồn tại = branch tồn tại = nợ. Merge xong xóa cả 2.
```

> **Tóm gọn 1 câu:** Worktree là "mỗi session một phòng làm việc riêng" — cùng một repo nhưng không ai đụng file của ai.

---

## 2. Workflow làm việc với worktree (3 mẫu copy-paste)

Mục này đưa 3 công thức làm việc song song sẵn sàng dùng: 2 feature cùng lúc, thử 2 phương án, và để agent tự chia việc. Chọn đúng mẫu cho tình huống của bạn rồi dán vào terminal.

### Mẫu A — 2 feature song song (phổ biến nhất)

> 📄 **Code ví dụ:** [`examples/03-mau-a-2-feature-song-song-pho-bien.sh`](examples/03-mau-a-2-feature-song-song-pho-bien.sh)

### Mẫu B — Thử 2 phương án, giữ cái thắng (spike)

> 📄 **Code ví dụ:** [`examples/04-mau-b-thu-2-phuong-an-giu-cai.sh`](examples/04-mau-b-thu-2-phuong-an-giu-cai.sh)

### Mẫu C — Agent fan-out (`/batch` / agent view tự tạo worktrees)

```text
# Bạn không tạo tay — Claude tự tạo mỗi subagent 1 worktree + 1 PR:
# > "/batch migrate 50 files từ pages/ sang app/: mỗi subagent 5 files, 1 worktree, 1 PR, chạy focused test"

# Bạn làm: /agents (tab Running) theo dõi → review từng PR → merge → worktrees tự dọn.
# Kill khi fan-out lỗi: Ctrl+X Ctrl+K ×2 trong 3s (dừng hết background subagents).
# Kiểm tra khi batch đang chạy: git worktree list → thấy N entries batch-xxx.
# Đừng xóa tay khi batch đang chạy — batch tự dọn khi xong.
```

> **Tóm gọn 1 câu:** Ba mẫu — chạy 2 việc song song, so 2 phương án, và fan-out cho agent tự làm — đều quy về một nguyên tắc: một việc, một worktree.

---

## 3. Checkpoints — hoàn tác cả code + hội thoại

Mục này nói về "nút save-game" của Claude Code: quay lại cả code lẫn đoạn hội thoại về trước thời điểm mọi thứ bắt đầu nát.

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

> **Cách đọc bảng này:** đọc từ trên xuống theo tần suất dùng — Double-Esc là hàng ngày, `/branch` và `/fork` chỉ khi cần rẽ nhánh; cột "Khi nào" là chỗ tra nhanh khi phân vân chọn lệnh nào.

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

> **Tóm gọn 1 câu:** Checkpoint là nút save-game hoàn tác cả code lẫn "trí nhớ" agent — nhưng đã commit/push thì chơi theo luật git.

---

## 4. Khi nào rewind, khi nào tiếp tục?

Mục này là bảng quyết định: tình huống bạn đang gặp thì nên rewind hay cứ đi tiếp — tránh rewind oan những lúc chỉ cần sửa 1 dòng.

| Tình huống | Rewind? | Về đâu? |
|---|---|---|
| Cùng 1 lỗi fail 2–3 lần dù 3 fixes khác nhau | Có | Trước fix 1, re-prompt với thông tin mới |
| Lan scope, diff phình (đụng 10 files khi chỉ cần 2) | Có | Trước khi lan + giao lại scope hẹp |
| Hiểu nhầm yêu cầu từ đầu (agent làm "đúng" prompt nhưng sai ý) | Có | Đầu task + viết lại prompt (mục tiêu + scope + verify + non-goals) |
| Sai 1 dòng, còn lại 9 steps đúng | Không | Sửa trực tiếp hoặc bảo agent sửa dòng X thành Y |
| Muốn thử hướng khác song song | Không (dùng `/branch`) | Fork, giữ mạch chính |
| Task đã commit/push PR rồi | Không (dùng git) | Checkpoint là local — `git revert`/PR mới |

> **Cách đọc bảng này:** tìm dòng khớp tình huống của bạn, cột giữa trả lời có rewind không, cột cuối chỉ "về đâu" — đọc đúng một dòng là đủ, không cần học thuộc cả bảng.

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

> **Tóm gọn 1 câu:** Sai lặp lại, lan scope, hiểu sai ý → rewind; sai nhỏ, đã commit, muốn thử song song → đừng rewind.

---

## 5. Kết hợp: song song an toàn

Mục này ghép 2 mảnh trước đó (worktree + checkpoint) thành một dây chuyền: nhiều worktree chạy song song, cái nào thắng merge cái đó.

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

> 📄 **Code ví dụ:** [`examples/05-5-1-walkthrough-ket-hop-20-phut.sh`](examples/05-5-1-walkthrough-ket-hop-20-phut.sh)

### 5.2. Pitfalls + fix

| Pitfall | Fix |
|---|---|
| Quên dọn worktree → 10 worktrees tồn | Merge xong remove ngay; `git worktree list` cuối tuần |
| 2 sessions cùng dir (không worktree) → conflict | Task song song = worktree riêng, không ngoại lệ |
| Rewind sau khi đã push | Checkpoint local only → git revert/PR mới |
| `/branch` xong quên mạch chính tên gì | `/rename` mạch chính trước khi branch |
| Xóa worktree đang có session mở | Đóng session trước, hoặc `cd` ra rồi remove lại |
| Worktree + `--add-dir` nhầm (load CLAUDE.md sai) | `export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` ([bài 01](./01-cai-dat-va-xac-thuc.md)) hoặc `cd` thẳng vào worktree |

> **Tóm gọn 1 câu:** Song song an toàn = mỗi việc một worktree, mỗi session một tên, sai thì rewind sớm — còn đã push thì về với git.

### 5.3. Worktree gotchas (4 cái ai cũng vấp 1 lần)

> 📄 **Code ví dụ:** [`examples/06-5-3-worktree-gotchas-4-cai-ai-cung.sh`](examples/06-5-3-worktree-gotchas-4-cai-ai-cung.sh)

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
