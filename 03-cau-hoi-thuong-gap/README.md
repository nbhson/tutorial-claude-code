# 03 — Câu hỏi thường gặp (10 bài)

> Mỗi bài ~10 câu hỏi. Mỗi câu hỏi theo khung 5 bước:
> **Hỏi ngắn gọn → Trả lời 1 câu → Giải thích chi tiết + ví dụ → Steps copy-paste → Nếu vẫn lỗi thì...**
> Đầu mỗi file có 1 sơ đồ mermaid + 1 bảng tổng hợp để nhìn 30 giây là nhớ.

| # | Chủ đề | Link |
|---|--------|------|
| 01 | Tài khoản, pricing, cài đặt | [01-tai-khoan-pricing-cai-dat.md](./01-tai-khoan-pricing-cai-dat.md) |
| 02 | Model, context, token | [02-model-context-token.md](./02-model-context-token.md) |
| 03 | Permissions & modes | [03-permissions-modes.md](./03-permissions-modes.md) |
| 04 | MCP FAQ (Tools/Resources/Prompts + scopes) | [04-mcp-faq.md](./04-mcp-faq.md) |
| 05 | Hooks FAQ | [05-hooks-faq.md](./05-hooks-faq.md) |
| 06 | Skills, commands, CLAUDE.md | [06-skills-commands-claude-md.md](./06-skills-commands-claude-md.md) |
| 07 | Subagents, teams, workflows | [07-subagents-teams-workflows.md](./07-subagents-teams-workflows.md) |
| 08 | Lỗi thường gặp & troubleshooting | [08-loi-thuong-gap-troubleshooting.md](./08-loi-thuong-gap-troubleshooting.md) |
| 09 | Bảo mật, quyền, riêng tư | [09-bao-mat-quyen-rieng-tu.md](./09-bao-mat-quyen-rieng-tu.md) |
| 10 | CI, SDK, routines, Web | [10-ci-sdk-routines-web.md](./10-ci-sdk-routines-web.md) |

## Gặp lỗi X → đọc bài nào? (bảng tra 10 giây)

- Không đăng nhập / lỗi cài đặt / thắc mắc giá → **bài 01**
- Hết token, tràn context, chọn model nào → **bài 02**
- Bị chặn quyền, không hiểu mode (plan/auto/bypass) → **bài 03**
- MCP không kết nối, thiếu tool ngoài, chưa rõ Tools/Resources/Prompts → **bài 04**
- Hook không chạy, matcher sai → **bài 05**
- Skill/command không load, CLAUDE.md không ăn → **bài 06**
- Subagent chạy loạn, team conflict → **bài 07**
- Lỗi lạ chưa rõ nguyên nhân → **bài 08** trước, rồi gõ `/doctor`
- Lo lộ code/secret, sợ bypass quyền → **bài 09**
- Lỗi CI/CD, SDK, automation, bản Web → **bài 10**

> Thứ tự debug chuẩn mọi lỗi: `/status` → `claude doctor` → `/permissions` → `/mcp`+`/hooks` → `/debug` → `/bug`.
