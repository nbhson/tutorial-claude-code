# Tips 08 — Tiết Kiệm Cost & Token (Dùng Opus Khi Đáng, Haiku Khi Đủ)

## 1. Hiểu tiền đi đâu (`/cost` + `/usage`)

- `/cost`: session hiện tại tốn bao nhiêu. `/usage`: breakdown skills/subagents/plugins/per-MCP-server + rate limits.
- Kẻ ngốn nhất thường: CLAUDE.md phình (trả mọi turn), subagents spawn bừa (~20k overhead/con),
  multi-agent ×3–4 single-thread, MCP tools visible quá nhiều (chọn sai → retry tốn thêm).

## 2. Route model theo việc (đừng Opus mọi thứ)

| Việc | Model | Vì sao |
|---|---|---|
| Research/explore rộng, classify, rewrite đơn giản | Haiku | Rẻ, nhanh, đủ |
| Implement feature, refactor, debug thường | Sonnet | Cân bằng |
| Kiến trúc khó, security review, bug hiểm | Opus | Đáng tiền |
| Fast mode (`/fast` + `/extra-usage`) | Opus 4.6加速 | Khi cần Opus mà muốn nhanh |

Đổi giữa session: `/model`, chỉnh kỹ: `/effort low|medium|high|xhigh|max|auto`.
Subagent route riêng: explorer/tester → haiku; reviewer/security → opus (`model:` frontmatter).

## 3. Mười chiêu tiết kiệm cụ thể

1. CLAUDE.md <200 dòng; procedures → skills (load khi cần).
2. 1 task 1 session `/clear`; đừng nuôi conversation 200 turns.
3. Research ồn → subagent (main chỉ nhận summary).
4. `/compact` sớm (khi ~70–80%), kèm focus.
5. `disable-model-invocation: true` cho skills nặng chỉ gọi tay.
6. MCP ≤6 servers thực dùng; prune hàng tuần.
7. Subagent descriptions ngắn (tổng >15k tokens bị warning).
8. `/goal` + Stop-gate cho runs dài không giám sát (tránh loop vô hạn đốt tiền: luôn maxTurns).
9. Cost-cap hook (Stop → ledger → Slack khi quá cap).
10. `/doctor` hàng tháng: audit unused skills/MCP/plugins + hooks chậm + version mới.

## 4. Khi nào ĐỪNG tiết kiệm

- Review bảo mật, quyết định kiến trúc, debug production → Opus + reviewer fresh. Tiết kiệm ở đây
  đắt hơn gấp 100 lần khi sự cố.
- Verification (`/verify`, test-gate) không bao giờ cắt để "đỡ tốn".
