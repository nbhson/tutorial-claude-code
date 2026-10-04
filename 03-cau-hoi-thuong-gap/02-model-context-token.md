# FAQ 02 — Model, Context & Token Limits

**Đổi model giữa session?** `/model [opus|sonnet|haiku]` (+ `/effort`, `/fast`). Route: Haiku cho research/rewrite rẻ,
Sonnet implement thường, Opus kiến trúc/security/bug hiểm.

**Context đầy thì sao?** Dấu hiệu: quên rule đầu session, lan man, sửa A hỏng B. Cứu: `/compact [focus]`,
`/clear` + paste plan, rewind (double-Esc), đẩy research sang subagent. Xem `/context`, `/cost`, `/usage`.

**Giới hạn subagents descriptions 15k tokens?** Tổng description (trừ built-in) vượt ngưỡng → warning startup.
Rút gọn description, chi tiết vào body.

**Multi-agent tốn bao nhiêu?** Mỗi spawn ~20k overhead; multi-agent ~3–4x single-thread. Trần 3–5 concurrent.

**MCP nhiều có sao?** Quá ~10 tools visible → chọn sai/bỏ sót. Sweet spot 3–6 servers thực dùng.

**CLAUDE.md bao nhiêu dòng?** <200. Dài hơn = trả tiền mọi turn + loãng signal. Procedures → skills,
rules theo path → `.claude/rules/`, rule hay miss → hook.

**Skills tốn bao nhiêu?** Tên+description ~100 tokens lúc start; body chỉ khi trigger. Rẻ nhất trong các extensions.

**Hooks tốn tokens?** 0 model tokens (chạy ngoài model) + bắt buộc thực thi — thứ duy nhất vừa miễn phí vừa là luật.

**`/usage` vs `/cost`?** `/cost` = tiền session hiện tại; `/usage` = breakdown (skills/subagents/plugins/per-MCP) + rate limits.
