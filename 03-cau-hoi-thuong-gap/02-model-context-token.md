# FAQ 02 — Model, context & giới hạn token

> **Bài này cho ai:** bạn đang phân vân chọn model, lo context đầy giữa chừng, hoặc muốn tính đúng token và tiền cho từng session.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([FAQ 01](01-tai-khoan-pricing-cai-dat.md)); không cần biết gì thêm.
> **Đọc xong bạn làm được:**
> - Đổi model giữa session bằng `/model`, `/effort`, `/fast` và route đúng model theo phase công việc.
> - Cứu session khi context đầy theo 4 cách từ nhẹ tới nặng.
> - Đo token và tiền bằng `/context`, `/cost`, `/usage`, chỉ ra hạng mục nào đang ngốn nhất.
> **Thời gian:** ~12 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Token | Đơn vị model đọc và ghi — hết token là hết chỗ làm việc | `/cost` hiện input/output tokens rồi quy ra đô |
| Context window | Bộ nhớ tạm của model trong 1 session — hết chỗ là model dở | `/context` hiện % context đã dùng |
| Overhead | Phần tốn thêm chỉ vì công cụ, chưa tính việc thật | spawn 1 subagent ~20k tokens overhead |
| Subagent | Trợ lý con có context riêng, làm xong trả kết quả về | "dùng subagent Explore quét auth, trả 10 dòng tóm tắt" |
| Cache read | Đọc lại phần model đã nhớ — rẻ hơn giá input nhiều lần | Opus 5.5: $0.20/1M đọc cache, $4/1M đọc mới |

## Mục lục

- [Sơ đồ nhanh](#sơ-đồ-nhanh)
- [1. Đổi model giữa session thế nào (/model, /effort, /fast)?](#1-đổi-model-giữa-session-thế-nào-model-effort-fast)
- [2. Route model chuẩn: Haiku / Sonnet / Opus / Fable khi nào?](#2-route-model-chuẩn-haiku--sonnet--opus--fable-khi-nào)
- [3. Context đầy thì cứu thế nào? (4 cách cứu chuẩn)](#3-context-đầy-thì-cứu-thế-nào-4-cách-cứu-chuẩn)
- [4. Subagent tốn bao nhiều token? (overhead + trần 15k descriptions)](#4-subagent-tốn-bao-nhiều-token-overhead--trần-15k-descriptions)
- [5. CLAUDE.md bao nhiều dòng là đủ?](#5-claudemd-bao-nhiều-dòng-là-đủ)
- [6. Skills và hooks tốn bao nhiều token?](#6-skills-và-hooks-tốn-bao-nhiều-token)
- [7. /usage vs /cost vs /context — xem cái nào khi nào?](#7-usage-vs-cost-vs-context--xem-cái-nào-khi-nào)
- [Vẫn lỗi thì sao? (context/token)](#vẫn-lỗi-thì-sao-contexttoken)

---

## Sơ đồ nhanh

```mermaid
flowchart TD
  A[Context đầy?] -->|Cùng task| B[/compact + focus]
  A -->|Khác task| C[/clear]
  A -->|Sai hướng| D[Double-Esc rewind]
  B --> E[/context kiểm tra %]
  C --> E
  E -->|Vẫn nặng| F[Đổi Haiku + /effort low<br/>chia subagent / batch]
  E -->|Nhẹ| G[Tiếp tục task]
```

---

## 1. Đổi model giữa session thế nào (`/model`, `/effort`, `/fast`)?

> **Hỏi ngắn gọn:** đang chạy dở session muốn chuyển sang model khác thì gõ gì, có phải thoát ra không?
>
> **Trả lời 1 câu:** Không cần thoát — `/model` đổi họ model, `/effort` chỉnh độ suy nghĩ sâu, `/fast` ép nhanh khi việc đơn giản.

```bash
/model              # xem model hiện tại
/model sonnet       # việc thường: implement, refactor
/model opus         # việc khó: kiến trúc, security, bug hiểm
/model haiku        # việc rẻ: research, rewrite, quét ồn
/model fable        # mạnh nhất, chậm nhất — cần ≥2.1.257
/fast               # ép nhanh khi việc đơn giản
/effort high        # cần suy luận sâu cho bug khó
```

**Đào sâu:** Lưu ý tiền của `/fast`: nó bật fast mode của Opus 5.5, tính **$8 input / $40 output** (gấp đôi giá thường, đổi lấy ~2.5× tốc độ) — xem bảng giá ở [câu 2](#2-route-model-chuẩn-haiku--sonnet--opus--fable-khi-nào). Chi tiết: [lệnh `/model`](../01-huong-dan-su-dung/commands/model-mode/model/README.md) · [lệnh `/effort`](../01-huong-dan-su-dung/commands/model-mode/effort/README.md)

---

## 2. Route model chuẩn: Haiku / Sonnet / Opus / Fable khi nào?

> **Hỏi ngắn gọn:** việc gì thì xài Haiku, việc gì xài Sonnet, việc gì phải để Opus?
>
> **Trả lời 1 câu:** Haiku quét việc ồn, Sonnet code việc thường, Opus soi việc khó, Fable cho việc dài/suy luận nặng nhất.

- **Haiku:** research, rewrite, tóm tắt, quét ồn, song song số lượng lớn. Alias `haiku` trên Anthropic API trỏ **Haiku 5.5** (1M, $0.10/$0.50); provider khác vẫn là Haiku 4.5 (200K).
- **Sonnet:** implement thường, refactor, viết test, CRUD — cân bằng giá/chất lượng.
- **Opus:** kiến trúc, security review, bug hiểm (race, memory, crypto).
- **Fable 5.1:** mạnh nhất, chậm nhất — việc dài hơi mà Opus ở effort cao vẫn không đủ.

Giá API (USD / 1 triệu tokens, tra 11/10/2026, nguồn [WRITING-STYLE — Phần B](../WRITING-STYLE.md#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-11102026)):

| Model | Input | Output | Cache read | Context | Ghi chú |
|---|---|---|---|---|---|
| Claude Fable 5.1 | $10 | $50 | $0.25 | 1M | Alias `fable`; cần ≥2.1.257; mạnh nhất, chậm nhất |
| Claude Opus 5.5 | $4 | $20 | $0.20 | 1M | Cần ≥2.1.280; **mặc định tài khoản** (Pro/Max/Team/Enterprise/API/Bedrock/GCP) |
| Claude Opus 5.5 — fast mode | $8 | $40 | — | 1M | Gấp đôi giá thường, đổi lấy ~2.5× tốc độ |
| Claude Sonnet 5.5 | $2 | $10 | $0.10 | 1M | Cần ≥2.1.284; việc hằng ngày |
| Claude Haiku 5.5 | $0.10 | $0.50 | $0.01 | 1M | Cần ≥2.1.293; **mặc định Haiku trên API**; prompt >100K: $0.50/$2.50 |
| Claude Haiku 4.5 | $1 | $5 | $0.10 | 200K | Mặc định Haiku trên Bedrock/GCP/AWS; không hỗ trợ effort |

Đọc cột **Context** trước khi quét việc lớn: Haiku 4.5 chỉ có 200K, còn lại đều 1M.

**Đào sâu:** [bài 14 — models 5.x, chọn model đúng](../01-huong-dan-su-dung/14-models-5x-chon-model-dung.md) · [lệnh `/model`](../01-huong-dan-su-dung/commands/model-mode/model/README.md)

---

## 3. Context đầy thì cứu thế nào? (4 cách cứu chuẩn)

> **Hỏi ngắn gọn:** context sắp hết thì làm sao, có cách nào cứu mà không mất việc đang làm không?
>
> **Trả lời 1 câu:** Cứu theo thứ tự nhẹ → nặng: `/compact [focus]` → `/clear` + paste plan → rewind double-Esc → đẩy research sang subagent.

Dấu hiệu context loãng: quên rule đầu session, trả lời lan man, sửa A hỏng B, đọc lại file vừa đọc → chạy `/context` xác nhận rồi mới compact; đừng "nói thêm cho nó nhớ" khi đã đầy, càng nói càng loãng.

```bash
# Cách 1 — /compact [focus] (nhẹ nhất, giữ session):
/context            # xem đã đầy bao nhiều %
/compact            # tóm tắt toàn bộ, giữ mạch
/compact auth-flow  # chỉ giữ focus auth, vứt phần còn lại

# Cách 2 — /clear + paste plan: bảo Claude xuất plan ra file trước, rồi:
/clear
# Paste lại plan + chỉ files cần cho phase tiếp theo
# Cách 3 — Rewind: double-Esc → chọn checkpoint trước khi context loãng
# Cách 4 — Phòng bệnh: "Dùng subagent Explore quét auth, trả 10 dòng tóm tắt"
```

**Đào sâu:** [bài 02 tips — vệ sinh context](../02-tips-thuc-chien/01-context-hygiene.md) · [lệnh `/compact`](../01-huong-dan-su-dung/commands/session-context/compact/README.md) · [lệnh `/rewind`](../01-huong-dan-su-dung/commands/session-context/rewind/README.md)

---

## 4. Subagent tốn bao nhiều token? (overhead + trần 15k descriptions)

> **Hỏi ngắn gọn:** spawn subagent, chạy multi-agent có tốn thêm bao nhiêu, warning description lúc startup là gì?
>
> **Trả lời 1 câu:** Mỗi lần spawn ~20k tokens overhead (ước tính cộng đồng), multi-agent gấp ~3–4x tuần tự, trần thực tế 3–5 concurrent; tổng `description` của mọi custom subagent vượt ~15k tokens thì bị warning startup.

```text
1 subagent research nhỏ  = ~20k overhead + ~5k việc thật  ≈ 25k
3 subagents song song    = ~60k overhead + ~15k việc thật ≈ 75k
Single-thread đọc 10 files gọn = ~10-15k (RẺ HƠN NHIỀU)
```

| Dùng subagent khi | Làm trực tiếp khi |
|---|---|
| Quét >10 files ồn, chỉ cần tóm tắt | Việc 1-3 files, 1-2 bước |
| 3 hướng độc lập song song được | Việc tuần tự, bước sau cần bước trước |
| Muốn giữ main context sạch | Cần nhớ chi tiết history |

Riêng `description` của subagents được nạp 1 lần lúc khởi động và nằm suốt session — trả tiền cả khi không gọi agent nào. Quy tắc: **description = "khi nào gọi", body = "làm thế nào"** — 1-2 câu use case, đừng kể cách implement (vừa phình vừa làm model chọn agent sai). `/agents` xem library, description nào dài thì cắt.

Trước khi spawn, hỏi "việc này có đủ ồn/độc lập để đáng 20k không" — không thì làm trực tiếp hoặc dùng `/subtask` (≥2.1.212).

**Đào sâu:** [FAQ 07 — subagents, teams, workflows](07-subagents-teams-workflows.md) · [lệnh `/agents`](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md) · [bài 05 tips — chạy song song](../02-tips-thuc-chien/05-parallel-agents.md)

---

## 5. CLAUDE.md bao nhiều dòng là đủ?

> **Hỏi ngắn gọn:** CLAUDE.md viết bao nhiêu dòng là vừa, dài thêm có sao không?
>
> **Trả lời 1 câu:** Giữ dưới 200 dòng — vì nó được nạp lại mỗi turn, mỗi dòng thừa là tiền trả mãi mãi.

Chỉ giữ always-on facts (stack, lệnh test/lint/build, cấu trúc thư mục, 5-10 quy ước bất di bất dịch); quy trình dài tách sang skill, luật theo path sang `.claude/rules/` + `paths`, rule hay bị miss thì viết hook. Ranh giới chi tiết xem [FAQ 06 câu 6](06-skills-commands-claude-md.md#6-claudemd-ranh-giới-ở-đâu-init-hay-viết-tay).

```bash
wc -l CLAUDE.md        # vượt 150 → vàng, vượt 300 → đỏ, tách ngay
/doctor claude-md      # khám: dài quá? mâu thuẫn? trùng rules? (trim cần ≥2.1.206)
```

CLAUDE.md 320 dòng → `/doctor` báo đỏ → tách sang `/rules`, còn 45 dòng → tiết kiệm ~2.7k token/session.

**Đào sâu:** [FAQ 06 — skills, commands, CLAUDE.md](06-skills-commands-claude-md.md) · [bài 03 — CLAUDE.md & memory](../01-huong-dan-su-dung/03-claude-md-memory-rules.md)

---

## 6. Skills và hooks tốn bao nhiều token?

> **Hỏi ngắn gọn:** thêm skill vào project có tốn token không, viết rule vào hook thì sao?
>
> **Trả lời 1 câu:** Skill chưa trigger chỉ tốn tên + description (~100 tokens lúc start); hook shell chạy ngoài model nên tốn 0 model tokens — và là thứ duy nhất vừa miễn phí vừa bắt buộc thực thi.

So sánh: 30 skills không dùng ~3k tokens startup; 30 MCP tools luôn on ~8-10k; 1 subagent spawn ~20k. Có procedure mới thì viết skill đầu tiên, đừng nhét vào CLAUDE.md, đừng spawn agent chỉ để "nhớ quy trình". Rule nào nhắc 3 lần model vẫn quên (format, không commit secret, chạy test sau sửa) → chuyển thành hook:

```json
{
  "hooks": {
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "./scripts/lint-changed.sh" }] }]
  }
}
```

Mỗi lần sửa file tự lint, tốn 0 token model, không bao giờ miss.

**Đào sâu:** [FAQ 06 — skills, commands, CLAUDE.md](06-skills-commands-claude-md.md) · [FAQ 05 — hooks](05-hooks-faq.md) · [bài 08 tips — tiết kiệm cost & token](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md)

---

## 7. /usage vs /cost vs /context — xem cái nào khi nào?

> **Hỏi ngắn gọn:** ba lệnh `/context`, `/cost`, `/usage` khác nhau chỗ nào, nên gõ cái nào?
>
> **Trả lời 1 câu:** `/context` xem context đầy bao nhiêu, `/cost` xem session tốn bao nhiêu tiền, `/usage` xem hạng mục nào ngốn nhất và rate limit còn bao nhiêu.

| Lệnh | Trả lời câu hỏi | Dùng khi nào |
|---|---|---|
| `/context` | Context đầy bao nhiêu %? Cái gì ngốn? | Thấy Claude loãng, quên rule |
| `/cost` | Session này tốn bao nhiêu tiền? | Cuối session, muốn biết bill |
| `/usage` | Breakdown theo skills/subagents/plugins/MCP + rate limits | Cuối tuần, tìm chỗ tốn để cắt |

```bash
/context    # đầy >70% → compact ngay
/cost       # session này bao nhiều?
/usage      # tuần này cái gì ngốn nhất?
```

`/cost` thấy session 4$ → `/usage` thấy MCP ngốn 60% → tắt 5 servers thừa → tuần sau còn 1.5$/session.

**Đào sâu:** [lệnh `/usage`](../01-huong-dan-su-dung/commands/session-context/usage/README.md) · [lệnh `/cost`](../01-huong-dan-su-dung/commands/session-context/cost/README.md) · [FAQ 04 — MCP nhiều có sao không](04-mcp-faq.md)

---

## Vẫn lỗi thì sao? (context/token)

1. `/context` — xác nhận đầy thật hay model dởm (đầy → compact; chưa đầy mà dởm → rewind + re-prompt).
2. `/cost` + `/usage` — tìm hạng mục ngốn (MCP? subagents? skill rác?).
3. `/doctor` — khám CLAUDE.md phình, plugin thừa, MCP chết.
4. `/compact [focus]` hoặc `/clear` + paste plan — cứu session.
5. `/debug` — vẫn lạ → chẩn đoán sâu. Thứ tự debug chung mọi lỗi: `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` — chi tiết [FAQ 08](08-loi-thuong-gap-troubleshooting.md).

**Tham khảo chéo:** [FAQ 04 — MCP](04-mcp-faq.md) (sweet spot servers) · [FAQ 07 — subagents](07-subagents-teams-workflows.md) (overhead spawn) · [bài 08 tips — tiết kiệm cost](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md)

> Mẹo 1 dòng: _Haiku quét, Sonnet code, Opus soi khó — và context đầy thì compact trước, đừng cố nói thêm._
