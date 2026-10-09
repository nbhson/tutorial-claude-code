# 03 — Câu hỏi thường gặp (10 bài)

> **Bài này cho ai:** bạn đang gặp lỗi, chưa biết chọn gì, hoặc cần tra nhanh một câu hỏi về Claude Code.
> **Cần gì trước:** đã cài và đăng nhập Claude Code; đọc [`01-huong-dan-su-dung/`](../01-huong-dan-su-dung/) càng tốt, không bắt buộc.
> **Đọc xong bạn làm được:**
> - Chọn đúng file FAQ cho tình huống của mình trong chưa đầy 10 giây.
> - Tự tra 1 câu hỏi bất kỳ theo khung 5 khối: hỏi → trả lời → giải thích → ví dụ → đào sâu.
> - Debug theo thứ tự chuẩn `/status` → `claude doctor` → `/permissions` → `/mcp` + `/hooks` → `/debug` → `/bug`.
> **Thời gian:** ~5 phút đọc mục lục, mỗi bài ~10 phút tra cứu

## Thuật ngữ dùng ở trang này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| FAQ | Câu hỏi thường gặp, viết theo khung 5 khối cố định | bài 08 — "sao `claude` báo Unknown command?" |
| Khung 5 khối | Cách mỗi câu hỏi được trả lời trong mọi file FAQ | Câu hỏi → Trả lời 1 câu → Giải thích → Ví dụ → Đào sâu |
| Mermaid | Sơ đồ vẽ bằng chữ, GitHub tự render | sơ đồ "chọn model nào" đầu bài 02 |
| Troubleshooting | Tra lỗi khi chưa rõ nguyên nhân | mở bài 08 trước, rồi gõ `/doctor` |

## Mục lục

- [Mục tiêu folder](#mục-tiêu-folder)
- [Danh sách 10 file FAQ](#danh-sách-10-file-faq)
- [Câu hỏi trong FAQ viết theo khung nào?](#câu-hỏi-trong-faq-viết-theo-khung-nào)
- [Gặp lỗi X → đọc bài nào?](#gặp-lỗi-x--đọc-bài-nào)
- [Link tra cứu](#link-tra-cứu)

## Mục tiêu folder

Section này trả lời câu: 10 file FAQ trong folder gộp lại giúp bạn điều gì?

Folder này là "sổ tay chữa bệnh" của khóa: gặp lỗi thì mở ra tra, chưa biết chọn gì thì mở ra so.
Mỗi file khoảng 10 câu hỏi, đầu file luôn có **1 sơ đồ mermaid + 1 bảng tổng hợp** để nhìn 30 giây
là nhớ được bố cục. Đọc theo thứ tự 00 → 16 không cần thiết — vào thẳng file đúng việc.

## Danh sách 10 file FAQ

Cần chọn nhanh file hợp với rắc rối của mình → dùng bảng này: mỗi dòng 1 file, có mô tả 1 dòng và link.

| # | Chủ đề | Mô tả 1 dòng | Link |
|---|--------|--------------|------|
| 01 | Tài khoản, pricing, cài đặt | Đăng nhập, chọn gói, cài lại từ đầu khi hỏng | [01-tai-khoan-pricing-cai-dat.md](./01-tai-khoan-pricing-cai-dat.md) |
| 02 | Model, context, token | Chọn model, giữ context, hiểu hạn mức token | [02-model-context-token.md](./02-model-context-token.md) |
| 03 | Permissions & modes | Quyền hạn, plan/auto/bypass, cách bỏ chặn | [03-permissions-modes.md](./03-permissions-modes.md) |
| 04 | MCP FAQ (Tools/Resources/Prompts + scopes) | Kết nối công cụ ngoài, lỗi server không lên | [04-mcp-faq.md](./04-mcp-faq.md) |
| 05 | Hooks FAQ | Hook không chạy, matcher sai, thứ tự event | [05-hooks-faq.md](./05-hooks-faq.md) |
| 06 | Skills, commands, CLAUDE.md | Skill/command không load, CLAUDE.md không ăn | [06-skills-commands-claude-md.md](./06-skills-commands-claude-md.md) |
| 07 | Subagents, teams, workflows | Chia việc cho trợ lý con, xung đột giữa các agent | [07-subagents-teams-workflows.md](./07-subagents-teams-workflows.md) |
| 08 | Lỗi thường gặp & troubleshooting | Lỗi lạ chưa rõ nguyên nhân — mở file này trước | [08-loi-thuong-gap-troubleshooting.md](./08-loi-thuong-gap-troubleshooting.md) |
| 09 | Bảo mật, quyền, riêng tư | Lo lộ code/secret, kiểm soát quyền ngặt hơn | [09-bao-mat-quyen-rieng-tu.md](./09-bao-mat-quyen-rieng-tu.md) |
| 10 | CI, SDK, routines, Web | Chạy headless trên CI, Agent SDK, bản Web | [10-ci-sdk-routines-web.md](./10-ci-sdk-routines-web.md) |

## Câu hỏi trong FAQ viết theo khung nào?

Mọi câu hỏi trong 10 file đều xếp đúng 5 khối này — bạn đọc block nào tùy việc cần:

1. **Câu hỏi** — viết lại theo cách người mới actually gõ, không sao chép nguyên văn tiêu đề.
2. **Trả lời 1 câu** — câu trả lời thật, đọc 1 dòng là đủ.
3. **Giải thích** — vì sao lại thế, cơ sở ở đâu.
4. **Ví dụ** — lệnh hoặc tình huống copy-paste được.
5. **Đào sâu** — liên kết tới bài chi tiết hơn, và mục "Vẫn lỗi thì sao" cuối mỗi file.

> Đầu mỗi file còn có 1 sơ đồ mermaid + 1 bảng tổng hợp — cần nhìn nhanh thì xem đó trước, cần làm theo thì nhảy vào khung 5 khối.

## Gặp lỗi X → đọc bài nào?

Chưa biết lỗi thuộc nhóm nào → bám 10 dòng dưới đây, mỗi dòng trỏ đúng 1 file.

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

## Link tra cứu

Cần tra nhanh mà không muốn mở file FAQ dài → dùng các đường dẫn này:

- **Tra 1 lệnh bất kỳ:** [`01-huong-dan-su-dung/commands/`](../01-huong-dan-su-dung/commands/) — 78 lệnh, mỗi lệnh 1 folder.
- **Sổ tay thao tác:** [`01-huong-dan-su-dung/README.md`](../01-huong-dan-su-dung/README.md).
- **Thói quen làm việc:** [`02-tips-thuc-chien/README.md`](../02-tips-thuc-chien/README.md).
- **Bảng tra 1 trang:** [`CHEATSHEET.md`](../CHEATSHEET.md) — in ra dán cạnh màn hình.
- **File mẫu copy-paste:** [`templates/`](../templates/) — `CLAUDE.md`, skills, agents, hooks, `.mcp.json`.
- **Số version/model/giá chuẩn:** [`WRITING-STYLE.md` — Phần B](../WRITING-STYLE.md#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-07102026).

**Kiểm tra nhanh:** mở được bảng 10 file FAQ và 1 link chéo về `commands/`; chỉ ra được file trả lời cho lỗi bạn đang gặp; nhớ được thứ tự debug 6 bước.

> Mẹo 1 dòng: gặp lỗi lạ thì mở [`08-loi-thuong-gap-troubleshooting.md`](./08-loi-thuong-gap-troubleshooting.md) trước, rồi gõ `/doctor`.
