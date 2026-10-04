# /cost — Xem tốn bao nhiêu token và bao nhiêu tiền trong phiên

> Loại Built-in · Nhóm Session & Context · Nguy hiểm Không (lệnh chỉ đọc báo cáo billing, không xóa/sửa gì, không phát sinh phí khi gọi)

`/cost` là "hóa đơn tại bàn": cho biết session hiện tại đã đốt bao nhiêu input/output tokens (kể cả cache), quy ra tiền ước tính, để bạn quyết định có nên compact/clear/đổi model hay không.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/cost` | _(không có)_ | Hiện tổng tokens + chi phí ước tính của session hiện tại |

Không có flag `--json`, `--by-model`, `--reset`. Muốn chi tiết theo skill/MCP thì dùng `/usage`.

Ví dụ gọi từng dạng:

```bash
# Dạng 1: xem hóa đơn nhanh
/cost
```

```bash
# Dạng 2: xem trước khi quyết định có compact không
/context
/cost
# → context 70% + cost đã $2.30 → compact để các prompt sau rẻ hơn
```

```bash
# Dạng 3: chốt ca — ghi cost vào báo cáo
/cost
# → copy con số vào docs/sprint-log.md: "Ca sáng: 1.2M in / 80K out ≈ $3.10"
```

```bash
# Dạng 4: so sánh 2 model (làm tay 2 phiên)
/cost
# Phiên Sonnet: $1.20 cho cùng task
# Phiên Opus: $4.80 cho cùng task → quyết định khi nào đáng dùng Opus
```

Output mẫu (minh họa):

```text
Session cost (estimated):
  Input tokens:          850K (cached: 700K, uncached: 150K)
  Output tokens:          45K
  Cache read/write:      700K / 12K
  Estimated cost:         $2.45 (Sonnet 200K pricing)
Note: estimate only, actual billing per provider dashboard.
```

---

## Cách nó hoạt động

### Under-the-hood

1. **Đọc counters từ transcript:**
   - Mỗi request tới API trả về `usage: {input_tokens, output_tokens, cache_read, cache_creation}`. Claude Code cộng dồn từ đầu session (file `.jsonl` local).
2. **Nhân với bảng giá model:**
   - Giá lấy từ bảng giá built-in của model đang dùng (ví dụ Sonnet input $3/1M, output $15/1M, cache read $0.30/1M — số minh họa, giá thật xem dashboard).
   - Đổi model giữa chừng → mỗi đoạn tính theo giá model của đoạn đó, rồi cộng tổng.
3. **Hiển thị ước tính, không phải hóa đơn chính thức:**
   - `/cost` không gọi API billing của Anthropic/console. Số liệu là ước tính client-side, có thể lệch phí thuế, discount, rate đặc biệt của Team/API.
   - Muốn số chính thức → mở console dashboard / Stripe invoice.
4. **Phân biệt cache:**
   - Prompt caching giúp input lặp lại (CLAUDE.md, history cũ) rẻ hơn ~90%. `/cost` tách riêng `cached` vs `uncached` để bạn thấy caching cứu bao nhiêu tiền.
   - Paste file mới hoàn toàn → uncached → đắt. Hỏi tiếp trên history cũ → cached → rẻ.

```text
Ví dụ tác dụng của cache:
  Không cache: 850K input × $3/1M = $2.55
  Có cache (700K cached × $0.30): 700K×0.30 + 150K×3.0 = $0.21 + $0.45 = $0.66
  → tiết kiệm ~74% nhờ cache. Vì vậy đừng /clear bừa (clear làm mất cache).
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Trả lời câu hỏi | Nguồn số liệu |
|---|---|---|
| `/cost` | "Tốn bao nhiêu tiền session này?" | Cộng dồn usage API × bảng giá |
| `/usage` | "Tiền đi vào đâu? skill/MCP/plugin nào? Còn quota không?" | Breakdown theo component + rate limits |
| `/context` | "RAM còn bao nhiêu %?" | Tokenizer đếm context window hiện tại |

> Ví dụ phân biệt:
>
> - `/context` 70% nhưng `/cost` mới $0.50 → RAM đầy do log rác (nhờ cache nên vẫn rẻ) → `/compact` là đủ.
> - `/context` 30% nhưng `/cost` đã $8.00 → tốn do output dài / Opus / nhiều lượt tool → cần đổi chiến thuật (hỏi gọn, đổi Sonnet, tắt MCP rườm rà).

### Vì sao cost tăng nhanh bất thường? 4 thủ phạm

1. **Output dài:** output đắt gấp ~5x input. Bảo model viết file 2000 dòng 1 lần là đốt tiền. Chia nhỏ + bảo viết diff/gọn.
2. **Paste file lớn lặp lại:** mỗi lần paste là input uncached mới. Đọc 1 lần rồi reference bằng đường dẫn, đừng paste lại.
3. **Vòng lặp tool không hồi kết:** model `read` → `grep` → `read` 30 lần vì prompt mơ hồ. Viết prompt cụ thể để giảm vòng lặp.
4. **Dùng Opus cho việc vặt:** Opus đắt gấp ~5x Sonnet. Việc vặt (rename, format, đọc log) để Sonnet làm.

---

## Ví dụ thực tế

### Kịch bản 1: Task refactor 2 tiếng — kiểm soát ngân sách $5

```bash
# Đầu task: đặt ngân sách miệng "$5 cho task này"
# Sau 45 phút:
/cost
# → $1.80, input 400K (cached 320K), output 25K
# → đang trong ngân sách, làm tiếp

# Sau 90 phút:
/context
/cost
# → context 68%, cost $3.90
# → compact để prompt sau rẻ hơn (tận dụng cache mới)
/compact Giữ quyết định dùng Zod strict, file đã sửa src/billing/*, bước tiếp fix invoice test.

# Cuối task:
/cost
# → $4.60 tổng → ghi vào log, dưới $5 là đạt
```

### Kịch bản 2: Phát hiện MCP đốt tiền — tắt bớt

```bash
# Thấy cost vọt $2 sau 10 phút dù hỏi ít
/cost
# → input uncached cao bất thường

/usage
# → thấy github MCP trả 40K tokens/lần (lấy cả thread dài)

# Hành động: hỏi hẹp lại
Hãy chỉ lấy 5 issues mới nhất của repo X, mỗi issue chỉ lấy title + labels, không lấy comments.
# → /cost lần sau tăng chậm hẳn
```

### Kịch bản 3: So sánh Sonnet vs Opus cho cùng bug khó

```bash
# Phiên 1 (Sonnet): thử 30 phút không ra
/cost
# → $1.10 mà chưa fix được

# Quyết định: đáng ném Opus vào 10 phút không?
# Mở phiên mới với Opus, fix xong trong 3 prompts
/cost
# → $2.40 nhưng fix được → tổng $3.50 vẫn rẻ hơn 3 giờ lương dev
# Bài học: bug khó, dùng Opus sớm còn rẻ hơn ráng Sonnet 2 tiếng
```

### Kịch bản 4: Báo cáo cho sếp / client theo giờ

```bash
# Cuối ngày, cần số liệu để tính chi phí AI vào dự án
/cost
# → copy: "2026-10-04, task payments: 850K in (700K cached), 45K out, ≈$2.45 (Sonnet)"

# Ghi vào file để tháng sau tổng hợp
# docs/ai-spend-log.md:
# | ngày | task | model | cost ước tính |
# | 10-04 | payments | sonnet | $2.45 |
```

---

## Rủi ro & lưu ý

### Mất gì? Tốn token?

- Không mất gì, tốn ~0 token khi gọi.
- Nhưng hiểu nhầm số `/cost` là hóa đơn chính thức → tranh cãi billing sai. Luôn ghi chú "ước tính".

### Những gì `/cost` KHÔNG tính

- Phí IDE/Web subscription cố định (Pro $20/tháng) — `/cost` chỉ tính tokens API-style, không trừ quota subscription.
- Discount Team, credits khuyến mãi, thuế.
- Tiền model khác gọi qua MCP / API ngoài (ví dụ MCP gọi OpenAI riêng).
- Điện, thời gian dev chờ.

### Version tối thiểu & provider

- Có từ bản sớm, hiển thị cache breakdown rõ trên v2.0+, v2.1.x tách `cache read/write` đẹp hơn.
- Mọi plan đều xem được. Nhưng ý nghĩa khác nhau:
  - **Pro/Team subscription:** `/cost` chỉ để tham khảo hiệu năng, bạn không trả thêm theo token (trong quota).
  - **API pay-as-you-go / usage-based:** `/cost` gần với tiền thật bạn trả.

### Cloud vs Local

| Môi trường | Hành vi |
|---|---|
| CLI (API key) | Số gần với bill console nhất |
| CLI (subscription login) | Số chỉ mang tính tham khảo quota |
| IDE/Web | Hiển thị thêm biểu đồ theo ngày/tuần (tùy bản) |

> Giá model thay đổi theo thời gian. Đừng hardcode giá vào script; luôn xem dashboard khi cần số chính thức.

---

## Kết hợp trong workflow

| Combo | Cách dùng |
|---|---|
| `/context` + `/cost` | Cặp song sinh: RAM đầy không? Tiền tốn không? Rồi mới quyết compact/clear |
| `/cost` + `/usage` | Cost cao → usage để tìm thủ phạm (skill/MCP nào) |
| `/cost` + `/compact` | Cost tăng nhanh do input phình → compact để prompt sau rẻ |
| `/cost` + đổi model | Task vặt mà cost cao do Opus → đổi Sonnet |
| `/export` + `/cost` | Export transcript + kèm cost để báo cáo |

Ngưỡng hành động gợi ý (Sonnet, task vừa):

```bash
/cost
# < $1: thoải mái, cứ làm tiếp
# $1-3: để ý, compact 1 lần
# > $5/task nhỏ: dừng, xem lại prompt/MCP/model
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/cost` báo $0 dù hỏi nhiều | Đang dùng subscription quota, counters hiển thị khác / bản cũ chưa nhân giá | Không phải lỗi nghiêm trọng; xem `/usage` (quota) thay vì `/cost` |
| Số `/cost` khác dashboard | `/cost` ước tính client, dashboard tính giá chính thức + discount/thuế | Tin dashboard cho billing, tin `/cost` cho ra quyết định kỹ thuật |
| Cost vọt sau khi đổi sang Opus | Quên mình đang dùng Opus đắt gấp nhiều lần | Gõ `/cost` ngay sau khi đổi model để ý thức giá; đổi về Sonnet cho việc vặt |
| `/cost` không hiện cache breakdown | Bản CLI cũ | Update `npm i -g @anthropic-ai/claude-code` |
| Gõ `/cost` báo unknown | CLI quá cũ | Update CLI |
| Muốn cost theo từng skill/MCP | `/cost` chỉ tổng session | Dùng `/usage` để breakdown |
| Muốn reset cost về 0 | Không có nút reset — cost gắn với session | `/clear` hoặc phiên mới thì counters mới (tùy bản); muốn theo dõi task mới thì bắt phiên mới |

---

## Tham khảo

- Lệnh liên quan:
  - [../usage/README.md](../../session-context/usage/README.md) — breakdown ai đốt tiền + rate limits
  - [../context/README.md](../../session-context/context/README.md) — RAM đầy hay chưa
  - [../compact/README.md](../../session-context/compact/README.md) — nén để prompt sau rẻ hơn
  - [../clear/README.md](../../session-context/clear/README.md) — khi task xong thì reset cả RAM lẫn counters
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md` — bản đồ lệnh
  - `../10-permissions-modes-availability.md` — modes ảnh hưởng số lượt tool (ảnh hưởng cost)
  - `../08-mcp-ket-noi-cong-cu-ngoai.md` — MCP ngốn tokens thế nào
  - `../09-plugins-marketplaces.md` — plugins cũng có thể gọi model riêng

> Mẹo 1 dòng: _đặt thói quen `/context` + `/cost` cùng lúc — một cái giữ RAM nhẹ, một cái giữ ví nhẹ._
