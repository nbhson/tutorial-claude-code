# FAQ 02 — Model, Context & Token Limits

> Nhóm Model & Token · 10 câu hỏi deep-dive · Đọc xong biết khi nào đổi model, cứu context đầy, và đo tiền chính xác

Mỗi câu có giải thích + lệnh/config copy-paste + ví dụ + khi nào áp dụng. Số liệu overhead trong file này là con số thực tế để bạn tính toán, không phải slogan.

---

## Sơ đồ nhanh (nhìn 30 giây là nhớ)

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

## Bảng tổng hợp: con số phải nhớ

| Hạng mục | Con số | Ý nghĩa thực tế |
|---


|---|---|
| Spawn 1 subagent | ~20k tokens overhead | Đừng spawn cho việc 1 bước |
| Tổng subagent descriptions | 15k tokens trần | Vượt → warning startup, phải rút gọn |
| MCP tools visible | >~10 → accuracy giảm | Sweet spot 3–6 servers thực dùng |
| CLAUDE.md | <200 dòng | Dài hơn = trả tiền mọi turn |
| Skill chưa trigger | ~100 tokens (tên + description) | Rẻ nhất trong các extensions |
| Hook shell | 0 model tokens | Thứ duy nhất vừa miễn phí vừa bắt buộc |
| Multi-agent vs single | ~3–4x tokens | Trần 3–5 concurrent |
| `/cost` vs `/usage` | Tiền session vs breakdown + rate limits | Xem cả 2, không xem 1 |

---

## 1. Đổi model giữa session thế nào (`/model`, `/effort`, `/fast`)?
> **Hỏi ngắn gọn:** Đổi model giữa session thế nào (`/model`, `/effort`, `/fast`)?
>
> **Trả lời 1 câu:** Không cần thoát session để đổi model.


**Giải thích chi tiết + ví dụ:** Không cần thoát session để đổi model. `/model` đổi họ model, `/effort` chỉnh độ "suy nghĩ sâu", `/fast` ép nhanh-rẻ khi việc đơn giản.

**Làm thế nào (steps copy-paste):**

```bash
/model              # xem model hiện tại
/model sonnet       # việc thường: implement, refactor
/model opus         # việc khó: kiến trúc, security, bug hiểm
/model haiku        # việc rẻ: research, rewrite, quét ồn
/fast               # ép nhanh khi việc đơn giản
/effort high        # cần suy luận sâu cho bug khó
```

**Ví dụ:** session đang Sonnet, gặp bug race condition 3 ngày chưa ra → `/model opus` + `/effort high`, fix xong quay lại `/model sonnet` để đỡ tốn.

**Khi nào áp dụng:** đổi theo PHASE, không đổi theo cảm xúc. Route chuẩn xem câu 2.

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 2. Route model chuẩn: Haiku / Sonnet / Opus khi nào?
> **Hỏi ngắn gọn:** Route model chuẩn: Haiku / Sonnet / Opus khi nào?
>
> **Trả lời 1 câu:** Mỗi họ sinh ra cho 1 việc khác nhau.


**Giải thích chi tiết + ví dụ:** Mỗi họ sinh ra cho 1 việc khác nhau. Dùng sai = vừa đắt vừa dở:

- **Haiku:** research, rewrite, tóm tắt, quét file ồn, việc song song số lượng lớn. Rẻ, nhanh, đủ tốt cho việc "đọc rồi nhả lại gọn".
- **Sonnet:** implement thường, refactor, viết test, CRUD, glue code. Cân bằng giá/chất lượng — model mặc định 80% thời gian.
- **Opus:** kiến trúc, security review, bug hiểm (race, memory, crypto), quyết định khó đảo ngược. Đắt nhưng đáng cho việc sai 1 ly đi 1 dặm.

**Làm thế nào (steps copy-paste):**

```bash
# Phase research (rẻ): Haiku quét
/model haiku
# Phase implement (thường): Sonnet code
/model sonnet
# Phase review khó (đắt): Opus soi
/model opus
```

**Ví dụ workflow 1 feature:**

```text
Haiku:  quét 50 files tìm chỗ liên quan (rẻ, nhanh)
Sonnet: implement 5 files chính (chuẩn, vừa tiền)
Opus:   review security + race condition (đắt, xứng đáng)
```

**Khi nào áp dụng:** feature nào cũng đi 3 phase này. Đừng dùng Opus để rewrite comment, đừng dùng Haiku để thiết kế auth.

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 3. Context đầy thì cứu thế nào? (4 cách cứu chuẩn)
> **Hỏi ngắn gọn:** Context đầy thì cứu thế nào? (4 cách cứu chuẩn)
>
> **Trả lời 1 câu:** Dấu hiệu context đầy: Claude quên rule đầu session, trả lời lan man, sửa A hỏng B, đọc lại file vừa đọc.


**Giải thích chi tiết + ví dụ:** Dấu hiệu context đầy: Claude quên rule đầu session, trả lời lan man, sửa A hỏng B, đọc lại file vừa đọc. Có 4 cách cứu theo thứ tự nhẹ → nặng:

**Cách 1 — `/compact [focus]` (nhẹ nhất, giữ session):**

```bash
/context            # xem đã đầy bao nhiêu %
/compact            # tóm tắt toàn bộ, giữ mạch
/compact auth-flow   # chỉ giữ focus auth, vứt phần còn lại
```

**Cách 2 — `/clear` + paste plan (sạch, giữ hướng):**

```bash
# Trước khi clear: bảo Claude xuất plan hiện tại ra file
# Sau đó:
/clear
# Paste lại plan + chỉ files cần cho phase tiếp theo
```

**Cách 3 — Rewind (double-Esc, quay về checkpoint sạch):**

```bash
# Bấm Esc 2 lần → chọn checkpoint trước khi context loãng
# Dùng khi vừa làm 1 hướng sai tốn 20 turns
```

**Cách 4 — Đẩy research sang subagent (phòng bệnh):**

```bash
# Thay vì tự đọc 50 files trong main context:
# "Dùng subagent Explore quét auth flow, trả về 10 dòng tóm tắt + 5 file chính"
```

**Khi nào áp dụng:** thấy dấu hiệu loãng → `/context` trước để xác nhận, rồi compact. Đừng cố "nói thêm cho nó nhớ" khi đã đầy — càng nói càng loãng.

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 4. Giới hạn subagent descriptions 15k tokens là gì?
> **Hỏi ngắn gọn:** Giới hạn subagent descriptions 15k tokens là gì?
>
> **Trả lời 1 câu:** Mỗi subagent có `description` (lúc nào thì gọi nó).


**Giải thích chi tiết + ví dụ:** Mỗi subagent có `description` (lúc nào thì gọi nó). Tổng description của TẤT CẢ custom subagents (trừ built-in) vượt ~15k tokens → warning lúc startup. Vì descriptions luôn load vào context khởi động.

**Fix copy-paste:**

```markdown
---  # ❌ DÀI: description 300 chữ kể cả cách implement
description: Agent chuyên review code, kiểm tra security, performance, đọc từng file, chạy test, so sánh với main, viết báo cáo chi tiết...
---
```

```markdown
---  # ✅ GỌN: description 1-2 câu use case, chi tiết vào body
description: Review security + performance cho PR. Dùng khi cần reviewer thứ hai trước merge.
---
```

```bash
/agents   # xem library, description nào dài thì cắt
```

**Ví dụ:** 20 agents × 800 tokens description = 16k → warning. Cắt mỗi description còn ~200 tokens → 4k, hết warning, auto-trigger còn chính xác hơn (model đọc ngắn dễ khớp).

**Khi nào áp dụng:** ngay khi thấy warning startup. Quy tắc: description = "khi nào gọi", body = "làm thế nào".

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 5. Multi-agent tốn bao nhiêu token? (overhead ~20k, ~3–4x)
> **Hỏi ngắn gọn:** Multi-agent tốn bao nhiêu token? (overhead ~20k, ~3–4x)
>
> **Trả lời 1 câu:** Mỗi lần spawn subagent tốn ~20k tokens overhead (system prompt riêng + context fork + tools).


**Giải thích chi tiết + ví dụ:** Mỗi lần spawn subagent tốn ~20k tokens overhead (system prompt riêng + context fork + tools). Multi-agent song song tốn ~3–4x so với làm tuần tự 1 luồng. Trần thực tế: 3–5 concurrent — hơn nữa thì tiền tăng mà tốc độ không tăng (model + API limits).

**Tính nhẩm:**

```text
1 subagent research nhỏ  = ~20k overhead + ~5k việc thật  ≈ 25k
3 subagents song song    = ~60k overhead + ~15k việc thật ≈ 75k
Single-thread đọc 10 files gọn = ~10-15k (RẺ HƠN NHIỀU)
```

**Khi nào dùng / không:**

| Dùng subagent khi | Làm trực tiếp khi |
|---|---|
| Quét >10 files ồn, chỉ cần tóm tắt | Việc 1-3 files, 1-2 bước |
| 3 hướng độc lập song song được | Việc tuần tự, bước sau cần bước trước |
| Muốn giữ main context sạch | Cần nhớ chi tiết history |

**Khi nào áp dụng:** trước khi spawn, hỏi "việc này có đủ ồn/độc lập để đáng 20k không". Không → làm trực tiếp.

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 6. MCP nhiều có sao không? (trần ~10 tools, sweet spot 3–6 servers)
> **Hỏi ngắn gọn:** MCP nhiều có sao không? (trần ~10 tools, sweet spot 3–6 servers)
>
> **Trả lời 1 câu:** Mỗi MCP server expose tools vào context.


**Giải thích chi tiết + ví dụ:** Mỗi MCP server expose tools vào context. Quá ~10 tools visible → model chọn sai tool, bỏ sót tool, gọi thừa. Không phải "càng nhiều càng mạnh" mà là "càng nhiều càng loãng".

Sweet spot: **3–6 servers thực dùng** (VD: GitHub + Playwright + DB + search + tickets). Server nào 30+ tools mà tuần dùng 1 lần → disable khi không cần.

**Làm thế nào (steps copy-paste):**

```bash
/mcp                # list servers + tools count
/mcp disable <tên>  # tắt server ít dùng
/mcp enable <tên>   # bật lại khi cần
```

**Ví dụ:** gắn 12 servers (120 tools) → `/usage` thấy MCP ngốn 8k/session mà accuracy giảm. Tắt 7 cái ít dùng, giữ 5 → còn 3k/session, gọi đúng hơn.

**Khi nào áp dụng:** mỗi tháng `/mcp` 1 lần, tắt server 3 tháng không đụng. Chi tiết [FAQ 04](04-mcp-faq.md).

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 7. CLAUDE.md bao nhiêu dòng là đủ? (<200 dòng)
> **Hỏi ngắn gọn:** CLAUDE.md bao nhiêu dòng là đủ? (<200 dòng)
>
> **Trả lời 1 câu:** CLAUDE.md load MỌI turn → mỗi dòng thừa là tiền trả mãi mãi.


**Giải thích chi tiết + ví dụ:** CLAUDE.md load MỌI turn → mỗi dòng thừa là tiền trả mãi mãi. >200 dòng = loãng signal + tốn token/session. Quy tắc tách:

- **Giữ trong CLAUDE.md (<200 dòng):** always-on facts — stack, lệnh test/lint/build, cấu trúc thư mục, 5-10 quy ước bất di bất dịch.
- **Procedures/reference → skills:** quy trình dài, load-khi-cần (deploy, migrate, release...).
- **Rules theo path → `.claude/rules/` + `paths`:** luật chỉ áp dụng cho `api/**`, `web/**`...
- **Rule hay bị miss → hook:** cái gì nói 3 lần model vẫn quên → viết hook bắt buộc.

**Làm thế nào (steps copy-paste):**

```bash
wc -l CLAUDE.md
/doctor claude-md    # khám: dài quá? mâu thuẫn? trùng rules?
```

**Ví dụ:** CLAUDE.md 320 dòng → `/doctor` báo đỏ → tách 4 khối theo thư mục sang `/rules`, còn 45 dòng → tiết kiệm ~2.7k token/session.

**Khi nào áp dụng:** mỗi tháng `wc -l` 1 lần. Vượt 150 → vàng, vượt 300 → đỏ, tách ngay.

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 8. Skills tốn bao nhiêu token? (~100 tokens, rẻ nhất)
> **Hỏi ngắn gọn:** Skills tốn bao nhiêu token? (~100 tokens, rẻ nhất)
>
> **Trả lời 1 câu:** Skill chưa trigger chỉ tốn tên + description (~100 tokens lúc start).


**Giải thích chi tiết + ví dụ:** Skill chưa trigger chỉ tốn tên + description (~100 tokens lúc start). Body chỉ load khi model quyết định gọi. Nên skills là extension RẺ NHẤT — rẻ hơn MCP (tools luôn visible), rẻ hơn subagents (20k/spawn), rẻ hơn CLAUDE.md dài (load mọi turn).

```text
30 skills không dùng  = ~3k tokens startup (nhẹ)
30 MCP tools luôn on  = ~8-10k tokens startup (nặng)
1 subagent spawn      = ~20k (nặng nhất cho việc nhỏ)
```

**Khi nào áp dụng:** có procedure mới → viết skill đầu tiên, đừng nhét vào CLAUDE.md, đừng spawn agent chỉ để "nhớ quy trình". Chi tiết [FAQ 06](06-skills-commands-claude-md.md).

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 9. Hooks tốn tokens không? (0 model tokens + bắt buộc thực thi)
> **Hỏi ngắn gọn:** Hooks tốn tokens không? (0 model tokens + bắt buộc thực thi)
>
> **Trả lời 1 câu:** Hook shell chạy NGOÀI model → 0 model tokens.


**Giải thích chi tiết + ví dụ:** Hook shell chạy NGOÀI model → 0 model tokens. Và nó là thứ DUY NHẤT vừa miễn phí vừa bắt buộc (model không thể "quên" như rule trong CLAUDE.md). Luật nào quan trọng + check được bằng script → viết hook thay vì gõ chữ.

**Ví dụ:**

```json
{
  "hooks": {
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "./scripts/lint-changed.sh" }] }]
  }
}
```

→ Mỗi lần sửa file tự lint, tốn 0 token model, không bao giờ miss.

**Khi nào áp dụng:** rule nào đã nhắc 3 lần mà model vẫn quên (format, không commit secret, chạy test sau sửa) → chuyển thành hook. Chi tiết [FAQ 05](05-hooks-faq.md).

---

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).
## 10. `/usage` vs `/cost` vs `/context` — xem cái nào khi nào?
> **Hỏi ngắn gọn:** `/usage` vs `/cost` vs `/context` — xem cái nào khi nào?
>
> **Trả lời 1 câu:** 3 lệnh đo 3 thứ khác nhau, đừng xem 1 mà đoán 3:


**Giải thích chi tiết + ví dụ:** 3 lệnh đo 3 thứ khác nhau, đừng xem 1 mà đoán 3:

| Lệnh | Trả lời câu hỏi | Dùng khi nào |
|---|---|---|
| `/context` | Context đầy bao nhiêu %? Cái gì ngốn? | Thấy Claude loãng, quên rule |
| `/cost` | Session này tốn bao nhiêu tiền? | Cuối session, muốn biết bill |
| `/usage` | Breakdown theo skills/subagents/plugins/MCP + rate limits? | Cuối tuần, tìm chỗ tốn để cắt |

**Làm thế nào (steps copy-paste):**

```bash
/context    # đầy >70% → compact ngay
/cost       # session này bao nhiêu?
/usage      # tuần này cái gì ngốn nhất? rate limit còn bao nhiêu?
```

**Ví dụ:** `/cost` thấy session 4$ → `/usage` thấy MCP ngốn 60% → tắt 5 servers thừa → tuần sau còn 1.5$/session.

**Khi nào áp dụng:** `/context` xem trong session (khi loãng), `/cost` xem cuối session, `/usage` xem cuối tuần.

**Nếu vẫn lỗi thì:** đi hết thứ tự `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` (chi tiết xem FAQ 08 + mục *Vẫn lỗi thì sao* cuối file).

---

## Vẫn lỗi thì sao? (context/token)

1. `/context` — xác nhận đầy thật hay model dởm (đầy → compact; chưa đầy mà dởm → rewind + re-prompt).
2. `/cost` + `/usage` — tìm hạng mục ngốn (MCP? subagents? skill rác?).
3. `/doctor` — khám CLAUDE.md phình, plugin thừa, MCP chết.
4. `/compact [focus]` hoặc `/clear` + paste plan — cứu session.
5. `/debug` — session vẫn lạ sau khi đã gọn → chẩn đoán sâu.

```bash
/context
/compact auth-flow
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/model-mode/model/README.md](../01-huong-dan-su-dung/commands/model-mode/model/README.md) — đổi model giữa session
  - [../01-huong-dan-su-dung/commands/session-context/context/README.md](../01-huong-dan-su-dung/commands/session-context/context/README.md) — xem context đầy bao nhiêu
  - [../01-huong-dan-su-dung/commands/session-context/compact/README.md](../01-huong-dan-su-dung/commands/session-context/compact/README.md) — cứu context nhẹ nhất
  - [../01-huong-dan-su-dung/commands/session-context/clear/README.md](../01-huong-dan-su-dung/commands/session-context/clear/README.md) — reset sạch + paste plan
  - [../01-huong-dan-su-dung/commands/session-context/cost/README.md](../01-huong-dan-su-dung/commands/session-context/cost/README.md) — tiền session hiện tại
  - [../01-huong-dan-su-dung/commands/session-context/usage/README.md](../01-huong-dan-su-dung/commands/session-context/usage/README.md) — breakdown + rate limits
  - [../01-huong-dan-su-dung/commands/session-context/rewind/README.md](../01-huong-dan-su-dung/commands/session-context/rewind/README.md) — quay về checkpoint sạch
  - [../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md) — quản lý subagents
  - [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — list/disable servers thừa
- Bài tổng quan:
  - [../01-huong-dan-su-dung/03-claude-md-memory-rules.md](../01-huong-dan-su-dung/03-claude-md-memory-rules.md) — giữ CLAUDE.md <200 dòng
  - [../01-huong-dan-su-dung/05-skills-custom-commands.md](../01-huong-dan-su-dung/05-skills-custom-commands.md) — skills rẻ nhất
  - [../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md](../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md) — hooks 0 token
  - [../02-tips-thuc-chien/01-context-hygiene.md](../02-tips-thuc-chien/01-context-hygiene.md) — giữ context sạch
  - [../02-tips-thuc-chien/08-tiet-kiem-cost-token.md](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md) — cắt bill thực tế
- FAQ liên quan: [FAQ 06](06-skills-commands-claude-md.md) (skills), [FAQ 07](07-subagents-teams-workflows.md) (subagents), [FAQ 04](04-mcp-faq.md) (MCP).

> Mẹo 1 dòng: _Haiku quét, Sonnet code, Opus soi khó — và context đầy thì compact trước, đừng cố nói thêm._
