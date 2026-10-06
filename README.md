# Khóa Học Claude Code — Từ Zero tới Pro (2026)

> Bộ tài liệu tiếng Việt đầy đủ, chi tiết, deep-dive về **Claude Code v2.1.x** — đối chiếu docs chính thức `code.claude.com/docs`.
> Mọi code block đều copy-paste được. Học xong bạn tự setup repo, tự fix lỗi thường gặp, tự dạy lại cho team.

## Bạn có hợp với khóa này không?

| Nếu bạn là... | Bạn sẽ làm được sau khóa học |
|---|---|
| Dev mới nghe tên Claude Code | Cài sạch 1 bản duy nhất, `claude login`, `/init` repo đầu tiên trong 15 phút |
| Dev đã dùng nhưng hay bị lỗi vặt | Hết `Unknown command`, hết duplicate install, biết `/doctor` → `/debug` → `/bug` |
| Dev muốn lên pro | Viết skills, subagents, hooks, gắn MCP, chia batch/worktree, chạy CI headless |
| Tech lead | Chuẩn hóa `CLAUDE.md` + `.claude/` + permissions baseline cho cả team |

Điều kiện duy nhất: biết dùng terminal cơ bản (`cd`, `git clone`). Không cần biết AI.

## Cấu trúc khóa học (mỗi phần = 1 folder)

| Folder | Nội dung | Gồm gì |
|---|---|---|
| [`01-huong-dan-su-dung/`](./01-huong-dan-su-dung/) | **Hướng dẫn sử dụng**: cài đặt, surfaces, CLAUDE.md, slash commands, skills, subagents, hooks, MCP, plugins, permissions, worktrees, SDK/CI | 17 bài + `commands/` (78 lệnh, mỗi lệnh 1 folder: làm gì → khi nào dùng → cách gọi → ví dụ thật → lỗi hay gặp) |
| [`02-tips-thuc-chien/`](./02-tips-thuc-chien/) | **Tips thực chiến**: context hygiene, prompt engineering, plan-first, verification, parallel agents, hooks recipes, skills design, tiết kiệm cost, teamwork | 11 bài deep-dive (mỗi bài: lý thuyết gọn + ≥3 ví dụ + walkthrough + pitfalls) |
| [`03-cau-hoi-thuong-gap/`](./03-cau-hoi-thuong-gap/) | **Q&A thường gặp**: tài khoản & pricing, model & context, permissions, MCP, hooks, skills, subagents, troubleshooting, bảo mật, CI/SDK | 10 bài, mỗi câu hỏi theo khung: Hỏi ngắn gọn → Trả lời 1 câu → Giải thích + ví dụ → Steps copy-paste → Nếu vẫn lỗi thì... |
| [`templates/`](./templates/) | Template copy-paste: `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `hooks`, `.mcp.json` | Copy vào repo thật, sửa 20% là chạy (có README 3 bước + checklist 15 phút) |
| [`CHEATSHEET.md`](./CHEATSHEET.md) | Bảng tra nhanh 1 trang: mỗi lệnh kèm ví dụ mini copy-paste | In ra dán cạnh màn hình |

## Lộ trình học đề xuất (5 ngày, mỗi ngày ~1 giờ)

```text
Ngày 1: 01 bài 00 → 04 (tổng quan, cài đặt, surfaces, CLAUDE.md)
Ngày 2: 01 bài 05 → 07 (commands, skills, subagents, hooks)
Ngày 3: 01 bài 08 → 12 (MCP, plugins, permissions, worktrees, SDK/CI)
Ngày 4: 02 tips 01 → 05 (context, prompt, plan, verify, parallel)
Ngày 5: 02 tips 06 → 10 + 03 FAQ tra cứu khi gặp lỗi
```

Tra cứu lệnh bất kỳ: `01-huong-dan-su-dung/commands/<tên-lệnh>/` (vd `commands/model-mode/plan/`).
Gặp lỗi lạ: mở [`03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md`](./03-cau-hoi-thuong-gap/08-loi-thuong-gap-troubleshooting.md) trước, rồi gõ `/doctor`.

Quy tắc vàng (nhớ 4 câu này là đủ 80% sức mạnh):

1. **Context là bottleneck, không phải model** — giữ context sạch (xem `02-tips-thuc-chien/01`).
2. **Explore → Plan → Implement → Verify** — không bao giờ code ngay task phức tạp.
3. **CLAUDE.md là gợi ý, hooks là luật** — rule nào hay bị quên thì viết thành hook.
4. **Việc ồn ào đẩy sang subagent** — main thread chỉ giữ quyết định.

## Phiên bản & nguồn

- Claude Code **v2.1.x** (2026). Lệnh `claude doctor` / `/doctor` để kiểm tra version.
- Docs gốc: https://code.claude.com/docs/en/ — file index: https://code.claude.com/docs/llms.txt
- Chú ý version-gated: `/verify` (≥2.1.145), `/cd` (≥2.1.169), `/goal` (≥2.1.139), `/doctor` trim CLAUDE.md (≥2.1.206).

## Cách dùng repo này

- Đọc theo thứ tự file `00-*` → `NN-*` trong mỗi folder (đã đánh số).
- Mọi code block đều copy-paste được. Template trong `templates/` dùng được ngay.
- Gõ `/` trong Claude Code session để xem lệnh khả dụng ở môi trường của bạn (không phải lệnh nào cũng hiện ở mọi plan/provider).
- Muốn đóng góp: đọc [`CONTRIBUTING.md`](./CONTRIBUTING.md) 5 phút trước khi mở PR.
