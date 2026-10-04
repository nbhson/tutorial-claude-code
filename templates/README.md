# Templates — copy-paste dùng ngay

> Thư mục này chứa bộ khung `.claude/` + `CLAUDE.md` + `.mcp.json` mẫu.
> Copy vào project thật, sửa tên/lệnh cho khớp repo là chạy được.

## Từng file/folder là gì

| Đường dẫn | Để làm gì | Khi nào đụng tới |
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
| `.mcp.json` | Khai báo MCP servers (DB, GitHub...) | Sửa URL/token theo môi trường |

## Cách copy vào project (3 bước)

```bash
# 1. Copy cả khung sang repo thật (đứng ở root repo đích)
cp -r /path/to/tutorial-claude-code/templates/.claude ./
cp /path/to/tutorial-claude-code/templates/CLAUDE.md ./
cp /path/to/tutorial-claude-code/templates/.mcp.json ./

# 2. Cho quyền chạy hooks (bắt buộc trên macOS/Linux)
chmod +x .claude/hooks/*.sh
./.claude/hooks/lint-on-write.sh --help 2>/dev/null || echo "hook ok (chờ stdin JSON)"

# 3. Kiểm tra Claude nhận đủ config
# Mở Claude Code trong repo đích rồi gõ: /agents, /hooks, /mcp
```

## Thứ tự setup khuyên dùng (15 phút)

1. **CLAUDE.md trước**: sửa stack + 4 lệnh Dev/Build/Test/Full-check (chỉ ghi lệnh đã chạy thử).
2. **Rules theo path**: giữ `backend-api.md` nếu có `apps/api/`, giữ `mobile-swift.md` nếu có app Swift; xóa cái không dùng.
3. **Agents**: giữ `explorer` + `tester` (dùng mỗi ngày), giữ `security-reviewer` nếu có auth/payment.
4. **Skills**: giữ `deploy` nếu team có deploy script; giữ `review-pr`, `add-table` nếu đúng stack Postgres + GitHub.
5. **Hooks**: bật `lint-on-write` + `guard-sensitive-paths` trước; thêm `test-gate.sh` vào `Stop` trong `settings.json` khi muốn chặn turn-end lúc test đỏ.
6. **MCP**: sửa `.mcp.json` (URL + token qua env, không hardcode), rồi `/mcp` để test kết nối.
7. **Verify cuối**: nhờ Claude làm 1 task nhỏ end-to-end (sửa 1 handler + chạy test + review) để chắc mọi mảnh đều chạy.
