# Templates — copy-paste dùng ngay

> Thư mục này chứa bộ khung `.claude/` + `CLAUDE.md` + `.mcp.json` (kèm workflow CI mẫu, tùy chọn) để copy vào project thật.
> **Cho ai:** dev/tech lead muốn dựng nhanh cấu hình Claude Code cho một repo mà chưa muốn viết từ đầu.
> **Cách dùng:** copy khung về repo đích, sửa tên/lệnh cho khớp repo là chạy được. Setup mất ~15 phút.

Hãy hình dung thư mục này như dãy nhà mẫu trong khu đô thị mới: đi xem từng mẫu, chọn mẫu hợp nhà mình, mang về và sơn lại theo màu đội — đừng xây từ móng.

## Từng file/folder là gì (đọc bảng này trước khi copy)

| Đường dẫn | Để làm gì (1 câu) | Khi nào đụng tới |
|---|---|---|
| `CLAUDE.md` | Bộ nhớ dài hạn: stack, lệnh verified, quy ước code | Sửa đầu tiên khi copy sang repo mới |
| `.claude/skills/deploy/SKILL.md` | Skill mẫu: deploy staging/prod (dry-run + smoke test) | Khi cần procedure dài gọi bằng `/deploy` |
| `.claude/skills/review-pr/SKILL.md` | Skill review PR: lấy diff + checklist correctness/security/tests | Gọi `/review-pr 123` hoặc `/review-pr main...HEAD` |
| `.claude/skills/add-table/SKILL.md` | Skill tạo bảng Postgres: migration + RLS + test | Gọi `/add-table ten_bang` |
| `.claude/agents/security-reviewer.md` | Agent review bảo mật (chỉ đọc) | Auto khi diff chạm auth/input/crypto |
| `.claude/agents/explorer.md` | Agent trinh sát chỉ-đọc, trả về list files sẽ sửa/đọc | Đầu task multi-file, trước khi plan |
| `.claude/agents/tester.md` | Agent chạy test focused, báo PASS/FAIL + guess 1 dòng | Sau mỗi change, trước khi commit |
| `.claude/rules/mobile-swift.md` | Rule mẫu cho `apps/mobile/**` (SwiftUI + Localizable) | Khi có app mobile Swift |
| `.claude/rules/backend-api.md` | Rule cho `apps/api/**`: error shape, controller mỏng, test bắt buộc | Khi có API backend |
| `.claude/settings.json` | Đăng ký hooks (lint, guard, ledger, notification) | Sửa khi thêm/bớt hook |
| `.claude/hooks/lint-on-write.sh` | PostToolUse: lint/format file vừa Edit/Write | Tự chạy sau mỗi Edit/Write |
| `.claude/hooks/block-main-push.sh` | PreToolUse Bash: chặn push trực tiếp lên main | Tự chạy trước lệnh Bash nguy hiểm |
| `.claude/hooks/guard-sensitive-paths.sh` | PreToolUse Write: chặn ghi vào path nhạy cảm | Tự chạy trước Write |
| `.claude/hooks/cost-ledger.sh` | Stop: ghi sổ token/cost mỗi turn | Tự chạy khi turn kết thúc |
| `.claude/hooks/test-gate.sh` | Stop: chạy `pnpm test` focused, đỏ thì exit 2 để block | Tự chạy khi turn kết thúc |
| `.claude/hooks/bash-guard.sh` | PreToolUse Bash: tách câu lệnh + chặn lệnh khớp pattern cấm | Tự chạy trước lệnh Bash nguy hiểm |
| `.claude/security-patterns.json` | Rule pattern cho plugin `security-guidance` (secrets, code rủi ro) | Sửa khi thêm/bớt rule security |
| `.claude/claude-security-guidance.md` | Threat model + checklist bảo mật của repo bạn | Điền khi dựng stack security |
| `.github/workflows/*.yml` | Workflow CI mẫu (review PR, triage issue) — **tùy chọn** | Copy riêng khi muốn CI đọc PR tự động |
| `.mcp.json` | Khai báo MCP servers (DB, GitHub...) — secrets qua env, không hardcode | Sửa URL/token theo môi trường |

> **Cách đọc bảng này:** mỗi dòng là một file/folder mẫu; cột "Để làm gì" trả lời nó là gì, cột "Khi nào đụng tới" trả lời lúc nào cần bận tâm — khi copy, cứ đi từng dòng và quyết định giữ/bỏ/sửa.

## Cách copy vào project (3 bước copy-paste)

> 📄 **Code ví dụ:** [`examples/01-cach-copy-vao-project-3-buoc-copy-paste.sh`](examples/01-cach-copy-vao-project-3-buoc-copy-paste.sh)

## Thứ tự setup khuyên dùng (15 phút, làm đúng thứ tự này)

Mục này là lộ trình dựng 15 phút: thứ tự bên dưới được xếp theo độ ưu tiên — làm lệch thứ tự dễ xây phòng khách trước móng nhà.

1. **CLAUDE.md trước (5')**: sửa stack + 4 lệnh Dev/Build/Test/Full-check (chỉ ghi lệnh đã chạy thử).
2. **Rules theo path (2')**: giữ `backend-api.md` nếu có `apps/api/`, giữ `mobile-swift.md` nếu có app Swift; xóa cái không dùng.
3. **Agents (2')**: giữ `explorer` + `tester` (dùng mỗi ngày), giữ `security-reviewer` nếu có auth/payment.
4. **Skills (3')**: giữ `deploy` nếu team có deploy script; giữ `review-pr`, `add-table` nếu đúng stack Postgres + GitHub.
5. **Hooks (2')**: bật `lint-on-write` + `guard-sensitive-paths` trước; thêm `test-gate.sh` vào `Stop` trong `settings.json` khi muốn chặn turn-end lúc test đỏ.
6. **MCP (1')**: sửa `.mcp.json` (URL + token qua env, không hardcode), rồi `/mcp` để test kết nối.
7. **Verify cuối**: nhờ Claude làm 1 task nhỏ end-to-end (sửa 1 handler + chạy test + review) để chắc mọi mảnh đều chạy.

> Nếu vẫn lỗi: `/doctor` trước (quét settings/MCP), rồi `/debug` trong session, rồi mới sửa tay từng file.

> **Tóm gọn 1 câu:** Bộ template là dãy nhà mẫu: chọn đúng mẫu hợp repo (CLAUDE.md → rules → agents → skills → hooks → MCP), dựng theo thứ tự 15 phút, rồi nhờ Claude chạy 1 task thật để nghiệm thu.
