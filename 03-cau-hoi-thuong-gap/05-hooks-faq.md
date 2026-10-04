# FAQ 05 — Hooks: Vì Sao Không Chạy?

**Xem hooks đang có?** `/hooks` (theo tool events).

**Hook không lửa — check gì?** (1) Đúng event chưa (Pre vs Post vs Stop...). (2) Matcher đúng case chưa
(`Edit` ≠ `edit`, `Bash` ≠ `bash`). (3) Folder trusted chưa (frontmatter hooks cần trust dialog).
(4) Chạy headless (`-p`/background) có gì cần prompt không.

**2 hooks cùng sửa `updatedInput`?** Thằng finish cuối thắng (non-deterministic) — đừng để overlap.

**Stop hook có lửa khi user interrupt?** Không. `Stop` = Claude xong response; interrupt không lửa;
API error lửa `StopFailure`.

**Stop-gate bị override?** Đúng — sau 8 blocks liên tiếp Claude override để thoát. Thiết kế gate hội tụ
(fix được), không phải gate vô hạn.

**Prompt-hook vs agent-hook vs command-hook?** Command (shell) = deterministic, production ưu tiên.
Prompt (LLM 1-turn, Haiku default) = cần judgment từ input. Agent (experimental, 60s/50 turns) = verify
cần đọc code/chạy lệnh. HTTP/MCP-tool cho tích hợp ngoài.

**Hook chạy với quyền gì?** Quyền của bạn (đọc FS, network, ghi disk) → review như production code,
chỉ cài nguồn tin cậy.

**Hook API đổi theo version?** Có (2025–2026 từng đổi `tools` frontmatter, PreToolUse stdin schema...).
Trước khi đặt hook chặn CI push: đối chiếu release notes với version đang chạy (`/status`).
