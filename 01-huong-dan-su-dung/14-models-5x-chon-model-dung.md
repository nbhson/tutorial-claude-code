# 14 — Models 5.x: Chọn Model Đúng (Fable / Opus / Sonnet / Haiku)

> Bài 14 của series. Đọc xong bạn chọn đúng model cho từng task, hiểu IDs +
> aliases + `/model`, và không còn trả tiền Opus cho việc Haiku làm được.
> Thời gian: ~35 phút.

## Mục lục

1. [Vì sao chọn model? (why)](#1-vì-sao-chọn-model-why)
2. [Bảng so sánh 4 models](#2-bảng-so-sánh-4-models)
3. [Model IDs + aliases + `/model`](#3-model-ids--aliases--model)
4. [Effort + fast mode](#4-effort--fast-mode)
5. [Cache reads: cost thật của agentic](#5-cache-reads-cost-thật-của-agentic)
6. [Breaking changes Opus 5.5](#6-breaking-changes-opus-55-đọc-kỹ-trước-khi-upgrade)
7. [Route model theo task + subagent routing](#7-route-model-theo-task--subagent-routing)
8. [Legacy / deprecated](#8-legacy--deprecated)
9. [Walkthrough + pitfalls + bài tập](#9-walkthrough--pitfalls--bài-tập)
10. [Link chéo](#10-link-chéo)

---

## 1. Vì sao chọn model? (why)

Model mạnh nhất không phải lúc nào cũng là model đúng. Mỗi task có 3 chiều
cần cân: **chất lượng suy luận — tốc độ — chi phí**. Dùng sai chiều là mất
tiền hoặc mất thời gian:

- Dùng Fable/Opus sửa typo → trả gấp 5–10 lần mà kết quả y hệt Haiku/Sonnet.
- Dùng Haiku thiết kế kiến trúc → thiếu depth, refactor 3 lần vẫn sai,
  tổng cost cao hơn 1 lần Opus đúng ngay.
- Không hiểu cache reads → shock khi bill gấp 3 lần dự tính (mục 5).

Nguyên tắc vàng:

```text
Task khó, mơ hồ, hậu quả lớn → model mạnh (Opus/Fable).
Task rõ ràng, lặp lại, khối lượng lớn → model rẻ + nhanh (Sonnet/Haiku).
Không bao giờ default Fable — chỉ gọi đích danh khi cần hardest/long-horizon.
```

- Quản lý: `/model` chuyển giữa session; frontmatter `model:` per-task (bài 06);
  env `ANTHROPIC_MODEL` cho CI (bài 12). Cost thực tế: `/cost` sau mỗi session.

---

## 2. Bảng so sánh 4 models

### 2.1. Bảng tổng (giá API chuẩn, USD / 1M tokens)

| Model | Input / Output | Context | Effort mặc định | Vai trò |
|---|---|---|---|---|
| **Fable 5.1** | $10 / $50 | 1M | high | Hardest, long-horizon — không bao giờ default |
| **Opus 5.5** | $4 / $20 | 1M | medium | Default mọi paid plan — suy luận sâu mặc định |
| **Sonnet 5.5** | $2 / $10 | 1M | (standard) | Daily coding — việc hàng ngày |
| **Haiku 4.5** | $1 / $5 | 200K | (light) | Việc nhỏ + subagents fan-out |

> Subscription (Pro/Max/Team) tính theo quota, không trừ từng token — quota Opus/Fable hết nhanh hơn Sonnet/Haiku nhiều lần.

### 2.2. Fable 5.1 — hardest/long-horizon, không bao giờ default

```text
Fable 5.1: đắt nhất ($10/$50), context 1M, effort high. Sinh ra cho task
hardest, long-horizon (reasoning sâu nhiều giờ, codebase lớn, research phức tạp).
KHÔNG BAO GIỜ default — gọi đích danh (alias fable, /model fable).
Dùng sai: bill nổ cho task Opus/Sonnet đã làm tốt.
```

Khi nào gọi Fable (checklist):

```text
✓ Task kéo dài nhiều giờ, dizaines steps, cần coherence xuyên suốt?
✓ Đã thử Opus mà stuck / quality chưa đạt?
✓ Hậu quả sai cao (migration prod, thiết kế security-critical)?
→ Cả 3 ✓ thì Fable. Thiếu 1 thì Opus trước đã.
```

### 2.3. Opus 5.5 — default mọi paid plan

```text
Opus 5.5: $4/$20, context 1M, effort medium. DEFAULT mọi paid plan.
Dùng cho: thiết kế, debug khó, refactor multi-file, review quan trọng.
Fast mode $8/$40 (mục 4) — nhanh hơn, đắt gấp đôi.
```

### 2.4. Sonnet 5.5 — daily coding

```text
Sonnet 5.5: $2/$10, context 1M — rẻ bằng nửa Opus. Việc hàng ngày:
implement theo plan đã duyệt, viết test, CRUD, docs, refactor cơ học.
Nhanh hơn Opus rõ rệt → vòng lặp code-test ngắn. Quy tắc: plan Opus,
execute Sonnet (alias opusplan — mục 3.3).
```

### 2.5. Haiku 4.5 — việc nhỏ + subagents

```text
Haiku 4.5: $1/$5, context 200K — rẻ nhất, nhanh nhất. Việc nhỏ (format,
rename, grep/explore, tóm tắt, classify) + subagents fan-out: 5–10 Haiku
song song rẻ hơn 1 Opus mà cover rộng hơn (mục 7.3). Lưu ý: context 200K,
không phải 1M — đừng nhét cả monorepo vào Haiku.
```

---

## 3. Model IDs + aliases + `/model`

### 3.1. Model IDs chuẩn (dùng trong API / frontmatter / env)

| Model | ID chính xác | Ghi chú |
|---|---|---|
| Opus 5.5 | `claude-opus-5-5` | Default paid plans |
| Sonnet 5.5 | `claude-sonnet-5-5` | Daily coding |
| Fable 5.1 | `claude-fable-5-1` | Gọi đích danh, không default |
| Haiku 4.5 | `claude-haiku-4-5-20251001` | Có date suffix — copy chính xác |

```text
⚠ Haiku ID có date suffix (-20251001) — gõ thiếu → "model not found".
Khi nghi ngờ → /model xem list thực tế thay vì đoán từ trí nhớ.
```

```bash
# Dùng ID trong CLI / env / frontmatter:
claude --model claude-sonnet-5-5
ANTHROPIC_MODEL=claude-haiku-4-5-20251001 claude -p "tóm tắt file này"
# Subagent frontmatter (.claude/agents/explorer.md): model: haiku
```

### 3.2. Aliases ngắn (dùng hàng ngày cho nhanh)

| Alias | Trỏ tới | Khi dùng |
|---|---|---|
| `opus` | Opus 5.5 | Suy luận sâu, debug khó |
| `sonnet` | Sonnet 5.5 | Daily coding |
| `haiku` | Haiku 4.5 | Việc nhỏ, explore |
| `fable` | Fable 5.1 | Hardest/long-horizon đích danh |
| `opusplan` | **Plan bằng Opus + execute bằng Sonnet** | Mặc định cho task multi-file |

### 3.3. `opusplan` — alias đáng tiền nhất

```text
opusplan = plan bằng Opus (hiểu sâu, thiết kế đúng) + execute bằng Sonnet
(nhanh, rẻ). Lỗi kiến trúc (sai ở plan) đắt gấp 10 lần lỗi implement → đổ
tiền model mạnh vào chỗ quyết định, tiết kiệm ở chỗ tay chân. Task điển hình:
plan 10% tokens × Opus + execute 90% × Sonnet ≈ rẻ hơn full-Opus ~40%.
```

```bash
# Dùng opusplan:
claude --model opusplan
# Hoặc trong session:
/model opusplan
```

### 3.4. `/model` — chuyển giữa session

```bash
# Trong session đang chạy:
/model
# → hiện model hiện tại + list chọn (opus/sonnet/haiku/fable/opusplan).

/model sonnet
# → chuyển ngay, context giữ nguyên, không mất history.

/model fable
# → chuyển sang Fable cho đoạn khó, xong /model sonnet quay lại.
```

```text
Chuyển model giữa session (giữ context + history — đừng ở lì 1 model):
  opus (hiểu + plan) → /model sonnet (implement) → stuck thì /model opus
  hoặc fable gỡ 1 đoạn → /model sonnet/haiku làm tiếp. Gom phase để đỡ phá cache (mục 5).
```

---

## 4. Effort + fast mode

### 4.1. Effort là gì

```text
Effort = mức "cố gắng suy luận" (low/medium/high). Effort cao → thinking sâu,
nhiều steps, nhiều tokens. Fable mặc định high, Opus mặc định medium.
Task dễ mà nghĩ lâu → hạ effort; task khó mà trả lời cạn → tăng effort.
```

```bash
# Đổi effort (tùy bản CLI — gõ "/" xem lệnh thực tế):
/effort high    # cho đoạn khó, chấp nhận chậm + đắt
/effort medium  # mặc định Opus
/effort low     # việc cơ học, muốn nhanh
# Chi tiết: commands/effort.
```

### 4.2. Fast mode (Opus 5.5: $8/$40)

| Chế độ | Giá Opus 5.5 | Khi dùng |
|---|---|---|
| Normal | $4 / $20 | Mặc định — depth đầy đủ |
| Fast mode | $8 / $40 | Cần latency thấp, chấp nhận đắt gấp đôi |

```text
Fast mode KHÔNG phải model khác — vẫn Opus 5.5, chỉ ưu tiên tốc độ.
Dùng khi: demo live, session interactive cần phản hồi nhanh, CI cần rút
wall-clock mà vẫn cần depth Opus. KHÔNG dùng cho overnight batch (phí tiền)
hay task đã hợp Sonnet/Haiku (đổi model rẻ hơn là nhanh + rẻ).
```

```bash
# Bật fast mode (Sub/Console có; Bedrock/AWS/GCP không — bài 10 mục 6.1):
/fast
# → toggle. Chi tiết: commands/fast.
```

### 4.3. Chọn effort/fast theo task (cheat)

```text
Việc cơ học (format, rename, grep)       → haiku + effort low
Implement theo plan rõ                    → sonnet (mặc định)
Debug khó, refactor kiến trúc             → opus + effort medium
Stuck sau 2 lần thử Opus                  → opus effort high hoặc fable
Demo live cần nhanh mà vẫn sâu            → opus fast mode (có tiền thì bật)
Overnight batch                           → KHÔNG fast (phí), chọn model đúng là đủ
```

---

## 5. Cache reads: cost thật của agentic

### 5.1. Vì sao bill cao hơn bảng giá input/output

```text
Agentic = mỗi step gửi lại gần như toàn bộ context. Không cache → mỗi step
trả full input price. Có cache → phần trùng khớp tính giá cache read rẻ hơn
nhiều. Thực tế session dài: cache reads (Opus 5.5: $0.20/1M) = ĐA SỐ cost.
Đổi model rẻ mà phá cache liên tục có thể đắt hơn ở lì Opus cache tốt.
```

### 5.2. Số minh họa (Opus 5.5)

```text
Session 50 steps × ~100K tokens: không cache ≈ $20; cache tốt (90% hit)
≈ $3 (4.5M read × $0.20 + 0.5M mới × $4). Chênh ~7 lần — cache không phải chi tiết nhỏ.
```

### 5.3. Giữ cache hit cao (thực hành)

```text
1. Đừng /model qua lại liên tục — mỗi lần đổi có thể phá cache prefix.
   Gom đoạn cần Opus/Fable làm 1 lượt rồi về Sonnet.
2. Đừng /cd lung tung (bài 10) hay nhét file khổng lồ không liên quan vào context.
3. Explore bằng Haiku subagents thay vì nhét 20 files vào main context.
4. Sau mỗi session: /cost → tỉ lệ cache read thấp bất thường? Xem lại workflow.
```

```bash
# Kiểm tra cost thực tế (đừng đoán — xem thật):
/cost
# → hiện tokens theo loại (input mới / cache read / cache write / output)
#   + tiền ước tính session này.
```

---

## 6. Breaking changes Opus 5.5 (đọc kỹ trước khi upgrade)

Lên Opus 5.5 từ bản cũ có 4 breaking changes hay cắn. Biết trước đỡ mất
buổi sáng debug "sao hôm nay nó lạ thế".

### 6.1. Thinking không tắt được

```text
Opus 5.5 LUÔN thinking (không tắt được như bản cũ) → latency floor cao hơn.
Fix: việc siêu nhỏ route sang Haiku/Sonnet effort low. Đừng prompt "đừng suy
nghĩ" — model vẫn thinking ngầm, tokens vẫn tính.
```

### 6.2. Forced tool use lỗi

```text
Pattern "ép model gọi tool X ngay" trên Opus 5.5 có thể lỗi (sai params, gọi
thừa, từ chối vòng vo). Fix: viết lại thành "đề xuất + hỏi trước", hoặc tách
step ép-tool sang Haiku/Sonnet (nghe lời hơn ở task cơ học).
```

### 6.3. Thinking blocks gắn conversation

```text
Thinking blocks GẮN vào conversation (không strip được). Hệ quả: history nặng,
mang thinking cũ theo mọi step (ảnh hưởng cache + context). Fix: compact sớm khi
chuyển phase (plan xong → compact → execute); đừng branch 1 conversation dài cho 2 task.
```

### 6.4. Computer tool cũ bị từ chối

```text
Opus 5.5 TỪ CHỐI computer tool phiên bản cũ ("I can't use that tool").
Fix: upgrade computer tool lên bản tương thích; check version floor (bài 10 mục 7.4).
```

```text
Checklist upgrade (dán cho team):
[ ] Việc nhỏ đã route Haiku/Sonnet? (thinking không tắt được)
[ ] Prompt ép-tool test lại? (mục 6.2) [ ] Compact giữa phase? (mục 6.3)
[ ] Computer tool bản mới? (mục 6.4) [ ] /cost sau 1 tuần so với trước upgrade?
```

---

## 7. Route model theo task + subagent routing

### 7.1. Bảng route theo task (dán lên tường team)

| Task | Model | Effort | Vì sao |
|---|---|---|---|
| Thiết kế kiến trúc, plan multi-file | opus / opusplan | medium | Quyết định đắt nhất → model mạnh |
| Debug stuck > 30 phút | opus → fable nếu vẫn stuck | high | Cần depth, không cần tốc độ |
| Implement theo plan đã duyệt | sonnet | default | Rõ ràng → rẻ + nhanh |
| Viết test, docs, CRUD | sonnet | default/low | Cơ học, khối lượng lớn |
| Explore codebase, grep, tóm tắt | haiku | low | Rộng + nhanh + rẻ |
| Format, rename, classify | haiku | low | Opus làm cũng vậy mà đắt 4–10 lần |
| Hardest / long-horizon đích danh | fable | high | Chỉ khi Opus chưa đạt |
| Demo live cần nhanh + sâu | opus fast | medium | Trả gấp đôi lấy latency |

### 7.2. Nguyên tắc route (3 câu)

```text
1. Plan đắt, execute rẻ: opusplan là default cho task > 3 files.
2. Fan-out rẻ, main đắt: explore đẩy Haiku, main giữ Opus/Sonnet.
3. Stuck thì leo thang: sonnet 2 lần → opus → fable. Ghi lý do để lần sau route đúng ngay.
```

### 7.3. Subagent routing (mẫu copy-paste)

```markdown
<!-- .claude/agents/explorer.md — explore rẻ bằng Haiku -->
---
model: haiku
tools: [Glob, Grep, Read]
permissionMode: plan
---
Chỉ ĐỌC và báo cáo (files liên quan + dòng quan trọng). Không sửa file.
```

```markdown
<!-- .claude/agents/implementer.md — implement bằng Sonnet -->
---
model: sonnet
tools: [Read, Edit, Write, Bash]
permissionMode: acceptEdits
---
Implement đúng plan được giao. Không tự đổi kiến trúc — cấn thì hỏi lại.
```

```markdown
<!-- .claude/agents/architect.md — thiết kế bằng Opus -->
---
model: opus
tools: [Read, Glob, Grep]
permissionMode: plan
---
Thiết kế + plan (steps + risks). KHÔNG code.
```

```text
Fan-out (rẻ mà cover rộng): main (opus) spawn 5 haiku explore 5 hướng →
gom báo cáo → main quyết định → sonnet implement. Chi tiết: bài 06.
```

---

## 8. Legacy / deprecated

| Model cũ | Trạng thái | Hành động |
|---|---|---|
| Opus 4 / Opus 4.1 | **Bị xóa** | Không gọi được nữa — migrate ID sang `claude-opus-5-5` |
| Opus 4.5 – 4.8 | Legacy (còn nhưng không phát triển) | Task mới dùng 5.x; task cũ giữ nguyên nếu đang ổn, migrate khi rảnh |
| Sonnet/Haiku đời cũ | Theo bảng provider | Tra docs hiện hành — date suffix Haiku đổi theo bản |

```text
Migrate (Opus 4/4.1 bị xóa):
[ ] grep repo + configs còn "opus-4"? → đổi sang claude-opus-5-5, test lại ép-tool (mục 6.2)
[ ] Task dở trên 4.5–4.8: để yên cho xong; task mới dùng 5.x
[ ] Pin version ở CI (bài 12) để lần sau không bị xóa bất ngờ
```

```bash
# Tìm model IDs cũ còn sót:
rg -n "opus-4|sonnet-4|haiku-4[^.]" --glob '!node_modules' --glob '!.git'
# → đổi từng hit sang ID mục 3.1, test 1 task mẫu trước khi merge.
```

---

## 9. Walkthrough + pitfalls + bài tập

### 9.1. Walkthrough: route đúng cho 1 task thật (20 phút)

```text
Bước 1: Lấy 1 task multi-file thật. Mở bằng opusplan.
Bước 2: Sau plan xong, /cost → ghi tokens plan. Implement xong, /cost → ghi tổng.
Bước 3: Chạy task tương tự full-sonnet và full-haiku. So quality + /cost 3 runs.
Bước 4: Spawn 3 haiku explore song song 1 câu hỏi codebase (bài 06). So thời gian
         + cost vs tự explore bằng main model.
```

### 9.2. Pitfalls + fix

| Pitfall | Vì sao | Fix |
|---|---|---|
| Default Fable cho mọi thứ | Bill nổ, nhanh hơn không bao nhiêu | Fable chỉ đích danh khi Opus stuck |
| Ở lì Opus cả session dài | Phần cơ học trả giá Opus | Chuyển `/model sonnet/haiku` theo phase |
| Haiku cho task kiến trúc | Thiếu depth, refactor 3 lần | Plan bằng Opus, execute mới rẻ |
| Quên date suffix Haiku | `model not found` | Copy `claude-haiku-4-5-20251001` chính xác |
| Đổi model liên tục | Phá cache, bill cao hơn (mục 5) | Gom phase, chuyển ít lần |
| Prompt ép-tool cũ trên Opus 5.5 | Forced tool use lỗi (mục 6.2) | Viết lại thành đề xuất + hỏi |
| Conversation Opus dài không compact | Thinking blocks nặng history | Compact giữa plan/execute |
| Gọi Opus 4/4.1 trong CI cũ | Đã bị xóa → CI đỏ | Migrate ID + pin version (mục 8) |
| Nhìn giá input/output mà quên cache | Shock bill (cache reads mới là đa số) | `/cost` mỗi session, tối ưu cache (mục 5.3) |

### 9.3. Bài tập thực hành

**Bài 1 (15 phút):** Cùng 1 task nhỏ, chạy 3 models (haiku → sonnet → opus). Ghi `/cost` + thời gian + quality. Kết luận model nào là "đủ"?

**Bài 2 (15 phút):** Dùng `opusplan` cho 1 task 3+ files. Ghi tokens plan (Opus) vs execute (Sonnet). So với full-Opus — tiết kiệm bao nhiêu %?

**Bài 3 (15 phút):** Test 1 breaking change (mục 6): prompt ép-tool cũ trên Opus 5.5 → ghi lỗi → sửa theo fix → chạy lại so sánh.

**Bài 4 (15 phút):** Audit repo tìm model IDs cũ (lệnh `rg` mục 8). Lập bảng file → ID 5.x mới. Prompt ép-tool nào cần test lại?

### 9.4. FAQ models

| Câu hỏi | Trả lời |
|---|---|
| Model nào làm default? | Opus 5.5 (mọi paid plan). Fable không bao giờ default |
| `opusplan` là gì? | Alias: plan Opus + execute Sonnet — default tốt cho task multi-file |
| Khi nào dùng Fable? | Opus stuck 2 lần + task hardest/long-horizon + hậu quả sai cao |
| Fast mode có phải model khác? | Không — vẫn Opus 5.5, giá $8/$40, chỉ ưu tiên latency |
| Sao bill cao hơn tính từ bảng giá? | Cache reads ($0.20) mới là đa số cost agentic — xem `/cost` |
| Opus 4 còn dùng được? | Opus 4/4.1 bị xóa; 4.5–4.8 legacy — migrate sang 5.x |

---

## 10. Link chéo

- **Bài 04 — Slash commands**: `/model`, `/cost`, `/effort`, `/fast` chi tiết.
- **Bài 06 — Subagents**: `model:` frontmatter, fan-out Haiku, permissionMode per-agent.
- **Bài 10 — Permissions/availability**: fast mode theo provider (Bedrock/AWS/GCP
  không có), version floor khi "lệnh không tồn tại".
- **Bài 12 — SDK/CI**: `ANTHROPIC_MODEL` env, pin version tránh bị xóa bất ngờ.
- **02-tips/08** + **commands/model, commands/effort, commands/fast**: case study cost + reference đầy đủ.
