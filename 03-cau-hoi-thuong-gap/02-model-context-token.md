# FAQ 02 — Model, context & giới hạn token

> **Bài này cho ai:** bạn đang phân vân chọn model, lo context đầy giữa chừng, hoặc muốn tính đúng token và tiền cho từng session.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([FAQ 01](01-tai-khoan-pricing-cai-dat.md)); không cần biết gì thêm.
> **Đọc xong bạn làm được:**
> - Đổi model giữa session bằng `/model`, `/effort`, `/fast` và chọn đúng họ model cho từng phase công việc.
> - Cứu session khi context đầy theo 4 cách từ nhẹ tới nặng, đọc được dấu hiệu context loãng.
> - Đo token và tiền bằng `/context`, `/cost`, `/usage`, chỉ ra được hạng mục nào đang ngốn nhất.
> **Thời gian:** ~15 phút

## Thuật ngữ dùng trong bài này

Đọc bảng này trước khi vào câu 1 — mọi thuật ngữ Anh trong bài đều được giải thích ở đây.

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Token | Đơn vị model đọc và ghi, chữ bị cắt ra từng miếng nhỏ — hết token là hết chỗ làm việc | `/cost` hiện input/output tokens của session rồi quy ra đô |
| Context window | Bộ nhớ tạm của model trong 1 session — hết chỗ là model dở | `/context` hiện phần trăm context đã dùng |
| Overhead | Phần tốn thêm chỉ vì công cụ (system prompt, copy context), chưa tính việc thật | spawn 1 subagent ~20k tokens overhead |
| Subagent | Trợ lý con có context riêng, làm xong việc được giao rồi trả kết quả về | "dùng subagent Explore quét auth flow, trả 10 dòng tóm tắt" |
| Compact | Gom session thành bản tóm tắt: giữ mạch, bỏ chi tiết | `/compact auth-flow` |
| Model | Bộ não sinh text và gọi tool, chia theo độ mạnh và giá: Haiku / Sonnet / Opus / Fable | `/model opus` |
| Cache read | Đọc lại phần model đã nhớ thay vì đọc mới — rẻ hơn giá input nhiều lần | Opus 5.5: $0.20/1M đọc cache, $4/1M đọc mới |
| Effort | Mức "suy nghĩ sâu" model dùng trước khi trả lời, chỉnh bằng `/effort` | `/effort high` cho bug khó |

## Mục lục

- [Sơ đồ nhanh (nhìn 30 giây là nhớ)](#sơ-đồ-nhanh-nhìn-30-giây-là-nhớ)
- [Chọn đường vào nhanh](#chọn-đường-vào-nhanh)
- [Bảng tổng hợp: con số phải nhớ](#bảng-tổng-hợp-con-số-phải-nhớ)
- [1. Đổi model giữa session thế nào (/model, /effort, /fast)?](#1-đổi-model-giữa-session-thế-nào-model-effort-fast)
- [2. Route model chuẩn: Haiku / Sonnet / Opus khi nào?](#2-route-model-chuẩn-haiku--sonnet--opus-khi-nào)
- [3. Context đầy thì cứu thế nào? (4 cách cứu chuẩn)](#3-context-đầy-thì-cứu-thế-nào-4-cách-cứu-chuẩn)
- [4. Giới hạn subagent descriptions 15k tokens là gì?](#4-giới-hạn-subagent-descriptions-15k-tokens-là-gì)
- [5. Multi-agent tốn bao nhiều token? (overhead ~20k, ~3–4x)](#5-multi-agent-tốn-bao-nhiều-token-overhead-20k-34x)
- [6. MCP nhiều có sao không? (trần ~10 tools, sweet spot 3–6 servers)](#6-mcp-nhiều-có-sao-không-trần-10-tools-sweet-spot-36-servers)
- [7. CLAUDE.md bao nhiều dòng là đủ? (<200 dòng)](#7-claudemd-bao-nhiều-dòng-là-đủ-200-dòng)
- [8. Skills tốn bao nhiều token? (~100 tokens, rẻ nhất)](#8-skills-tốn-bao-nhiều-token-100-tokens-rẻ-nhất)
- [9. Hooks tốn tokens không? (0 model tokens + bắt buộc thực thi)](#9-hooks-tốn-tokens-không-0-model-tokens--bắt-buộc-thực-thi)
- [10. /usage vs /cost vs /context — xem cái nào khi nào?](#10-usage-vs-cost-vs-context--xem-cái-nào-khi-nào)
- [Vẫn lỗi thì sao? (context/token)](#vẫn-lỗi-thì-sao-contexttoken)
- [Tham khảo chéo](#tham-khảo-chéo)

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

## Chọn đường vào nhanh

Đọc bảng này khi cần nhảy thẳng tới câu đúng với việc đang mắc — mỗi dòng 1 tình huống.

| Tình huống của bạn | Nhảy tới |
|---|---|
| Đang chạy session muốn đổi model mà không muốn thoát | [Câu 1](#1-đổi-model-giữa-session-thế-nào-model-effort-fast) |
| Chưa biết việc nào xài Haiku, việc nào xài Opus | [Câu 2](#2-route-model-chuẩn-haiku--sonnet--opus-khi-nào) |
| Claude bắt đầu quên rule, trả lời lan man, sửa A hỏng B | [Câu 3](#3-context-đầy-thì-cứu-thế-nào-4-cách-cứu-chuẩn) |
| Lúc mở lên báo warning subagent description quá dài | [Câu 4](#4-giới-hạn-subagent-descriptions-15k-tokens-là-gì) |
| Spawn nhiều agent mà token tăng vọt | [Câu 5](#5-multi-agent-tốn-bao-nhiều-token-overhead-20k-34x) |
| Cài nhiều MCP rồi model chọn sai tool, gọi thừa | [Câu 6](#6-mcp-nhiều-có-sao-không-trần-10-tools-sweet-spot-36-servers) |
| CLAUDE.md phình ra quá 200 dòng | [Câu 7](#7-claudemd-bao-nhiều-dòng-là-đủ-200-dòng) |
| Thêm skill mà sợ tốn token | [Câu 8](#8-skills-tốn-bao-nhiều-token-100-tokens-rẻ-nhất) |
| Quy tắc viết 3 lần mà model vẫn quên | [Câu 9](#9-hooks-tốn-tokens-không-0-model-tokens--bắt-buộc-thực-thi) |
| Không biết session này tốn bao nhiều, đang ngốn ở đâu | [Câu 10](#10-usage-vs-cost-vs-context--xem-cái-nào-khi-nào) |

## Bảng tổng hợp: con số phải nhớ

Đọc bảng này khi cần tra nhanh 1 con số trước khi tính toán — số trong đây là số thật dùng được, không phải slogan.

| Hạng mục | Con số | Ý nghĩa thực tế |
|---|---|---|
| Spawn 1 subagent | ~20k tokens overhead | Đừng spawn cho việc 1 bước |
| Tổng subagent descriptions | 15k tokens trần | Vượt → warning startup, phải rút gọn |
| MCP tools visible | >~10 → accuracy giảm | Sweet spot 3–6 servers thực dùng |
| CLAUDE.md | <200 dòng | Dài hơn = trả tiền mọi turn |
| Skill chưa trigger | ~100 tokens (tên + description) | Rẻ nhất trong các extensions |
| Hook shell | 0 model tokens | Thứ duy nhất vừa miễn phí vừa bắt buộc |
| Multi-agent vs single | ~3–4x tokens | Trần 3–5 concurrent |
| `/cost` vs `/usage` | Tiền session vs breakdown + rate limits | Xem cả 2, không xem 1 |

> Số ~20k mỗi lần spawn và ngưỡng ~10 tools / 3–6 servers là **ngưỡng thực nghiệm cộng đồng**, không phải số chính thức của Anthropic.

---

## 1. Đổi model giữa session thế nào (`/model`, `/effort`, `/fast`)?

> **Hỏi ngắn gọn:** đang chạy dở session muốn chuyển sang model khác thì gõ gì, có phải thoát ra không?
>
> **Trả lời 1 câu:** Không cần thoát — gõ `/model` đổi họ model, `/effort` chỉnh độ suy nghĩ sâu, `/fast` ép nhanh khi việc đơn giản.

**Giải thích:** Ba lệnh làm 3 việc khác nhau và đổi được bất cứ lúc nào, không restart:

- **`/model`** — chọn họ model (`haiku` / `sonnet` / `opus` / `fable`), đổi ngay giữa chừng.
- **`/effort`** — chỉnh độ "suy nghĩ sâu": `high` cho bug khó (model suy luận lâu hơn trước khi trả lời), mặc định cho việc thường.
- **`/fast`** — ép model chạy nhanh khi việc đơn giản, không cần suy luận sâu.

Đổi theo phase công việc, không đổi theo cảm xúc — route chuẩn ở [câu 2](#2-route-model-chuẩn-haiku--sonnet--opus-khi-nào).

**Kiểm tra nhanh:**

```bash
/model              # xem model hiện tại
/model sonnet       # việc thường: implement, refactor
/model opus         # việc khó: kiến trúc, security, bug hiểm
/model haiku        # việc rẻ: research, rewrite, quét ồn
/model fable        # mạnh nhất, chậm nhất — cần ≥2.1.257
/fast               # ép nhanh khi việc đơn giản
/effort high        # cần suy luận sâu cho bug khó
```

Session đang Sonnet, gặp bug race condition 3 ngày chưa ra → `/model opus` + `/effort high`, fix xong quay lại `/model sonnet` để đỡ tốn.

**Đào sâu:** Lưu ý tiền của `/fast`: nó bật fast mode của Opus 5.5, tính **$8 input / $40 output** (gấp đôi giá thường, đổi lấy ~2.5× tốc độ) — xem bảng giá ở [câu 2](#2-route-model-chuẩn-haiku--sonnet--opus-khi-nào). Chi tiết: [lệnh `/model`](../01-huong-dan-su-dung/commands/model-mode/model/README.md) · [lệnh `/effort`](../01-huong-dan-su-dung/commands/model-mode/effort/README.md) · [lệnh `/fast`](../01-huong-dan-su-dung/commands/model-mode/fast/README.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 2. Route model chuẩn: Haiku / Sonnet / Opus khi nào?

> **Hỏi ngắn gọn:** việc gì thì xài Haiku, việc gì xài Sonnet, việc gì phải để Opus?
>
> **Trả lời 1 câu:** Haiku quét việc ồn, Sonnet code việc thường, Opus soi việc khó — mỗi họ sinh ra cho 1 việc khác nhau.

**Giải thích:** Dùng sai model = vừa đắt vừa dở:

- **Haiku:** research, rewrite, tóm tắt, quét file ồn, việc song song số lượng lớn. Rẻ, nhanh, đủ tốt cho việc "đọc rồi nhả lại gọn".
- **Sonnet:** implement thường, refactor, viết test, CRUD, glue code. Cân bằng giá/chất lượng — model mặc định 80% thời gian.
- **Opus:** kiến trúc, security review, bug hiểm (race, memory, crypto), quyết định khó đảo ngược. Đắt nhưng đáng cho việc sai 1 ly đi 1 dặm.

Feature nào cũng đi đủ 3 phase. Đừng dùng Opus để rewrite comment, đừng dùng Haiku để thiết kế auth.

**Kiểm tra nhanh:**

```bash
# Phase research (rẻ): Haiku quét
/model haiku
# Phase implement (thường): Sonnet code
/model sonnet
# Phase review khó (đắt): Opus soi
/model opus
```

```text
Haiku:  quét 50 files tìm chỗ liên quan (rẻ, nhanh)
Sonnet: implement 5 files chính (chuẩn, vừa tiền)
Opus:   review security + race condition (đắt, xứng đáng)
```

**Đào sâu:** Cần căn giá thật trước khi chọn model — giá API (USD / 1 triệu tokens, tra 07/10/2026, nguồn [WRITING-STYLE — Phần B](../WRITING-STYLE.md#phần-b--dữ-kiện-chuẩn-làm-tròn-thời-gian-07102026)):

| Model | Input | Output | Cache read | Context | Ghi chú |
|---|---|---|---|---|---|
| Claude Fable 5.1 | $10 | $50 | $0.25 | 1M | Alias `fable`; cần ≥2.1.257; mạnh nhất, chậm nhất |
| Claude Opus 5.5 | $4 | $20 | $0.20 | 1M | Cần ≥2.1.280; mặc định ở hầu hết gói (từ 22/09/2026) |
| Claude Opus 5.5 — fast mode | $8 | $40 | — | 1M | Gấp đôi giá thường, đổi lấy ~2.5× tốc độ |
| Claude Sonnet 5.5 | $2 | $10 | $0.20 | 1M | Việc hằng ngày — cân bằng chất lượng/giá |
| Claude Haiku 4.5 | $1 | $5 | $0.10 | 200K | Nhanh nhất, rẻ nhất; không hỗ trợ effort |

Đọc cột **Context** trước khi quét việc lớn: Haiku 4.5 chỉ có 200K, còn lại 1M. Chi tiết: [lệnh `/model`](../01-huong-dan-su-dung/commands/model-mode/model/README.md) · [bài 14 — models 5.x, chọn model đúng](../01-huong-dan-su-dung/14-models-5x-chon-model-dung.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 3. Context đầy thì cứu thế nào? (4 cách cứu chuẩn)

> **Hỏi ngắn gọn:** context sắp hết thì làm sao, có cách nào cứu mà không mất việc đang làm không?
>
> **Trả lời 1 câu:** Cứu theo thứ tự nhẹ → nặng: `/compact [focus]` → `/clear` + paste plan → rewind double-Esc → đẩy research sang subagent.

**Giải thích:** Dấu hiệu context đầy không phải model dở — Claude quên rule đầu session, trả lời lan man, sửa A hỏng B, đọc lại file vừa đọc. Thấy 1 trong các dấu hiệu này là context đang loãng. Thấy dấu hiệu thì chạy `/context` trước để xác nhận rồi mới compact — đừng cố "nói thêm cho nó nhớ" khi đã đầy, càng nói càng loãng.

**Kiểm tra nhanh:**

Cách 1 — `/compact [focus]` (nhẹ nhất, giữ session):

```bash
/context            # xem đã đầy bao nhiều %
/compact            # tóm tắt toàn bộ, giữ mạch
/compact auth-flow   # chỉ giữ focus auth, vứt phần còn lại
```

Cách 2 — `/clear` + paste plan (sạch, giữ hướng):

```bash
# Trước khi clear: bảo Claude xuất plan hiện tại ra file
# Sau đó:
/clear
# Paste lại plan + chỉ files cần cho phase tiếp theo
```

Cách 3 — Rewind (double-Esc, quay về checkpoint sạch):

```bash
# Bấm Esc 2 lần → chọn checkpoint trước khi context loãng
# Dùng khi vừa làm 1 hướng sai tốn 20 turns
```

Cách 4 — Đẩy research sang subagent (phòng bệnh):

```bash
# Thay vì tự đọc 50 files trong main context:
# "Dùng subagent Explore quét auth flow, trả về 10 dòng tóm tắt + 5 file chính"
```

**Đào sâu:** [bài 02 tips — vệ sinh context](../02-tips-thuc-chien/01-context-hygiene.md) · [lệnh `/context`](../01-huong-dan-su-dung/commands/session-context/context/README.md) · [lệnh `/compact`](../01-huong-dan-su-dung/commands/session-context/compact/README.md) · [lệnh `/clear`](../01-huong-dan-su-dung/commands/session-context/clear/README.md) · [lệnh `/rewind`](../01-huong-dan-su-dung/commands/session-context/rewind/README.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 4. Giới hạn subagent descriptions 15k tokens là gì?

> **Hỏi ngắn gọn:** lúc mở Claude Code có warning nhắc về subagent description — ý nó là gì?
>
> **Trả lời 1 câu:** Tổng `description` của tất cả custom subagents vượt ~15k tokens thì bị cảnh báo lúc startup.

**Giải thích:** Mỗi subagent có `description` — dòng mô tả "lúc nào thì gọi nó". Descriptions của TẤT CẢ custom subagents (trừ built-in) được nạp 1 lần lúc khởi động và nằm yên đó suốt session, nên chúng là khoản bạn trả ngay cả khi không gọi agent nào. Description kể cả cách implement (300 chữ) làm phình nhanh hơn nhiều so với 1 câu use case, đồng thời làm model chọn agent sai (đọc nhiều, dễ nhầm). Thấy warning xuất hiện lúc startup là cắt ngay.

Quy tắc: description = "khi nào gọi", body = "làm thế nào".

**Kiểm tra nhanh:**

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

Mong đợi: 20 agents × 800 tokens description = 16k → warning. Cắt mỗi description còn ~200 tokens → 4k, hết warning, auto-trigger còn chính xác hơn (model đọc ngắn dễ khớp).

**Đào sâu:** [FAQ 07 — subagents, teams, workflows](07-subagents-teams-workflows.md) · [lệnh `/agents`](../01-huong-dan-su-dung/commands/knowledge-system/agents/README.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 5. Multi-agent tốn bao nhiều token? (overhead ~20k, ~3–4x)

> **Hỏi ngắn gọn:** chia việc cho nhiều agent chạy song song có tốn kém hơn làm tay không?
>
> **Trả lời 1 câu:** Tốn hơn — mỗi lần spawn subagent mất ~20k tokens overhead, và multi-agent gấp ~3–4x so với làm tuần tự 1 luồng.

**Giải thích:** Mỗi lần spawn subagent phải đóng gói system prompt riêng + copy context + bộ tools → ~20k tokens overhead trước khi làm việc thật (số ước tính cộng đồng, không phải số chính thức của Anthropic). Multi-agent song song vì thế tốn ~3–4x so với tuần tự. Trần thực tế: 3–5 concurrent — hơn nữa thì tiền tăng mà tốc độ không tăng (model + API limits). Trước khi spawn, hỏi "việc này có đủ ồn/độc lập để đáng 20k không" — không thì làm trực tiếp.

**Kiểm tra nhanh:**

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

**Đào sâu:** [FAQ 07 — subagents, teams, workflows](07-subagents-teams-workflows.md) · [bài 06 — subagents & agent teams](../01-huong-dan-su-dung/06-subagents-agent-teams-parallel.md) · [bài 05 tips — chạy song song](../02-tips-thuc-chien/05-parallel-agents.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 6. MCP nhiều có sao không? (trần ~10 tools, sweet spot 3–6 servers)

> **Hỏi ngắn gọn:** cài thêm MCP server có làm Claude mạnh thêm không?
>
> **Trả lời 1 câu:** Không — quá ~10 tools visible là model chọn sai tool, bỏ sót tool; sweet spot là 3–6 servers thực dùng.

**Giải thích:** Mỗi MCP server expose tools vào context ngay cả khi bạn không gọi tới, nên không phải "càng nhiều càng mạnh" mà là "càng nhiều càng loãng": quá ~10 tools visible thì model bắt đầu chọn sai tool, bỏ sót tool, gọi thừa. Server nào 30+ tools mà tuần dùng 1 lần thì disable khi không cần; mỗi tháng mở `/mcp` 1 lần, tắt server 3 tháng không đụng.

**Kiểm tra nhanh:**

```bash
/mcp                # list servers + tools count
/mcp disable <tên>  # tắt server ít dùng
/mcp enable <tên>   # bật lại khi cần
```

Gắn 12 servers (120 tools) → `/usage` thấy MCP ngốn 8k/session mà accuracy giảm. Tắt 7 cái ít dùng, giữ 5 → còn 3k/session, gọi đúng hơn.

**Đào sâu:** [FAQ 04 — MCP](04-mcp-faq.md) · [bài 08 — kết nối công cụ ngoài](../01-huong-dan-su-dung/08-mcp-ket-noi-cong-cu-ngoai.md) · [lệnh `/mcp`](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 7. CLAUDE.md bao nhiều dòng là đủ? (<200 dòng)

> **Hỏi ngắn gọn:** CLAUDE.md viết bao nhiêu dòng là vừa, dài thêm có sao không?
>
> **Trả lời 1 câu:** Giữ dưới 200 dòng — vì nó được nạp lại mỗi turn, nên mỗi dòng thừa là tiền bạn trả mãi mãi.

**Giải thích:** CLAUDE.md load MỌI turn → dài hơn 200 dòng là vừa loãng signal vừa tốn token mỗi session. Quy tắc tách:

- **Giữ trong CLAUDE.md (<200 dòng):** always-on facts — stack, lệnh test/lint/build, cấu trúc thư mục, 5-10 quy ước bất di bất dịch.
- **Procedures/reference → skills:** quy trình dài, load-khi-cần (deploy, migrate, release...).
- **Rules theo path → `.claude/rules/` + `paths`:** luật chỉ áp dụng cho `api/**`, `web/**`...
- **Rule hay bị miss → hook:** cái gì nói 3 lần model vẫn quên → viết hook bắt buộc.

Mỗi tháng `wc -l` 1 lần: vượt 150 → vàng, vượt 300 → đỏ, tách ngay.

**Kiểm tra nhanh:**

```bash
wc -l CLAUDE.md
/doctor claude-md    # khám: dài quá? mâu thuẫn? trùng rules?
```

CLAUDE.md 320 dòng → `/doctor` báo đỏ → tách 4 khối theo thư mục sang `/rules`, còn 45 dòng → tiết kiệm ~2.7k token/session.

**Đào sâu:** [bài 03 — CLAUDE.md & memory](../01-huong-dan-su-dung/03-claude-md-memory-rules.md) · [FAQ 06 — skills, commands, CLAUDE.md](06-skills-commands-claude-md.md) · [lệnh `/doctor`](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) (trim CLAUDE.md cần ≥2.1.206) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 8. Skills tốn bao nhiều token? (~100 tokens, rẻ nhất)

> **Hỏi ngắn gọn:** thêm skill vào project có tốn thêm token không?
>
> **Trả lời 1 câu:** Chưa trigger, skill chỉ tốn tên + description (~100 tokens lúc start); body chỉ load khi model thật sự gọi.

**Giải thích:** Đây là lý do skill là extension RẺ NHẤT: MCP tools thì luôn visible trong context, subagent mỗi lần spawn ~20k, CLAUDE.md dài thì load mọi turn — còn skill chỉ trả tiền khi dùng. So ra:

```text
30 skills không dùng  = ~3k tokens startup (nhẹ)
30 MCP tools luôn on  = ~8-10k tokens startup (nặng)
1 subagent spawn      = ~20k (nặng nhất cho việc nhỏ)
```

Có procedure mới thì viết skill đầu tiên, đừng nhét vào CLAUDE.md, đừng spawn agent chỉ để "nhớ quy trình".

**Kiểm tra nhanh:** Ba dòng trên copy-paste được — tự đếm trong project của bạn: mở `/agents` và `/mcp` để xem mỗi extension đang chiếm bao nhiều dòng mô tả, rồi đối chiếu với số token startup ở trên.

**Đào sâu:** [FAQ 06 — skills, commands, CLAUDE.md](06-skills-commands-claude-md.md) · [bài 05 — skills & custom commands](../01-huong-dan-su-dung/05-skills-custom-commands.md) · [bài 07 tips — thiết kế skills](../02-tips-thuc-chien/07-thiet-ke-skills.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 9. Hooks tốn tokens không? (0 model tokens + bắt buộc thực thi)

> **Hỏi ngắn gọn:** quy tắc viết vào hook có tốn token như viết vào CLAUDE.md không?
>
> **Trả lời 1 câu:** Không — hook shell chạy ngoài model nên tốn 0 model tokens, và là thứ DUY NHẤT vừa miễn phí vừa bắt buộc thực thi.

**Giải thích:** Hook là script do CLI tự chạy mỗi lần tool chạy, model không nhìn thấy và không thể "quên" như một rule trong CLAUDE.md. Luật nào quan trọng + check được bằng script thì viết hook thay vì gõ chữ rồi cầu mong model nhớ. Rule nào đã nhắc 3 lần mà model vẫn quên (format, không commit secret, chạy test sau sửa) → chuyển thành hook.

**Kiểm tra nhanh:**

```json
{
  "hooks": {
    "PostToolUse": [{ "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "./scripts/lint-changed.sh" }] }]
  }
}
```

Mỗi lần sửa file tự lint, tốn 0 token model, không bao giờ miss.

**Đào sâu:** [FAQ 05 — hooks](05-hooks-faq.md) · [bài 07 — hooks tự động hóa](../01-huong-dan-su-dung/07-hooks-tu-dong-hoa.md) · [bài 06 tips — công thức hook](../02-tips-thuc-chien/06-hooks-recipes.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## 10. `/usage` vs `/cost` vs `/context` — xem cái nào khi nào?

> **Hỏi ngắn gọn:** ba lệnh `/context`, `/cost`, `/usage` khác nhau chỗ nào, nên gõ cái nào?
>
> **Trả lời 1 câu:** `/context` xem context đầy bao nhiêu, `/cost` xem session tốn bao nhiêu tiền, `/usage` xem hạng mục nào ngốn nhất và rate limit còn bao nhiêu.

**Giải thích:** 3 lệnh đo 3 thứ khác nhau, đừng xem 1 mà đoán 3:

| Lệnh | Trả lời câu hỏi | Dùng khi nào |
|---|---|---|
| `/context` | Context đầy bao nhiêu %? Cái gì ngốn? | Thấy Claude loãng, quên rule |
| `/cost` | Session này tốn bao nhiêu tiền? | Cuối session, muốn biết bill |
| `/usage` | Breakdown theo skills/subagents/plugins/MCP + rate limits? | Cuối tuần, tìm chỗ tốn để cắt |

Xem `/context` trong session (khi bắt đầu loãng), `/cost` cuối session, `/usage` cuối tuần — xem cả `/cost` và `/usage` chứ không xem 1 cái rồi đoán.

**Kiểm tra nhanh:**

```bash
/context    # đầy >70% → compact ngay
/cost       # session này bao nhiều?
/usage      # tuần này cái gì ngốn nhất? rate limit còn bao nhiều?
```

`/cost` thấy session 4$ → `/usage` thấy MCP ngốn 60% → tắt 5 servers thừa → tuần sau còn 1.5$/session.

**Đào sâu:** [lệnh `/context`](../01-huong-dan-su-dung/commands/session-context/context/README.md) · [lệnh `/cost`](../01-huong-dan-su-dung/commands/session-context/cost/README.md) · [lệnh `/usage`](../01-huong-dan-su-dung/commands/session-context/usage/README.md) · [bài 08 tips — tiết kiệm cost & token](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md) · [thứ tự debug cuối file](#vẫn-lỗi-thì-sao-contexttoken)

---

## Vẫn lỗi thì sao? (context/token)

Section này trả lời câu: làm theo 10 câu trên mà vẫn không ổn thì đi theo thứ tự nào?

1. `/context` — xác nhận đầy thật hay model dởm (đầy → compact; chưa đầy mà dởm → rewind + re-prompt).
2. `/cost` + `/usage` — tìm hạng mục ngốn (MCP? subagents? skill rác?).
3. `/doctor` — khám CLAUDE.md phình, plugin thừa, MCP chết.
4. `/compact [focus]` hoặc `/clear` + paste plan — cứu session.
5. `/debug` — session vẫn lạ sau khi đã gọn → chẩn đoán sâu.

**Kiểm tra nhanh:**

```bash
/context
/compact auth-flow
```

Thứ tự debug chung cho mọi lỗi (không chỉ lỗi context): `/status` → `claude doctor` → `/permissions` → `/debug` → `/bug` — chi tiết ở [FAQ 08](08-loi-thuong-gap-troubleshooting.md).

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
