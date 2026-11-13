# Tips 01 — Vệ sinh context: kỹ năng quyết định 80% kết quả

> **Bài này cho ai:** dev dùng Claude Code hàng ngày nhưng hay bị "Claude dở đi" giữa session, hoặc tech lead muốn chuẩn hóa cách quản lý context cho team.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)).
> **Đọc xong bạn làm được:** chẩn đoán session "bẩn" và cứu bằng `/export` → `/compact`/`/clear`; dùng đúng 5 thói quen nền; cắt "thuế ẩn" config (CLAUDE.md, skills, subagents, MCP).
> **Thời gian:** ~45 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na | Ví dụ |
|---|---|---|
| Context window | Bộ nhớ tạm của model: mọi thứ trong session đều nằm ở đó, đầy thì model dở | 140K tokens sau 90 phút lan man |
| `/clear` | Xóa hội thoại, giữ file trên đĩa — token về ~0–2% | Xong bug CSS → `/clear` → task mới |
| `/compact [focus]` | Nén hội thoại thành tóm tắt, dặn giữ gì bỏ gì | `/compact Giữ decisions 1-5, bỏ log` |
| `/usage` | Breakdown token per-MCP/skill/subagent/plugin + rate limits (từ w21/2026) | Skill nào 0 lần gọi 2 tuần |
| Rewind (Esc Esc) | Quay cả code + hội thoại về checkpoint trước | Sửa sai 2 lần → Esc Esc → re-prompt |
| `/doctor` | Audit: skill ế, MCP nặng, hook chậm — bí danh `/checkup` (từ w28/2026) | `/doctor` mỗi tháng 1 lần |

---

## 1. Vì sao vệ sinh context quyết định 80%?

Hầu hết "Claude dở đi" không phải do model kém, mà do **context bẩn**: bắt đầu bằng bug CSS 15 phút, tiện hỏi luôn chuyện deploy, rồi viết SQL, rồi refactor auth — 90 phút sau context 140K tokens, model quên rule `CLAUDE.md`, sửa A hỏng B. Hãy hình dung context như bàn làm việc: bàn càng chất nhiều giấy vụn, càng dễ lấy nhầm tờ — model cũng vậy, context càng rác nó càng dễ "chạm" nhầm thông tin.

> Quy tắc vàng: **files persist, context thì không** (cái gì quan trọng thì save ra file); **1 task = 1 session sạch** (đổi task là đổi session); **việc ồn ào đẩy sang chỗ khác** (subagent, `/btw`, file trung gian) — giữ main session gọn để ra quyết định.

Ba con số cần ghim vào đầu: **~70–80%** là ngưỡng bắt đầu compact/reset (chạy `/context`, đừng đợi 95%); **~15K tokens** là trần cộng dồn subagent descriptions lúc startup (quá là bị warning); **~10 tools** là ngưỡng MCP tools visible bắt đầu chọn sai (prune server không dùng). Coi 3 con số này như vạch đèn báo xăng trên xe: chạm tới là đổ (dọn context), đừng đợi cạn giữa đường.

> **Tóm gọn 1 câu:** Claude dở đi 9/10 là do bàn làm việc (context) chất rác — dọn sớm bằng `/clear`/`/compact` rẻ hơn nhiều so với ngồi dọn khi đã chật.

---

## 2. Cơ chế: context window hoạt động thế nào?

Mục này giải thích "vì sao dọn context lại có tác dụng" — hiểu cơ chế thì bạn biết cái gì gánh theo, cái gì ném đi được, thay vì nhớ máy móc các lệnh.

Mỗi prompt gửi đi gồm `[system prompt + CLAUDE.md + skills + MCP tool defs] + [history] + [tool calls/results] + [prompt mới]` — mọi thứ đã làm đều bị "thuế" mỗi turn sau (đọc 20 files → 20 file contents gánh theo; paste log 800 dòng → gánh theo 20 turns). Ba cơ chế khiến context đầy thì model dở: **(1) Attention dilution** — 150K tokens rác làm rule quan trọng bị "chìm" (quên convention, đổi API không xin phép); **(2) Recency bias + lost-in-the-middle** — model nhớ đầu/cuối, quên giữa, nên quyết định chốt ở turn 12 bị "chôn" dưới log ở turn 40 → ghi quyết định ra `plan.md`/`decisions.md`; **(3) Auto-compact mất kiểm soát** — chạm ~80–90% là tự nén, hay mất plan giữ vụn → compact chủ động với focus trước.

> Không vệ sinh: 10 turns × 100K rác = 1M input lãng phí. Vệ sinh: 10 × 5K = 50K → rẻ hơn ~95% (xem [Tips 08](./08-tiet-kiem-cost-token.md)).

> **Tóm gọn 1 câu:** Mỗi thứ trong context là "hành lý" mang theo mọi turn sau — hành lý ít đi thì mỗi turn rẻ hơn và model tỉnh táo hơn.

---

## 3. Năm thói quen nền

Mục này là 5 thói quen lõi của cả bài — giống 5 thao tác rửa tay trước khi ăn: làm quen một lần, dùng cả ngày.

### 3.1. `/clear` giữa các task không liên quan

Thói quen ROI cao nhất: drop toàn bộ history, giữ file trên đĩa + nạp lại `CLAUDE.md`/settings/skills. Giống xóa bảng trắng sau mỗi buổi họp — bảng sạch cho buổi sau, còn biên bản đã chụp ảnh (file) thì vẫn còn. Dùng khi: xong việc vặt → chuyển feature lớn; paste log khổng lồ xong; chuẩn bị demo; model "ám ảnh" chuyện cũ.

> 📄 **Code ví dụ:** [`examples/01-3-1-clear-giua-cac-task-khong-lien.sh`](examples/01-3-1-clear-giua-cac-task-khong-lien.sh)

Trước khi clear task dài: `/export` rồi copy quyết định vào `docs/decisions.md`, sau đó nạp lại (`Hãy đọc docs/decisions.md và tiếp tục bước 3 trong plan.md.`). Từ w26/2026 `/rewind` vẫn resume được ngay cả sau `/clear` — nhưng đừng dựa vào đó thay cho save file.

### 3.2. Rewind thay vì cãi

**Correct 2 lần vẫn sai → dừng cãi, rewind.** Double-Esc mở rewind menu → quay cả code + conversation về checkpoint trước khi rẽ sai.

```text
Turn 1: "Sửa hàm login, đừng đổi API." → Claude đổi API + hỏng test.
Turn 2: "Tôi đã bảo đừng đổi API, sửa lại." → vá thêm, test vẫn đỏ.
STOP. Không gõ turn 3. Esc Esc → checkpoint trước turn 1 → re-prompt:
"Chỉ sửa src/auth/login.ts hàm validate(), giữ nguyên export. Đọc test login.test.ts
trước và liệt kê 3 cases phải giữ xanh."
```

### 3.3. `/btw` cho câu hỏi phụ

`/btw` = full context, **no tools**, không thêm vào history:

> 📄 **Code ví dụ:** [`examples/02-3-3-btw-cho-cau-hoi-phu.sh`](examples/02-3-3-btw-cho-cau-hoi-phu.sh)

Không dùng khi cần chạy tools (→ subagent) hoặc muốn lưu quyết định (→ hỏi thường + ghi file).

### 3.4. Đẩy exploration ồn sang subagents

Subagent = fresh context + full tools, chỉ trả summary về main (~500–1500 tokens thay vì 30K tokens file reads):

```text
Dùng subagent explore src/auth/ với phạm vi hẹp:
- Chỉ đọc files liên quan tới login + refresh token.
- Trả về: files sẽ sửa/đọc + flow hiện tại (5 bullet) + 2 phương án (pros/cons).
- Không sửa code, không chạy test nặng. Chỉ trả summary, không dump log.
```

Đừng spawn agent chung chung — luôn giao 1 task hẹp + output format. Xem [Tips 05](./05-parallel-agents.md).

### 3.5. `/compact [focus]` khi >80% + `/context` + `/usage`

> 📄 **Code ví dụ:** [`examples/03-3-5-compact-focus-khi-80-context-usage.sh`](examples/03-3-5-compact-focus-khi-80-context-usage.sh)

> **Tóm gọn 1 câu:** Năm thói quen trên là bộ "dọn bàn định kỳ" — clear khi đổi việc, rewind khi đi sai, hỏi phụ ngoài mạch chính, việc ồn giao trợ lý, và compact có dặn dò trước khi bàn chật.

---

## 4. Trần context: CLAUDE.md + skills + subagents + MCP + doctor

Mục này nói về "thuế ẩn" — thứ bạn không paste gì mà context vẫn nặng vì config phình. Muốn cắt bill thì phải rà đủ 5 nguồn này, không chỉ dọn hội thoại.

### 4.1. CLAUDE.md <200 dòng

Nạp **mọi turn** — 800 dòng rules = trả thuế 800 dòng × 100 turns. Giống tiền thuê nhà tính theo ngày: càng để nhiều đồ thừa, càng trả nhiều mỗi ngày.

```markdown
# Project X — 5 dòng mô tả + stack chính

## Luật hay sai nhất (5-10 dòng, front-load lên đầu)
- Luôn chạy pnpm test auth trước khi kết luận done.
- Không sửa src/generated/, không commit thẳng main.

## Chi tiết xem thêm (import, không paste)
- Kiến trúc: @docs/architecture.md
- Rules theo thư mục: .claude/rules/*.md
```

Front-load rule hay sai nhất lên đầu; procedures dài → tách `.claude/rules/` hoặc skills (xem [Tips 07](./07-thiet-ke-skills.md), [Tips 09](./09-teamwork-chuan-hoa.md)).

### 4.2. Skills: đừng nhét procedure vào CLAUDE.md

Skills chỉ tốn ~100 tokens (tên + description) lúc startup; body chỉ load khi trigger. Skill load sai lúc → siết `description` + thêm `when_to_use`. Skill ế lâu ngày → `/skill-doctor` (từ w36/2026) audit context cost từng skill. Tắt skill ồn qua `settings.json`: `{ "skillOverrides": { "heavy-deploy-helper": { "enabled": false } } }`.

### 4.3. Subagent descriptions >15K tokens → warning

Descriptions cộng dồn lúc startup; quá ~15K → warning, chọn agent sai. Description 1–2 câu use-case (`"Tester cho payments. Dùng khi cần chạy pnpm test payments và báo pass/fail + log."`), chi tiết đẩy vào body, xóa agent 1 tháng không dùng.

### 4.4. MCP: quá ~10 tools visible → accuracy giảm

Tất cả tool defs nằm trong context; quá nhiều → chọn sai tool, retry tốn thêm. Giữ ≤6 servers thực dùng, prune server 2 tuần không dùng, ưu tiên project-scope (`.mcp.json`). `/mcp` xem server đang bật; `/usage` (w21/2026) xem per-MCP + per-plugin tokens.

### 4.5. `/doctor` định kỳ

> 📄 **Code ví dụ:** [`examples/04-4-5-doctor-inh-ky.sh`](examples/04-4-5-doctor-inh-ky.sh)

Lịch: mỗi tháng 1 lần (team) hoặc sau khi cài 2–3 plugins/skills mới; `/skill-doctor` đi sâu riêng context cost của skills.

> **Tóm gọn 1 câu:** Context nặng không chỉ vì hội thoại — CLAUDE.md, skills, subagent descriptions và MCP đều "gánh theo" mỗi turn; rà định kỳ bằng `/doctor` là cắt thuế ẩn.

---

## 5. Dấu hiệu context bẩn và cách cứu

Mục này là bảng "bệnh sĩ": đối chiếu triệu chứng đang gặp vào dòng tương ứng để biết chẩn đoán và lệnh cứu ngay.

| Dấu hiệu | Chẩn đoán | Cứu ngay (copy-paste) |
|---|---|---|
| Claude đọc hàng trăm file sau chữ "investigate" | Scope quá rộng | `"Chỉ explore src/auth/login*, trả 5 files liên quan nhất"` hoặc ném sang subagent |
| Trả lời lan man, quên rule đầu session | Attention dilution | `/compact Giữ rules CLAUDE.md + decisions 1-5, bỏ log cũ` hoặc `/clear` + paste plan |
| Sửa chỗ A hỏng chỗ B | Task quá lớn trong 1 context | Chia phase, mỗi phase 1 session fresh (mục 6) |
| `/context` >75% giữa task | Rác research còn nằm lại | `/export` → `/clear` → nạp lại `plan.md` gọn |
| Subagent trả dump 200 dòng log | Thiếu output contract | `"Chỉ trả quyết định + evidence, không dump log"` |

> **Cách đọc bảng này:** quét cột "Dấu hiệu" trước để tìm dòng khớp triệu chứng đang gặp; cột "Cứu ngay (copy-paste)" là lệnh dán được vào session luôn — không cần đọc cột giữa nếu đã gấp.

> **Tóm gọn 1 câu:** Context bẩn có "mặt mũi" riêng (quên rule, lan man, sửa A hỏng B) — gặp đúng bệnh thì dùng đúng thuốc, đừng xoá cả session khi chỉ cần compact.

---

## 6. Recipes session sạch (copy-paste)

### Recipe A — Ngày nhiều task vặt (1 session 1 việc)

> 📄 **Code ví dụ:** [`examples/05-recipe-a-ngay-nhieu-task-vat-1-session.sh`](examples/05-recipe-a-ngay-nhieu-task-vat-1-session.sh)

### Recipe B — Cứu session đang bẩn (không mất việc)

> 📄 **Code ví dụ:** [`examples/06-recipe-b-cuu-session-ang-ban-khong-mat.sh`](examples/06-recipe-b-cuu-session-ang-ban-khong-mat.sh)

### Recipe C — Hỏi phụ không bẩn mạch chính

`/btw hàm calculateTotal trong src/cart/total.ts làm gì, 3 bullet?` (mục 3.3) hoặc `Dùng subagent đọc src/payments/*.ts, tóm tắt flow refund 8 bullet + file:line.` (mục 3.4). Kịch bản task lớn research → plan → implement → review xem bảng walkthrough mục 7.

---

## 7. Walkthrough: task refactor 3 ngày

| Ngày | Session | Prompt mở đầu (copy-paste) |
|---|---|---|
| Ngày 1 | Research (30p) | `"Dùng subagent explore src/auth.ts. Trả: hàm chính + dependencies + 3 rủi ro. Table file:line."` + `/btw` hỏi hướng tách |
| Ngày 1 | Plan (20p, fresh) | `/clear` → plan mode: `"Đọc plan.md + outline auth.ts. Trình plan 3 modules + verify từng phase. Chờ duyệt."` → commit `plan.md` |
| Ngày 2 | Implement | `/clear` → `"Đọc plan.md. Chỉ làm Phase 1 (tách types). Chạy pnpm test auth, dán log, dừng."` (lặp Phase 2) |
| Ngày 3 | Review (fresh) | `"Reviewer fresh review diff vs plan.md. Finding = bug/security/test-gap. [SEVERITY] file:line — fix."` |

Kết quả: 5–6 sessions gọn (<50% context mỗi cái) thay vì 1 session 95% đầy rác 3 ngày. Giống chia marathon thành các chặng tiếp nước: mỗi chặng chạy hết sức, nghỉ 5 phút, lại chạy tiếp.

> **Cách đọc bảng này:** đọc theo cột "Ngày" từ trên xuống là đúng trình tự làm; cột "Prompt mở đầu (copy-paste)" dán thẳng vào session mới — mỗi dòng là một session riêng, không gộp chung.

> **Tóm gọn 1 câu:** Việc 3 ngày không phải 1 cự ly marathon mà là 3 chặng tiếp nước — mỗi chặng một session fresh, kế hoạch là cây gậy tiếp nước đã cắm sẵn ở `plan.md`.

---

## 8. Bảng so sánh: chọn công cụ nào?

| Công cụ | Giữ context cũ? | Giữ code? | Tốn tokens? | Dùng khi nào? |
|---|---|---|---|---|
| `/clear` | Không (xóa 100%) | Có (file giữ) | ~0 + đọc lại vài K | Đổi task hoàn toàn |
| `/compact [focus]` | Có (dạng tóm tắt) | Có | 1 lần tóm tắt | Cùng task nhưng >60–70% |
| Rewind (Esc Esc) | Quay về checkpoint | Có thể revert code | Rẻ | Đi sai hướng, muốn quay lại |
| `/fork`, `/branch` | Copy sang nhánh mới | Có | Copy 1 lần | Thử what-if song song |
| `/btw` | Không ghi vào history | Có | 1 turn, no tools | Hỏi phụ nhanh |
| Subagent | Main chỉ nhận summary | Tùy (read-only được) | Overhead ~20K/con | Explore ồn, review fresh |

> **Cách đọc bảng này:** cột "Giữ context cũ?" và "Tốn tokens?" giúp bạn lọc nhanh cái rẻ/cái đắt; chốt lựa chọn ở cột "Dùng khi nào?" — đối chiếu tình huống của mình với 6 dòng là chọn được ngay.

> Quy tắc ngón tay: **cùng task đầy RAM → `/compact`; khác task RAM bẩn → `/clear`; sai hướng → rewind; thử 2 hướng → `/fork`; hỏi phụ → `/btw`; explore ồn → subagent.**

> **Tóm gọn 1 câu:** Sáu công cụ = sáu loại xe trong gara — chọn theo chuyến đi (tình huống) chứ không phải theo xe đẹp nhất.

---

## 9. Checklist context sạch mỗi ngày

Mục này gom mọi thói quen trên thành checklist theo nhịp ngày–tuần: sáng dọn, giữa task kiểm, cuối ngày chốt.

- [ ] Sáng: `/context` còn rác hôm qua → `/clear`; mở đúng branch + spec.
- [ ] Giữa task (mỗi 30–45p): chạm 70% → `/compact` có focus hoặc `/clear` + `plan.md`; quyết định quan trọng ghi file ngay; hỏi phụ → `/btw`, explore rộng → subagent.
- [ ] Cuối task/ngày: `/export` nếu transcript giá trị; ghi todos ra file; `/clear` để mai sạch.
- [ ] Tuần/tháng: prune MCP (`/mcp`, `/usage`); `CLAUDE.md` <200 dòng; `/doctor` + `/skill-doctor`; xóa subagents 1 tháng không gọi.

> **Tóm gọn 1 câu:** Nhịp dọn context giống dọn nhà: sáng dọn bàn, giữa ngày bắt tay dọn ngay khi thấy rác, tối cất hết đồ — chứ đừng đợi cuối tháng mới đại tu.

---

## 10. Pitfalls + hiểu nhầm thường gặp

| Pitfall / Hiểu nhầm | Fix / Sự thật |
|---|---|
| Nuôi 1 conversation 200 turns cho 5 việc | 1 việc 1 session, `/clear` giữa việc — rẻ hơn ~95% |
| `investigate auth` không scope → đọc 300 files | Khoanh module + output format, hoặc subagent phạm vi hẹp |
| Reviewer tự review bài mình → "LGTM" mù | Luôn reviewer fresh, chưa thấy reasoning của writer |
| Compact không focus → mất decisions | Compact tay với focus; decisions đã lưu file trước |
| CLAUDE.md 600 dòng rules | <200 dòng + `@import` + skills; front-load rule hay sai nhất |
| Tin "should work" | Đòi log/diff/test xanh (xem [Tips 04](./04-verification-done-that.md)) |

> **Cách đọc bảng này:** cột trái là "bệnh", cột phải là "thuốc" — tra theo cột trái khi gặp sự cố, còn khi review thói quen bản thân thì đọc hết cả bảng.

> **Tóm gọn 1 câu:** Sáu cạm bẫy này đều sinh ra từ một thói quen: tối ưu cho "tiện lúc đó" — còn cái rẻ lúc đó thường là cái đắt về sau.

---

## 11. Bài tập cuối bài

1. **Đo hiện trạng (15p):** chạy `/context` + `/usage` + `/doctor`; ghi % đầy, top 2 kẻ ngốn, 1 MCP/skill tắt được ngay; rút `CLAUDE.md` xuống <200 dòng.
2. **Tách session bẩn (30p):** 1 conversation >50 turns → tách thành research → plan → implement. So `/cost` + số retry trước/sau.
3. **Subagent vs main (20p):** cùng 1 task explore: (a) hỏi main, (b) via subagent. Đo tokens main nhận, số files đọc, summary có đủ plan không?

---

## 12. Tham khảo chéo

- Lệnh: [clear](../01-huong-dan-su-dung/commands/session-context/clear/README.md) · [compact](../01-huong-dan-su-dung/commands/session-context/compact/README.md) · [context](../01-huong-dan-su-dung/commands/session-context/context/README.md) · [usage](../01-huong-dan-su-dung/commands/session-context/usage/README.md) · [doctor](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) · [rewind](../01-huong-dan-su-dung/commands/session-context/rewind/README.md) · [btw](../01-huong-dan-su-dung/commands/code-repo/btw/README.md) · [mcp](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md)
- Bài tips: [Tips 02](./02-prompt-engineering.md) (prompt gọn) · [Tips 03](./03-plan-first-workflow.md) (plan-first) · [Tips 05](./05-parallel-agents.md) (fan-out subagents) · [Tips 08](./08-tiet-kiem-cost-token.md) (route model + tiết kiệm)
