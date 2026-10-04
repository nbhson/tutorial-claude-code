# Khóa Học Claude Code — Từ Zero tới Pro (2026)

> Bộ tài liệu tiếng Việt đầy đủ, chi tiết, deep-dive về **Claude Code v2.1.x** — verified với docs chính thức `code.claude.com/docs`.
> Tác giả tổng hợp từ: Anthropic Docs, best-practices, skills/subagents/hooks/MCP guides, và kinh nghiệm thực chiến.

## Đối tượng

- Dev mới nghe tên Claude Code, muốn setup và dùng đúng ngay từ đầu.
- Dev đã dùng, muốn lên pro: skills, subagents, hooks, MCP, plugins, agent teams, CI/CD.
- Tech lead muốn chuẩn hóa workflow cho cả team.

## Cấu trúc khóa học (mỗi phần = 1 folder)

| Folder | Nội dung | Số bài |
|---|---|---|
| [`01-huong-dan-su-dung/`](./01-huong-dan-su-dung/) | **Hướng dẫn sử dụng**: cài đặt, surfaces, CLAUDE.md, slash commands, skills, subagents, hooks, MCP, plugins, permissions, worktrees, SDK/CI | 13 bài + commands/ (62 folders, mỗi lệnh 1 folder chi tiết) |
| [`02-tips-thuc-chien/`](./02-tips-thuc-chien/) | **Tips thực chiến**: context hygiene, prompt engineering, plan-first, verification, parallel agents, hooks recipes, skills design, tiết kiệm cost, teamwork | 10 bài deep-dive |
| [`03-cau-hoi-thuong-gap/`](./03-cau-hoi-thuong-gap/) | **Q&A thường gặp**: tài khoản & pricing, model & context, permissions, MCP, hooks, skills, subagents, lỗi & troubleshooting, bảo mật | 10 bài deep-dive |
| [`templates/`](./templates/) | Template copy-paste: `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/rules/`, `hooks`, `.mcp.json` | templates copy-paste: CLAUDE.md, 3 skills, 3 agents, rules, settings, 5 hooks, .mcp.json |
| [`CHEATSHEET.md`](./CHEATSHEET.md) | Bảng tra nhanh lệnh, phím tắt, hooks events, MCP | 1 trang |

## Lộ trình học đề xuất

```
Ngày 1: 01 bài 00 → 04 (tổng quan, cài đặt, surfaces, CLAUDE.md)
Ngày 2: 01 bài 05 → 07 (commands, skills, subagents, hooks)
Ngày 3: 01 bài 08 → 12 (MCP, plugins, permissions, worktrees, SDK/CI)
Ngày 4: 02 tips 01 → 05 (context, prompt, plan, verify, parallel)
Ngày 5: 02 tips 06 → 10 + 03 FAQ tra cứu khi gặp lỗi
```

Tra cứu lệnh: 01-huong-dan-su-dung/commands/<tên-lệnh>/ (vd commands/plan/)

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
