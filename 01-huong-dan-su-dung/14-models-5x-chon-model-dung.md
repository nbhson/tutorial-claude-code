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

> **Cách đọc bảng này:** Mỗi dòng là một thuật ngữ. Cột "Hiểu nôm na" giải thích bằng lời đời thường, cột "Ví dụ" là lệnh thật để thử ngay.

---

## 1. Vì sao chọn model?

Mục này trả lời câu hỏi đầu tiên: tại sao phải băn khoăn chọn model thay vì cứ để mặc định? Vì chọn sai là trả tiền oan — hoặc tệ hơn, làm việc chậm và lỗi.

Model mạnh nhất không phải lúc nào cũng là model đúng. Mỗi task cần cân **chất lượng suy luận — tốc độ — chi phí**. Hãy tưởng tượng như chọn xe: đi mua rau thì xe máy là đủ, mượn cả chiếc container chỉ để chở một bịch rau thì tốn xăng vô ích.

- Dùng Fable/Opus sửa typo → trả gấp hàng chục lần mà kết quả y hệt Haiku/Sonnet. Giống thuê thợ vàng để siết ốc.
- Dùng Haiku thiết kế kiến trúc → thiếu depth, refactor 3 lần vẫn sai, tổng cost cao hơn 1 lần Opus đúng ngay. Như nhờ em nhỏ vẽ bản vẽ nhà: vẽ 3 lần vẫn sập.
- Không hiểu cache reads → shock khi bill gấp 3 lần dự tính (mục 5).

Quản lý: `/model` chuyển giữa session; frontmatter `model:` per-subagent (bài 06); env `ANTHROPIC_MODEL` cho CI (bài 12); `ANTHROPIC_DEFAULT_MODEL` đặt default cho session MỚI (≥2.1.236). Cost thực tế: `/cost` sau mỗi session.

> **Tóm gọn 1 câu:** Chọn model là cân ba thứ — chất lượng, tốc độ, chi phí; đắt nhất chưa chắc đã là lựa chọn đúng.

---

## 2. Bảng so sánh model hiện hành (10/2026)

| Model | Input / Output (USD/MTok) | Cache read | Context | Effort mặc định | Vai trò |
|---|---|---|---|---|---|
| **Fable 5.1** | $10 / $50 | 2.5% giá input | 1M | high | Hardest, long-horizon — **không bao giờ default** |
| **Opus 5.5** | $4 / $20 | 5% giá input | 1M | medium | **Default tài khoản** — suy luận sâu mặc định |
| **Sonnet 5.5** | $2 / $10 | 5% giá input | 1M | high | Daily coding — việc hàng ngày |
| **Haiku 5.5** | từ $0.10 / $0.50 | 10% giá input | 1M | medium | Việc vặt + subagents fan-out — rẻ nhất dòng 5.x |

> **Cách đọc bảng này:** Mỗi dòng là một model. Cột giá tính cho mỗi triệu token (MTok) — input là những gì bạn gửi đi, output là model trả về. Cột "Vai trò" cho biết khi nào nên dùng model đó.

> Subscription (Pro/Max/Team) tính theo quota, không trừ từng token — quota Opus/Fable hết nhanh hơn Sonnet/Haiku nhiều lần. Fable không nằm trong hạn mức thường: trên subscription bill bằng **usage credits** (`/model` picker hiện "Requires usage credits").

**Fable 5.1** (`claude-fable-5-1`, ≥2.1.257): KHÔNG là default trên plan/provider nào — muốn dùng phải gọi đích danh `/model fable`, như gọi món đặc biệt ngoài menu. Request bị safety classifier flag (cyber/bio) → tự động model fallback. Khi nào gọi: cả 3 ✓ — (1) task kéo dài nhiều giờ, cần coherence xuyên suốt? (2) Opus đã stuck? (3) hậu quả sai cao (migration prod, security-critical)?

**Opus 5.5** — default tài khoản (Pro/Max/Team/Enterprise/API/Bedrock/GCP từ ≥2.1.280; trước đó default là Sonnet 5 trên Pro/Team Standard, Opus 5 ở nơi khác). Ngoại lệ: Microsoft Foundry default Sonnet 4.5. Hãy xem nó như "cục pin đời thường" của session: dùng cho thiết kế, debug khó, refactor multi-file, review quan trọng.

**Sonnet 5.5** — implement theo plan, viết test, CRUD, docs; cache read rẻ nên session dài đỡ đau. Quy tắc: plan Opus, execute Sonnet (`opusplan`) — kiến trúc sư vẽ bản vẽ một lần, thợ thi công làm cả ngày.

**Haiku 5.5** — thay Haiku 4.5 làm mặc định Haiku trên Anthropic API (≥2.1.293); 5–10 Haiku song song rẻ hơn 1 Opus mà cover rộng hơn — như chia việc cho 10 thực tập sinh nhanh thay vì 1 giám đốc chậm. Lưu ý provider: Bedrock/GCP/AWS còn trả alias `haiku` → Haiku 4.5 (200K context) — đừng nhét cả monorepo vào đó.

> **Tóm gọn 1 câu:** Fable cho việc siêu khó đích danh, Opus cho suy luận sâu, Sonnet cho việc hàng ngày, Haiku cho việc vặt — mỗi model một vai, đừng dùng lẫn.

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

> **Cách đọc bảng này:** Mỗi dòng là một model kèm ID đầy đủ của nó. Cột "Bản tối thiểu" cho biết từ phiên bản Claude Code nào ID này mới tồn tại.

> 📄 **Code ví dụ:** [`examples/01-3-1-model-ids-chuan-dung-trong-api.sh`](examples/01-3-1-model-ids-chuan-dung-trong-api.sh)

> Gõ thiếu/thừa ID thì hệ thống báo "model not found" — giống gõ sai số tài khoản khi chuyển tiền. Khi nghi ngờ, đừng đoán: dùng `/model` để xem danh sách thật.
> Pin version: dùng full ID hoặc `ANTHROPIC_DEFAULT_OPUS_MODEL` / `_SONNET_MODEL` / `_HAIKU_MODEL` / `_FABLE_MODEL`; có `opus[1m]`/`sonnet[1m]` khi cần ép cửa sổ 1M cho riêng lượt.

> **Tóm gọn 1 câu:** Dùng đúng ID đầy đủ khi cấu hình máy móc, và luôn kiểm tra bằng `/model` thay vì đoán.

### 3.2. Aliases ngắn (dùng hàng ngày)

| Alias | Trỏ tới (Anthropic API) | Khi dùng |
|---|---|---|
| `default` | Opus 5.5 (runtime default theo account; Foundry = Sonnet 4.5) | Để nguyên mặc định |
| `best` | Fable nếu provider có, không thì Opus | Muốn model mạnh nhất hiện có |
| `opus` / `sonnet` / `haiku` | 5.5 (provider khác có thể đời cũ hơn) | Suy luận sâu / daily / việc nhỏ |
| `fable` | Fable 5.1 | Hardest/long-horizon đích danh |
| `opusplan` | **Plan bằng Opus + execute bằng Sonnet** | Mặc định cho task multi-file |

> **Cách đọc bảng này:** Mỗi dòng là một alias ngắn để gõ nhanh. Cột giữa cho biết alias đó thực sự trỏ tới model nào, cột phải là tình huống nên dùng.

### 3.3. `opusplan` — alias đáng tiền nhất

```text
opusplan = plan bằng Opus (hiểu sâu, thiết kế đúng) + execute bằng Sonnet (nhanh, rẻ).
Lỗi kiến trúc (sai ở plan) đắt gấp 10 lần lỗi implement → đổ tiền model mạnh vào
chỗ quyết định. Plan ~10% tokens × Opus + execute ~90% × Sonnet ≈ rẻ hơn full-Opus ~40%.
```

> 📄 **Code ví dụ:** [`examples/02-3-3-opusplan-alias-ang-tien-nhat.sh`](examples/02-3-3-opusplan-alias-ang-tien-nhat.sh)

### 3.4. `/model` — chuyển giữa session (giữ context)

> 📄 **Code ví dụ:** [`examples/03-3-4-model-chuyen-giua-session-giu-context.sh`](examples/03-3-4-model-chuyen-giua-session-giu-context.sh)

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

> 📄 **Code ví dụ:** [`examples/04-4-1-effort.sh`](examples/04-4-1-effort.sh)

### 4.2. Fast mode (Opus 5.5: $8/$40)

| Chế độ | Giá Opus 5.5 | Khi dùng |
|---|---|---|
| Normal | $4 / $20 | Mặc định — depth đầy đủ |
| Fast mode | $8 / $40 (đến 2.5x nhanh hơn) | Cần latency thấp, chấp nhận đắt gấp đôi |

> **Cách đọc bảng này:** So sánh hai chế độ chạy của cùng một Opus 5.5. Cột giữa là giá, cột phải là lúc nào nên chọn chế độ đó.

```text
Fast mode KHÔNG phải model khác — vẫn Opus, chỉ ưu tiên tốc độ.
Chỉ có trên Anthropic API/subscription (Pro/Max/Team/Enterprise + Console).
KHÔNG có trên Bedrock/GCP/Foundry/AWS Platform (bài 10). Trên subscription
nó trừ vào usage credits, không tính vào hạn mức plan.
Dùng khi: demo live, live debugging. KHÔNG dùng overnight batch/CI (phí tiền).
Rate limit fast mode riêng — hết → tự fallback về tốc độ chuẩn, icon ↯ xám.
```

> 📄 **Code ví dụ:** [`examples/05-4-2-fast-mode-opus-5-5-8.sh`](examples/05-4-2-fast-mode-opus-5-5-8.sh)

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

Mục này tiết lộ phần "mập mờ" nhất trong hóa đơn: thứ chiếm đa số bill không phải câu trả lời, mà là việc gửi lại context cũ đi gửi lại nhiều lần. Hiểu được điều này, bạn biết vì sao workflow lộn xộn làm bill tăng vọt.

```text
Agentic = mỗi step gửi lại gần như toàn bộ context. Không cache → mỗi step trả
full input price. Có cache → phần trùng tính giá cache read (5–10% input price).
Số minh họa (Opus 5.5, $0.20/1M cache read): session 50 steps × ~100K tokens,
không cache ≈ $20, cache tốt (90% hit) ≈ $3. Thực tế session dài: cache reads
= ĐA SỐ cost. Đổi model rẻ mà phá cache liên tục có thể đắt hơn ở lì Opus.
```

Giữ cache hit cao — cache giống cuốn sổ tay bạn đang mở sẵn; cứ gấp lại rồi mở trang khác là phải chép lại từ đầu:

```text
1. Đừng /model qua lại liên tục — mỗi lần đổi có thể phá cache prefix. Gom đoạn cần Opus/Fable làm 1 lượt rồi về Sonnet.
2. Đừng /cd lung tung (bài 10) hay nhét file khổng lồ không liên quan vào context.
3. Explore bằng Haiku subagents thay vì nhét 20 files vào main context.
4. Sau mỗi session: /cost → tỉ lệ cache read thấp bất thường? Xem lại workflow.
```

> **Tóm gọn 1 câu:** Cache read là phần chiếm đa số hóa đơn agentic — giữ workflow ổn định để giữ tỉ lệ cache hit cao.

---

## 6. Breaking changes Opus 5.5 (đọc kỹ trước khi upgrade)

| Thay đổi | Hệ quả | Fix |
|---|---|---|
| Thinking không tắt được | Latency floor cao hơn | Việc siêu nhỏ route Haiku/Sonnet effort low |
| Forced tool use lỗi (sai params, gọi thừa, từ chối vòng vo) | Prompt ép-tool cũ gãy | Viết lại thành "đề xuất + hỏi trước", hoặc tách step ép-tool sang Haiku/Sonnet |
| Thinking blocks GẮN conversation (không strip được) | History nặng, ảnh hưởng cache | Compact sớm khi chuyển phase (plan xong → compact → execute) |
| Computer tool cũ bị từ chối | Session lỗi tool | Upgrade computer tool lên bản tương thích |

> **Cách đọc bảng này:** Mỗi dòng là một breaking change khi lên Opus 5.5. Cột giữa là hậu quả bạn sẽ gặp, cột "Fix" là cách xử lý.

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

> **Cách đọc bảng này:** Đây là bảng tra nhanh khi phân công việc. Mỗi dòng là một loại task, kèm model + effort nên dùng và lý do ngắn gọn.

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

> **Cách đọc bảng này:** Mỗi dòng là một model cũ. Cột "Trạng thái" cho biết nó còn sống không, cột "Hành động" là việc bạn cần làm nếu đang dùng nó.

> 📄 **Code ví dụ:** [`examples/06-8-1-legacy-models.sh`](examples/06-8-1-legacy-models.sh)

### 8.2. fallbackModel — dự phòng khi model lỗi

> 📄 **Code ví dụ:** [`examples/07-8-2-fallbackmodel-du-phong-khi-model-loi.sh`](examples/07-8-2-fallbackmodel-du-phong-khi-model-loi.sh)

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

> **Cách đọc bảng này:** Mỗi dòng là một sai lầm hay gặp. Cột "Fix" là cách sửa ngay, kèm mục tham chiếu trong bài.

**Bài 1 (15 phút):** Cùng 1 task nhỏ, chạy thử với 3 models: haiku → sonnet → opus. Như nếm ba loại cà phê để biết loại nào "đủ vị" cho mình. Ghi lại `/cost` + thời gian + chất lượng. Kết luận model nào là "đủ"?

**Bài 2 (30 phút):** Dùng `opusplan` cho 1 task 3+ files — ghi tokens plan (Opus) vs execute (Sonnet), so với full-Opus. Rồi test 1 breaking change (mục 6): prompt ép-tool cũ → ghi lỗi → sửa → chạy lại.

**Bài 3 (15 phút):** Audit repo tìm model IDs cũ (lệnh `rg` mục 8.1). Lập bảng file → ID mới. Prompt ép-tool nào cần test lại?

**Flow chọn model 30 giây:** khó + mơ hồ + hậu quả lớn? → Opus (medium) → stuck 2 lần + hardest? → Fable. Không hiểm: việc lặp rõ ràng → explore/việc vặt = Haiku (low), còn lại = Sonnet; task >3 files → opusplan. Sau mỗi run `/cost` verify.

> **Tóm gọn 1 câu:** Ghi nhớ flow 30 giây: việc khó dùng Opus, việc thường dùng Sonnet, việc vặt dùng Haiku, và luôn kiểm tra `/cost` sau mỗi run.

**Link chéo:** [04 — Slash commands](./04-slash-commands-toan-tap.md) (`/model /effort /fast`) · [06 — Subagents](./06-subagents-agent-teams-parallel.md) (frontmatter `model:`, fan-out Haiku) · [10 — Permissions](./10-permissions-modes-availability.md) (fast mode theo provider) · [12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md) (`ANTHROPIC_MODEL`, pin version) · [02-tips/08 — Tiết kiệm cost](../02-tips-thuc-chien/08-tiet-kiem-cost-token.md) · Reference: [commands/model](./commands/model-mode/model/README.md), [commands/effort](./commands/model-mode/effort/README.md), [commands/fast](./commands/model-mode/fast/README.md).
