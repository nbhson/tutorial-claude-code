# 14 — Models 5.x: chọn model đúng (Fable / Opus / Sonnet / Haiku)

> **Bài này cho ai:** dev chọn model trong `/model` mỗi ngày, và tech lead muốn gate model + kiểm soát chi phí cho team.
> **Cần gì trước:** đã cài + login Claude Code (bài 01); biết đọc `/cost` (Tips 08).
> **Đọc xong bạn làm được:** chọn đúng model cho từng task (không trả tiền Opus cho việc Haiku làm được); dùng `opusplan` tiết kiệm ~40% cho task multi-file; hiểu cache reads — phần chiếm đa số bill agentic; route model cho subagent; xử lý breaking changes khi lên Opus 5.5.
> **Thời gian:** ~35 phút.

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Model (Opus/Sonnet/Haiku/Fable) | 4 cỡ não: sâu—hàng ngày—việc vặt—siêu khó dài hơi | `/model sonnet` cho daily, `opus` cho kiến trúc |
| `/model` | Công tắc đổi não giữa session, giữ context | `/model sonnet` → chạy tiếp, không mất history |
| `opusplan` | Kiến trúc sư vẽ bản vẽ (Opus) + thợ thi công (Sonnet) | `claude --model opusplan` cho task >3 files |
| Effort (low→xhigh) | Vặn mức "cố gắng suy luận" | `/effort low` cho rename, `xhigh` cho đoạn khó nhất |
| Fast mode | Cùng Opus, latency thấp hơn, giá cao hơn | `/fast` cho demo live |
| Cache reads | Phần context trùng tính giá rẻ | `/cost` hiện `cache read` chiếm đa số bill |

---

## 1. Vì sao chọn model?

Model mạnh nhất không phải lúc nào cũng là model đúng. Mỗi task cần cân **chất lượng suy luận — tốc độ — chi phí**:

- Dùng Fable/Opus sửa typo → trả gấp hàng chục lần mà kết quả y hệt Haiku/Sonnet.
- Dùng Haiku thiết kế kiến trúc → thiếu depth, refactor 3 lần vẫn sai, tổng cost cao hơn 1 lần Opus đúng ngay.
- Không hiểu cache reads → shock khi bill gấp 3 lần dự tính (mục 5).

Quản lý: `/model` chuyển giữa session; frontmatter `model:` per-subagent (bài 06); env `ANTHROPIC_MODEL` cho CI (bài 12); `ANTHROPIC_DEFAULT_MODEL` đặt default cho session MỚI (≥2.1.236). Cost thực tế: `/cost` sau mỗi session.

---

## 2. Bảng so sánh model hiện hành (10/2026)

| Model | Input / Output (USD/MTok) | Cache read | Context | Effort mặc định | Vai trò |
|---|---|---|---|---|---|
| **Fable 5.1** | $10 / $50 | 2.5% giá input | 1M | high | Hardest, long-horizon — **không bao giờ default** |
| **Opus 5.5** | $4 / $20 | 5% giá input | 1M | medium | **Default tài khoản** — suy luận sâu mặc định |
| **Sonnet 5.5** | $2 / $10 | 5% giá input | 1M | high | Daily coding — việc hàng ngày |
| **Haiku 5.5** | từ $0.10 / $0.50 | 10% giá input | 1M | medium | Việc vặt + subagents fan-out — rẻ nhất dòng 5.x |

> Subscription (Pro/Max/Team) tính theo quota, không trừ từng token — quota Opus/Fable hết nhanh hơn Sonnet/Haiku nhiều lần. Fable không nằm trong hạn mức thường: trên subscription bill bằng **usage credits** (`/model` picker hiện "Requires usage credits").

**Fable 5.1** (`claude-fable-5-1`, ≥2.1.257): KHÔNG là default trên plan/provider nào — gọi đích danh `/model fable`. Request bị safety classifier flag (cyber/bio) → tự động model fallback. Khi nào gọi: cả 3 ✓ — (1) task kéo dài nhiều giờ, cần coherence xuyên suốt? (2) Opus đã stuck? (3) hậu quả sai cao (migration prod, security-critical)?

**Opus 5.5** — default tài khoản (Pro/Max/Team/Enterprise/API/Bedrock/GCP từ ≥2.1.280; trước đó default là Sonnet 5 trên Pro/Team Standard, Opus 5 ở nơi khác). Ngoại lệ: Microsoft Foundry default Sonnet 4.5. Dùng cho thiết kế, debug khó, refactor multi-file, review quan trọng.

**Sonnet 5.5** — implement theo plan, viết test, CRUD, docs; cache read rẻ nên session dài đỡ đau. Quy tắc: plan Opus, execute Sonnet (`opusplan`).

**Haiku 5.5** — thay Haiku 4.5 làm mặc định Haiku trên Anthropic API (≥2.1.293); 5–10 Haiku song song rẻ hơn 1 Opus mà cover rộng hơn. Lưu ý provider: Bedrock/GCP/AWS còn trả alias `haiku` → Haiku 4.5 (200K context) — đừng nhét cả monorepo vào đó.

---

## 3. Model IDs + aliases + `/model`

### 3.1. Model IDs chuẩn (dùng trong API / frontmatter / env)

| Model | ID chính xác | Bản tối thiểu |
|---|---|---|
| Opus 5.5 | `claude-opus-5-5` | ≥2.1.280 |
| Sonnet 5.5 | `claude-sonnet-5-5` | ≥2.1.284 |
| Fable 5.1 | `claude-fable-5-1` | ≥2.1.257 |
| Haiku 5.5 | `claude-haiku-5-5` | ≥2.1.293 |
| Haiku 4.5 | `claude-haiku-4-5-20251001` | — (có date suffix — copy chính xác) |

```bash
# Dùng ID trong CLI / env / frontmatter:
claude --model claude-sonnet-5-5
ANTHROPIC_MODEL=claude-haiku-5-5 claude -p "tóm tắt file này"
# Subagent frontmatter (.claude/agents/explorer.md): model: haiku
```

> Gõ thiếu/thừa ID → "model not found". Khi nghi ngờ → `/model` xem list thực tế thay vì đoán.
> Pin version: dùng full ID hoặc `ANTHROPIC_DEFAULT_OPUS_MODEL` / `_SONNET_MODEL` / `_HAIKU_MODEL` / `_FABLE_MODEL`; có `opus[1m]`/`sonnet[1m]` khi cần ép cửa sổ 1M cho riêng lượt.

### 3.2. Aliases ngắn (dùng hàng ngày)

| Alias | Trỏ tới (Anthropic API) | Khi dùng |
|---|---|---|
| `default` | Opus 5.5 (runtime default theo account; Foundry = Sonnet 4.5) | Để nguyên mặc định |
| `best` | Fable nếu provider có, không thì Opus | Muốn model mạnh nhất hiện có |
| `opus` / `sonnet` / `haiku` | 5.5 (provider khác có thể đời cũ hơn) | Suy luận sâu / daily / việc nhỏ |
| `fable` | Fable 5.1 | Hardest/long-horizon đích danh |
| `opusplan` | **Plan bằng Opus + execute bằng Sonnet** | Mặc định cho task multi-file |

### 3.3. `opusplan` — alias đáng tiền nhất

```text
opusplan = plan bằng Opus (hiểu sâu, thiết kế đúng) + execute bằng Sonnet (nhanh, rẻ).
Lỗi kiến trúc (sai ở plan) đắt gấp 10 lần lỗi implement → đổ tiền model mạnh vào
chỗ quyết định. Plan ~10% tokens × Opus + execute ~90% × Sonnet ≈ rẻ hơn full-Opus ~40%.
```

```bash
claude --model opusplan   # hoặc trong session: /model opusplan
```

### 3.4. `/model` — chuyển giữa session (giữ context)

```bash
/model            # picker: Enter = đổi + lưu default; "s" = chỉ session này
/model sonnet     # chuyển ngay, context giữ nguyên
/model fable      # đoạn khó, xong /model sonnet quay lại
```

```text
Workflow đổi model theo phase (đừng ở lì 1 model):
  opus (hiểu + plan) → /model sonnet (implement) → stuck thì /model opus/fable
  → /model sonnet/haiku làm tiếp. Gom phase để đỡ phá cache (mục 5).
Chú ý: đổi model bằng /model áp luôn cho subagents kế thừa model session —
muốn subagent giữ model nhỏ thì set `model:` trong frontmatter của nó.
```

---

## 4. Effort + fast mode

### 4.1. Effort

```text
Effort = mức "cố gắng suy luận". Cao hơn → thinking sâu, nhiều steps, nhiều tokens.
Mặc định: Fable = high, Opus = medium, Sonnet = high, Haiku = medium.
Opus 5.5 / Sonnet 5.5 / Haiku 5.5 / Fable luôn thinking — KHÔNG tắt được,
đừng prompt "đừng suy nghĩ" (tokens vẫn tính). Việc siêu nhỏ → route Haiku/Sonnet effort low.
```

```bash
# /effort: slider chọn mức; các mức low → medium → high → xhigh
/effort high    # đoạn khó, chấp nhận chậm + đắt
/effort xhigh   # mức cao nhất — cap team bằng setting maxEffortLevel (managed)
/effort low     # việc cơ học, muốn nhanh
```

### 4.2. Fast mode (Opus 5.5: $8/$40)

| Chế độ | Giá Opus 5.5 | Khi dùng |
|---|---|---|
| Normal | $4 / $20 | Mặc định — depth đầy đủ |
| Fast mode | $8 / $40 (đến 2.5x nhanh hơn) | Cần latency thấp, chấp nhận đắt gấp đôi |

```text
Fast mode KHÔNG phải model khác — vẫn Opus, chỉ ưu tiên tốc độ.
Chỉ có trên Anthropic API/subscription (Pro/Max/Team/Enterprise + Console).
KHÔNG có trên Bedrock/GCP/Foundry/AWS Platform (bài 10). Trên subscription
nó trừ vào usage credits, không tính vào hạn mức plan.
Dùng khi: demo live, live debugging. KHÔNG dùng overnight batch/CI (phí tiền).
Rate limit fast mode riêng — hết → tự fallback về tốc độ chuẩn, icon ↯ xám.
```

```bash
/fast   # toggle (Space bật/tắt + Enter). Lưu vào setting fastMode.
```

### 4.3. Chọn effort/fast theo task (cheat)

```text
Việc cơ học (format, rename, grep)  → haiku + effort low
Implement theo plan rõ              → sonnet
Debug khó, refactor kiến trúc       → opus + effort medium
Stuck sau 2 lần thử Opus            → opus effort high, vẫn stuck → fable
Demo live cần nhanh mà vẫn sâu      → opus fast mode
Overnight batch                     → KHÔNG fast (phí), chọn model đúng là đủ
```

---

## 5. Cache reads: cost thật của agentic

```text
Agentic = mỗi step gửi lại gần như toàn bộ context. Không cache → mỗi step trả
full input price. Có cache → phần trùng tính giá cache read (5–10% input price).
Số minh họa (Opus 5.5, $0.20/1M cache read): session 50 steps × ~100K tokens,
không cache ≈ $20, cache tốt (90% hit) ≈ $3. Thực tế session dài: cache reads
= ĐA SỐ cost. Đổi model rẻ mà phá cache liên tục có thể đắt hơn ở lì Opus.
```

Giữ cache hit cao:

```text
1. Đừng /model qua lại liên tục — mỗi lần đổi có thể phá cache prefix. Gom đoạn cần Opus/Fable làm 1 lượt rồi về Sonnet.
2. Đừng /cd lung tung (bài 10) hay nhét file khổng lồ không liên quan vào context.
3. Explore bằng Haiku subagents thay vì nhét 20 files vào main context.
4. Sau mỗi session: /cost → tỉ lệ cache read thấp bất thường? Xem lại workflow.
```

---

## 6. Breaking changes Opus 5.5 (đọc kỹ trước khi upgrade)

| Thay đổi | Hệ quả | Fix |
|---|---|---|
| Thinking không tắt được | Latency floor cao hơn | Việc siêu nhỏ route Haiku/Sonnet effort low |
| Forced tool use lỗi (sai params, gọi thừa, từ chối vòng vo) | Prompt ép-tool cũ gãy | Viết lại thành "đề xuất + hỏi trước", hoặc tách step ép-tool sang Haiku/Sonnet |
| Thinking blocks GẮN conversation (không strip được) | History nặng, ảnh hưởng cache | Compact sớm khi chuyển phase (plan xong → compact → execute) |
| Computer tool cũ bị từ chối | Session lỗi tool | Upgrade computer tool lên bản tương thích |

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
| Format, rename, classify | haiku | low | Opus làm cũng vậy mà đắt hàng chục lần |
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

```text
Cùng pattern cho implementer: model: sonnet + tools [Read, Edit, Write, Bash] +
permissionMode: acceptEdits + chỉ dẫn "implement đúng plan, không tự đổi kiến trúc".
Fan-out (rẻ mà cover rộng): main (opus) spawn 5 haiku explore 5 hướng →
gom báo cáo → main quyết định → sonnet implement. Chi tiết: bài 06.
```

---

## 8. Legacy / fallback / gate model

### 8.1. Legacy models

| Model cũ | Trạng thái | Hành động |
|---|---|---|
| Opus 4 / Opus 4.1 | **Bị xóa** | Không gọi được nữa — migrate ID sang `claude-opus-5-5` |
| Opus 4.5 – 4.8, Sonnet 5, Sonnet 4.6 | Legacy (còn nhưng không phát triển) | Task mới dùng 5.5x; task cũ giữ nguyên nếu đang ổn |
| Haiku 4.5 | Còn (200K context) | Mặc định Haiku trên Bedrock/GCP/AWS |

```bash
# Tìm model IDs cũ còn sót:
rg -n "opus-4|sonnet-4|haiku-4[^.]" --glob '!node_modules' --glob '!.git'
# → đổi từng hit sang ID mục 3.1, test 1 task mẫu trước khi merge.
```

### 8.2. fallbackModel — dự phòng khi model lỗi

```bash
# Trong Agent SDK / settings API: chuỗi fallback tối đa 3 model
# (fallbackModel / fallback model chain — Week 24/2026).
# Vd: chính Opus 5.5 → fallback Sonnet 5.5 → Haiku 5.5.
# Entry ngoài availableModels allowlist sẽ bị drop khỏi chuỗi.
```

### 8.3. Gate model cho team (managed settings)

```text
availableModels: ["sonnet", "haiku"]   # allowlist model user được chọn
enforceAvailableModels: true            # extend allowlist tới cả Default option
deniedModels: ["claude-opus-5-5"]       # chặn 1 version cụ thể (≥2.1.283)
model: claude-sonnet-5-5                # model khởi đầu (vẫn là initial, không phải enforcement)
```

---

## 9. Bẫy thường gặp + bài tập

| Pitfall | Fix |
|---|---|
| Default Fable cho mọi thứ | Fable chỉ đích danh khi Opus stuck — bill nổ |
| Ở lì Opus cả session dài | Chuyển `/model sonnet/haiku` theo phase |
| Haiku cho task kiến trúc | Thiếu depth, refactor 3 lần — plan Opus, execute Sonnet |
| Đổi model liên tục | Phá cache, bill cao hơn (mục 5) — gom phase |
| Prompt ép-tool cũ trên Opus 5.5 | Forced tool use lỗi (mục 6) — viết lại thành đề xuất + hỏi |
| Gọi Opus 4/4.1 trong CI cũ | Đã bị xóa → CI đỏ — migrate ID + pin version (mục 8.1) |
| Nhìn giá input/output mà quên cache | Cache reads mới là đa số bill — `/cost` mỗi session |

**Bài 1 (15 phút):** Cùng 1 task nhỏ, chạy 3 models (haiku → sonnet → opus). Ghi `/cost` + thời gian + quality. Kết luận model nào là "đủ"?

**Bài 2 (30 phút):** Dùng `opusplan` cho 1 task 3+ files — ghi tokens plan (Opus) vs execute (Sonnet), so với full-Opus. Rồi test 1 breaking change (mục 6): prompt ép-tool cũ → ghi lỗi → sửa → chạy lại.

**Bài 3 (15 phút):** Audit repo tìm model IDs cũ (lệnh `rg` mục 8.1). Lập bảng file → ID mới. Prompt ép-tool nào cần test lại?

**Flow chọn model 30 giây:** khó + mơ hồ + hậu quả lớn? → Opus (medium) → stuck 2 lần + hardest? → Fable. Không hiểm: việc lặp rõ ràng → explore/việc vặt = Haiku (low), còn lại = Sonnet; task >3 files → opusplan. Sau mỗi run `/cost` verify.

**Link chéo:** [04 — Slash commands](./04-slash-commands-toan-tap.md) (`/model /effort /fast`) · [06 — Subagents](./06-subagents-agent-teams-parallel.md) (frontmatter `model:`, fan-out Haiku) · [10 — Permissions](./10-permissions-modes-availability.md) (fast mode theo provider) · [12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md) (`ANTHROPIC_MODEL`, pin version) · [02-tips/08 — Tiết kiệm cost](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md) · Reference: [commands/model](./commands/model-mode/model/README.md), [commands/effort](./commands/model-mode/effort/README.md), [commands/fast](./commands/model-mode/fast/README.md).
