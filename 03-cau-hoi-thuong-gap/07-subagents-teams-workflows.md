# FAQ 07 — Subagents, Agent Teams & Workflows

**Khi nào dùng subagent vs làm trực tiếp?** Task phụ đọc nhiều/ồn/không cần nhớ → subagent.
Việc 1 bước ít file → trực tiếp (đỡ ~20k overhead). Chuẩn "làm theo" → skill, không phải worker.

**Subagent có thấy history không?** Mặc định không (fresh context + system prompt + tools riêng).
Forked subagent = kế thừa full conversation (cách spawn, không phải surface riêng).

**Skill `context: fork` là gì?** Skill chạy trong subagent cô lập (không thấy history).
Agent `Explore`/`Plan` khi fork còn skip CLAUDE.md + git status để gọn.

**Gọi subagent thế nào?** Tự động (description khớp) hoặc explicit ("dùng subagent X làm Y"),
`--agent <ten>` (cả session), `--agents '{...}'` (inline JSON).

**Subagent spawn subagent được?** Được, nhưng tiết chế (token cộng dồn). Giới hạn `maxTurns`, `maxTurns`...

**Agent teams là gì?** Lead plan + assign + supervise teammates (experimental, tắt mặc định).
Dùng cho feature lớn, debug đa giả thuyết, review song song (security/perf/tests).

**`/batch` là gì?** Skill/workflow chia 1 change lớn thành 5–30 worktree-subagents, mỗi đứa 1 PR.
Khác agent teams ở chỗ có script giữ plan + verify chéo.

**Theo dõi/kill background agents?** `/agents` (Running/Library), `/tasks`. Kill all: `Ctrl+X Ctrl+K` ×2 trong 3s.

**Worktrees để làm gì?** Mỗi session 1 checkout riêng → song song không giẫm file. Agent view/`/batch` tự tạo;
tay thì `git worktree add ../xxx-worktrees/<ten> -b feat/<ten>`, xong `git worktree remove`.
