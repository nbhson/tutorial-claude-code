# Tips 06 — Hooks Recipes: Biến Mọi Rule Hay Quên Thành Luật

## 1. Triết lý 1 dòng

> **Rule bị miss 2 lần → viết thành hook.** Hooks chạy ngoài model: 0 tokens, không bị thuyết phục.

## 2. Ba recipes bắt buộc (code mẫu trong `templates/`)

### a) Lint-on-write — `PostToolUse` match `Edit|Write`

Sau mỗi edit: chạy prettier/eslint đúng file vừa đổi. Lỗi → trả cho agent fix ngay turn sau.
→ Không bao giờ dồn thành cleanup 40 files cuối tuần.

### b) Branch-protect — `PreToolUse` match `Bash`

Parse command, block: push lên `main`, mọi force-push (`-f/--force/--force-with-lease`),
xóa branch, `push origin HEAD:main`. **Match theo intent, không substring.**
Test 4 ca trước khi tin: `push -f`, `push --force`, `push --force-with-lease`, `push origin HEAD:main`.

### c) Cost-cap — `Stop`

Đọc token usage từ logs → quy $ theo pricing hiện tại → append daily ledger → quá cap ping Slack.
→ Bảo hiểm rẻ nhất trong list, add sớm bất kể project lớn nhỏ.

## 3. Ba recipes nâng cao

- **Guard sensitive paths** (`PreToolUse` Write): block writes vào `migrations/`, `*.pem`, `.env*`, `generated/`.
- **Test-gate** (`Stop`): script chạy focused tests, block turn-end tới khi xanh (tối đa 8 lần).
- **SessionStart inject**: tự nạp branch hiện tại, ticket liên quan, `git status` tóm tắt vào context.

## 4. Prompt-hooks vs agent-hooks vs command-hooks

| Loại | Khi dùng |
|---|---|
| `command` (shell, default) | Mọi thứ deterministic — production ưu tiên |
| `prompt` (LLM 1-turn, Haiku default) | Quyết định cần judgment từ input data (vd commit msg có leak secret?) |
| `agent` (experimental, 60s/50 turns) | Verify cần đọc code/chạy lệnh thật |
| `http` / `mcp_tool` | POST ra ngoài / gọi MCP tool trong hook |

## 5. Bẫy thường gặp

- Matcher case-sensitive, sai event (Pre vs Post) → `/hooks` kiểm tra.
- 2 hooks cùng rewrite `updatedInput` → thằng finish cuối thắng (non-deterministic) → đừng overlap.
- `-p` non-interactive + background subagents: một số prompt flows không hiện → thiết kế hooks
  chạy được headless.
- Hooks là production code (chạy quyền của bạn): review như code, version như code,
  diff API theo version Claude (`tools` frontmatter, PreToolUse stdin schema từng đổi 2025–2026 —
  đối chiếu release notes trước khi đặt hook chặn CI push).
