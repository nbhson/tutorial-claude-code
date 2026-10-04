# Tips 01 — Context Hygiene: Kỹ Năng Quyết Định 80% Kết Quả

> Mọi best practice đều quy về 1 constraint: **context window đầy rất nhanh, và model dở dần khi context đầy.**

## 1. Năm thói quen nền

1. **`/clear` giữa các task không liên quan** — thói quen ROI cao nhất. Đừng để 1 conversation
   đi từ bugfix → feature → refactor.
2. **Rewind thay vì cãi**: correct 2 lần vẫn sai → double-Esc → rewind code+conversation → re-prompt sạch.
3. **`/btw` cho câu hỏi phụ**: `/btw config này để làm gì?` — dùng full context, có tools... à không:
   `/btw` = full context, **no tools**, không thêm vào history. Ngược với subagent (fresh context + tools).
4. **Đẩy exploration ồn sang subagents** (fresh context + full tools, chỉ trả summary về).
5. **`/compact [focus]` khi >80%** + `/context` để nhìn grid usage + `/usage` để biết ai ngốn (skills/subagents/plugins/per-MCP-server).

## 2. Giữ CLAUDE.md + skills gọn (trần context)

- CLAUDE.md <200 dòng, front-load rule hay sai nhất lên đầu, còn lại `@import` hoặc tách `.claude/rules/`.
- Skills: tên + description ~100 tokens lúc start; body chỉ load khi trigger → **đừng nhét procedure vào CLAUDE.md**.
- Subagent descriptions cộng dồn >15k tokens → warning startup: rút gọn description, chi tiết vào body.
- MCP: quá ~10 tools visible → accuracy chọn tool giảm. Prune server 2 tuần không dùng.
- `/doctor` định kỳ: tìm skills/MCP/plugins cài mà không dùng vs context cost + hooks chậm.

## 3. Dấu hiệu context bẩn (và cách cứu)

| Dấu hiệu | Cứu |
|---|---|
| Claude đọc hàng trăm file sau chữ "investigate" | Scope hẹp lại hoặc ném sang subagent |
| Trả lời dài, lan man, quên rule đầu session | `/compact` với focus, hoặc `/clear` + paste plan |
| Sửa chỗ A hỏng chỗ B | Task quá lớn trong 1 context → chia phase, mỗi phase 1 session fresh |
| Reviewer tự review code mình viết | Spawn reviewer subagent fresh-context (không mang định kiến người viết) |

## 4. Công thức session sạch cho task lớn

```
Session 1 (research): explorer subagents → ghi findings ra plan.md
Session 2 (plan): plan mode → duyệt plan → save plan.md
Session 3..N (implement): mỗi phase 1 session fresh, paste plan.md + "làm phase K, verify rồi dừng"
Session cuối (review): reviewer subagent fresh + /code-review + tests
```

Files persist, context thì không — **cái gì quan trọng thì save ra file** (`plan.md`, `SCRATCHPAD.md`).
