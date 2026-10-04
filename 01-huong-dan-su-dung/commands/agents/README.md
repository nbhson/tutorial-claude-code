# /agents — Quản lý subagent: đội quân AI chạy song song việc nặng

> Loại Built-in · Nhóm Tri thức & Hệ thống · Nguy hiểm Có nếu batch ẩu (30 subagent cùng ghi 1 file = xung đột; subagent kế thừa permissions nên bypass ở mẹ là bypass cả đàn)

`/agents` mở trung tâm quản lý subagent: xem danh sách đang chạy (Running), thư viện có sẵn (Library), tạo/sửa agent custom. Subagent là 1 phiên Claude độc lập với context riêng, nhận việc từ agent mẹ, làm xong trả kết quả về — mẹ không bị ngập context. Hiểu `/agents` là hiểu cách "thuê đệ" đúng cách.

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/agents` | _(không có)_ | Mở UI: tab Running + Library + tạo mới |
| Task tool | `subagent_type`, `prompt` | Mẹ spawning 1 subagent làm việc (trong chat/API) |
| `.claude/agents/*.md` | file định nghĩa | Agent custom của project (commit git) |
| `~/.claude/agents/*.md` | file định nghĩa | Agent custom cá nhân (mọi repo) |
| `--agents` (CLI) | JSON config | Định nghĩa agent khi chạy non-interactive |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: mở UI quản lý
/agents
# → tab Running: thấy 3 đứa đang chạy, kill đứa kẹt
# → tab Library: Explore, Plan, Bash, general-purpose...
```

```bash
# Dạng 2: thuê 1 subagent tìm hiểu code (trong chat, gõ tự nhiên)
# "Dùng Explore agent tìm xem auth flow đi qua những file nào"
```

```bash
# Dạng 3: thuê 3 đứa song song (model tự fan-out khi việc độc lập)
# "Song song: đứa 1 đọc api/, đứa 2 đọc web/, đứa 3 đọc migrations/ rồi tóm tắt"
```

```bash
# Dạng 4: định nghĩa agent custom (file .claude/agents/db-reviewer.md)
```

```markdown
---
name: db-reviewer
description: Review migration SQL, chặn DROP/TRUNCATE thiếu down script. Dùng khi chạm migrations/.
tools: Read, Grep, Glob
model: sonnet
---

Bạn là reviewer DB khó tính. Mọi migration phải có up + down.
CẤM approve nếu có DROP TABLE mà user chưa gõ ĐỒNG Ý.
Trả về: PASS/FAIL + danh sách lỗi + file:dòng.
```

```bash
# Dạng 5: gọi agent custom vừa tạo
# "Dùng db-reviewer kiểm tra migrations/ tuần này"
```

---

## Cách nó hoạt động

### Cơ chế sâu: Running / Library + subagent lifecycle

1. **Hai tab trong `/agents`:**
   - `Running`: các subagent đang sống trong session này (tên, task, thời gian chạy, nút kill). Đóng session là hết — không persistent.
   - `Library`: kho agent dùng được — gồm built-in (Explore, Plan) + custom (`.claude/agents/*.md` + `~/.claude/agents/*.md`) + plugin agents (nếu cài plugin).
2. **Lifecycle 1 subagent (5 pha):**
   - `spawn`: mẹ gọi Task tool với `subagent_type` + `prompt` (mục tiêu + ràng buộc + format output). Mẹ quyết định giao gì — càng cụ thể càng ít phải làm lại.
   - `fork context`: đứa con có context RIÊNG (trống, chỉ mang system prompt + CLAUDE.md/rules/memory như mẹ). Mẹ 100k token không truyền sang con — con tự đọc file nó cần. Đây là điểm tiết kiệm context cốt lõi.
   - `work`: con tự đọc file, chạy tool (trong giới hạn `tools` của nó + permissions kế thừa từ mẹ). Mẹ làm việc khác song song được.
   - `return`: con trả về TEXT tóm tắt (không trả cả context). Mẹ chỉ nhận kết quả gọn — VD "auth đi qua 5 file: ..." thay vì 20k token code.
   - `die`: con chết, context con bị huỷ. Muốn dùng tiếp phải spawn lại từ đầu (không có "gọi lại đứa cũ").
3. **Kế thừa gì từ mẹ?**
   - Có: permissions bảng, CLAUDE.md, rules, memory, MCP tools, model (trừ khi agent config `model` riêng).
   - Không: lịch sử chat mẹ, file mẹ đang mở, checkpoint/undo của mẹ.
   - Nghĩa là con không biết mẹ đã thử gì — phải ghi rõ trong prompt ("đừng thử cách X vì mẹ đã thử và fail với lỗi Y").
4. **Fan-out / fan-in (song song rồi gộp):**
   - 1 prompt mẹ → N con chạy song song (fan-out) → N kết quả về → mẹ gộp (fan-in).
   - Nhanh gấp N lần cho việc độc lập (đọc 3 thư mục). Nhưng N con cùng GHI 1 file = xung đột — quy tắc: song song chỉ cho việc ĐỌC hoặc ghi file KHÁC nhau.
5. **Explore vs Plan vs general-purpose:**
   - `Explore`: chỉ đọc (Read/Grep/Glob), không ghi, chạy nhanh, rẻ. Dùng để tìm hiểu code, không sợ nó phá.
   - `Plan`: đọc + vẽ kế hoạch, không code. Dùng với `/plan` cho task lớn.
   - `general-purpose`: làm gì cũng được (đọc + ghi + chạy). Đắt, mạnh — chỉ dùng khi cần.
   - Custom agent: bạn giới hạn `tools:` để ép con chỉ làm việc trong lồng (VD `tools: Read, Grep` = con không thể ghi dù muốn).
6. **Token và chi phí:**
   - Mỗi con tốn riêng (input: system + file nó đọc; output: kết quả trả về). 3 con đọc 3 thư mục ≈ 3× token 1 con — nhưng mẹ KHÔNG bị ngập, và nhanh hơn 3× thời gian.
   - Mẹ chỉ trả thêm phần kết quả gộp (vài trăm token/con). Pattern chuẩn: con đọc nhiều → trả ít.
7. **Giám sát và kill:**
   - Tab Running hiện thời gian + task. Con nào >10 phút không xong thường là kẹt (prompt mơ hồ, vòng lặp) → kill, chia nhỏ prompt, spawn lại.

### Sơ đồ lifecycle

```text
Mẹ (context 80k, đang bận)
  ├─ spawn Con A: "đọc api/, tóm tắt auth flow" ──→ context riêng ──→ trả về 300 token
  ├─ spawn Con B: "đọc web/, tóm tắt auth UI"  ──→ context riêng ──→ trả về 250 token
  └─ spawn Con C: "đọc migrations/, liệt kê bảng" ──→ context riêng ──→ trả về 200 token
       (3 con chạy SONG SONG, mẹ rảnh tay)
  ↓ fan-in: mẹ nhận 750 token gọn (thay vì tự đọc 30k token 3 thư mục)
```

### Khác gì với lệnh dễ nhầm?

| Cơ chế | Số context | Chết khi nào? | Dùng khi nào? |
|---|---|---|---|
| Subagent (`/agents`) | Riêng từng đứa | Xong việc là chết | Việc nặng, độc lập, tốn context |
| `/batch` | N đứa song song | Cùng chết khi xong batch | Lặp 1 việc trên N target |
| `/loop` | 1 đứa lặp lại | Hết vòng mới chết | Lặp tới khi pass |
| `/tasks` | Không (tracker) | Không | Chia việc cho chính mình |
| Hook | Không (script) | Chạy xong chết | Việc máy làm được, không cần AI |

> Quy tắc ngón tay cái:
>
> - **Việc độc lập + tốn context đọc → subagent. Lặp 1 việc N lần → `/batch` + subagent. Việc máy làm được → hook.**

---

## Ví dụ thực tế

### Kịch bản 1: Onboard repo lạ trong 10 phút (3 Explore song song)

Thay vì tự đọc 200 file:

```bash
# Gõ 1 câu, model tự fan-out 3 đứa:
# "Song song tìm hiểu repo này: đứa 1 đọc api/ (stack + entry point),
#  đứa 2 đọc web/ (framework + state), đứa 3 đọc migrations/ + README (schema + cách chạy).
#  Mỗi đứa trả về ≤15 dòng."
```

> Kết quả: 3 phút có bức tranh toàn repo. Mẹ chỉ nhận ~45 dòng gọn thay vì 30k token code.

### Kịch bản 2: Review song song trước khi merge (đọc, không ghi — an toàn)

```bash
# "Dùng 2 subagent review PR này song song:
#  đứa 1 (logic): check bug, race, null; đứa 2 (style): check convention trong .claude/rules/.
#  Cả 2 chỉ ĐỌC, không sửa. Trả về PASS/FAIL + file:dòng."
```

> Kết quả: 2 góc nhìn độc lập, không xung đột ghi. Mẹ gộp rồi tự sửa 1 lần.

### Kịch bản 3: Agent custom db-reviewer chặn migration ẩu

Tạo file `.claude/agents/db-reviewer.md` như mục Cú pháp dạng 4, rồi:

```bash
# Mỗi lần có migration mới:
# "Dùng db-reviewer kiểm tra migrations/2026-10-*.sql"

# Agent chỉ có tools Read/Grep → không thể sửa DB dù prompt injection.
# Trả về: FAIL — file 2026-10-04_add_index.sql thiếu down script (dòng 12).
```

### Kịch bản 4: Cứu batch kẹt — kill đứa treo trong Running

Triệu chứng: batch 5 đứa, 4 xong, 1 chạy 15 phút không về.

```bash
# Bước 1: mở UI
/agents
# → tab Running: thấy đứa #5 "đọc legacy/" chạy 15:32, status running

# Bước 2: kill đứa #5

# Bước 3: spawn lại với prompt nhỏ hơn:
# "Chỉ đọc legacy/auth.js (1 file, không đọc cả thư mục), tóm tắt hàm login ≤10 dòng"
```

> Bài học: prompt "đọc cả thư mục legacy 500 file" là quá to cho 1 con. Chia nhỏ là xong.

---

## Rủi ro & lưu ý

### Nguy hiểm khi nào?

| Tình huống | Rủi ro | Cách tránh |
|---|---|---|
| N con cùng GHI 1 file | Xung đột ghi, mất code, file rỗng | Song song chỉ cho việc ĐỌC; ghi thì mỗi con 1 file khác nhau, mẹ gộp sau |
| Mẹ ở bypass, spawn 30 con | 30 con cùng bypass — phá hoại song song | Kiểm tra permissions trước khi batch; không bypass khi fan-out |
| Prompt mơ hồ ("tìm hiểu giúp anh") | Con đọc cả repo 50k token, trả về chung chung | Prompt cụ thể: thư mục nào, trả về format gì, giới hạn bao nhiêu dòng |
| Con không biết mẹ đã thử gì | Làm lại việc fail, tốn tiền vòng lặp | Ghi rõ trong prompt: "đừng thử X (đã fail với lỗi Y)" |
| Agent custom tools quá rộng | Con làm việc ngoài ý định (xoá file khi chỉ cần đọc) | Giới hạn `tools:` tối thiểu (Explore-like: chỉ Read/Grep/Glob) |
| Tin kết quả con 100% | Con ảo giác file:dòng, mẹ merge mù | Mẹ spot-check 1-2 claim quan trọng trước khi gộp |

### Tốn token?

- Mỗi con ≈ 2-8k token (tuỳ nó đọc nhiều hay ít). 5 con ≈ 10-40k — đắt hơn tự làm 1 mình, nhưng NHANH hơn nhiều và mẹ không ngập.
- Ép con "trả về ≤15 dòng" để phần fan-in về mẹ rẻ. Con đọc nhiều → trả ít là pattern tiết kiệm nhất.

### Version / provider

- `/agents` UI (Running/Library): bản v2.x. Bản cũ chỉ spawn qua Task tool, không có UI kill.
- Agent custom `.claude/agents/`: v1.0.60+. Trước đó chỉ built-in.
- Bedrock/Vertex: subagent vẫn chạy, nhưng số lượng song song có thể bị giới hạn bởi rate limit provider.

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/agents` + `/batch` | Lặp N việc song song | `/batch` fan-out N con, mỗi con 1 target |
| `/agents` + `/plan` | Plan agent vẽ kế hoạch trước | Plan con vẽ, mẹ duyệt, general con code |
| `/agents` + `/rules` | Con tự nạp rules khu vực nó đọc | Con đọc `api/` tự thấy rule api |
| `/agents` + `/permissions` | Kiểm tra phanh trước khi thả đàn | Xem bảng allow/deny trước batch 30 |
| `/agents` + `/verify` | Con code, mẹ verify | Subagent sửa xong, `/verify` chạy test |

Workflow chuẩn "task lớn 3 pha":

```bash
# Pha 1: Explore (rẻ, chỉ đọc) — 3 con song song tìm hiểu
# Pha 2: Plan — 1 Plan agent vẽ kế hoạch, bạn duyệt
# Pha 3: Code — từng con code từng file khác nhau, mẹ gộp + /verify
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Con trả về chung chung, không dùng được | Prompt mơ hồ, không format output | Ghi rõ: "trả về danh sách file:dòng, ≤15 dòng, dạng bảng" |
| Con chạy 15 phút không xong | Ôm việc quá to (đọc cả repo) | Kill trong Running, chia nhỏ prompt (1 thư mục/con) |
| Hai con ghi đè nhau | Cùng ghi 1 file | Đổi sang mỗi con 1 file, mẹ gộp; hoặc chạy tuần tự |
| Gọi tên agent custom báo không thấy | Sai `name` trong frontmatter hoặc sai thư mục | Kiểm tra `.claude/agents/*.md` có `name:` khớp; `/agents` tab Library xem có không |
| Con không tuân rules | Con đọc thư mục khác với rules bạn nghĩ | Ghi rõ paths trong prompt; kiểm tra `/rules show` |
| Hết tiền nhanh khi batch | 30 con general-purpose cùng đọc nhiều | Dùng Explore cho việc đọc; giới hạn số con (5-10); ép output ngắn |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../batch/README.md](../batch/README.md) — fan-out N việc song song
  - [../loop/README.md](../loop/README.md) — lặp tới khi pass
  - [../tasks/README.md](../tasks/README.md) — tracker việc cho mình và đàn con
  - [../permissions/README.md](../permissions/README.md) — phanh kế thừa sang con
  - [../rules/README.md](../rules/README.md) — luật khu vực con tự nạp
  - [../verify/README.md](../verify/README.md) — kiểm tra việc con làm
- Bài tổng quan:
  - [../../03-claude-md-memory-rules.md](../../03-claude-md-memory-rules.md) — con có thấy memory/CLAUDE.md không (có)
  - [../../05-skills-custom-commands.md](../../05-skills-custom-commands.md) — skill vs agent khác gì
  - [../../06-subagents-agent-teams-parallel.md](../../06-subagents-agent-teams-parallel.md) — bài gốc của mọi pattern multi-agent
  - [../../07-hooks-tu-dong-hoa.md](../../07-hooks-tu-dong-hoa.md) — hook vs agent
  - [../../08-mcp-ket-noi-cong-cu-ngoai.md](../../08-mcp-ket-noi-cong-cu-ngoai.md) — con có dùng được MCP tools không (có)
  - [../../09-plugins-marketplaces.md](../../09-plugins-marketplaces.md) — plugin mang agent riêng

> Mẹo 1 dòng: _prompt cụ thể + việc đọc song song + ghi file khác nhau — và kill không tiếc con nào kẹt quá 10 phút._
