# Tips 08 — Tiết Kiệm Cost & Token (Dùng Opus Khi Đáng, Haiku Khi Đủ)

> Tiền đi đâu? Đọc `/cost` + `/usage` là biết. Bài này: đọc gì trong 2 lệnh đó, route model theo việc (Haiku/Sonnet/Opus), 10 chiêu tiết kiệm cụ thể, và khi nào ĐỪNG tiết kiệm.

## Mục lục

- [1. Vì sao cost phình?](#1-vì-sao-cost-phình)
- [2. Hiểu tiền đi đâu: /cost + /usage đọc gì](#2-hiểu-tiền-đi-đâu-cost--usage-đọc-gì)
- [3. Route model theo việc (đừng Opus mọi thứ)](#3-route-model-theo-việc-đừng-opus-mọi-thứ)
- [4. Ví dụ copy-paste: route cho 3 repo mẫu](#4-ví-dụ-copy-paste-route-cho-3-repo-mẫu)
- [5. Mười chiêu tiết kiệm cụ thể](#5-mười-chiêu-tiết-kiệm-cụ-thể)
- [6. Walkthrough: giảm 50% bill 1 tuần](#6-walkthrough-giảm-50-bill-1-tuần)
- [7. Bảng so sánh: tốn nhiều vs tốn ít](#7-bảng-so-sánh-tốn-nhiều-vs-tốn-ít)
- [8. Khi nào ĐỪNG tiết kiệm](#8-khi-nào-đừng-tiết-kiệm)
- [9. Checklist + pitfalls](#9-checklist--pitfalls)
- [10. Bài tập](#10-bài-tập)
- [11. Tham khảo chéo](#11-tham-khảo-chéo)

---

## 1. Vì sao cost phình?

### 1.1. Bốn kẻ ngốn nhất (theo thứ tự thường gặp)

1. **CLAUDE.md phình** — trả thuế mọi turn. 600 dòng × 100 turns = 60K tokens chỉ để "nhớ luật".
2. **Subagents spawn bừa** — ~20K overhead/con. 5 con/ngày × 20 ngày = 2M tokens/tháng cho overhead.
3. **Multi-agent ×3–4 thay vì single-thread** — việc 1 người làm được mà giao 4 agents verify chéo.
4. **MCP tools visible quá nhiều** — chọn sai tool → retry 2–3 vòng, mỗi vòng gánh thêm context.

### 1.2. Cơ chế: input tax + retry tax + overhead tax

```text
Bill = (input tokens × giá input) + (output × giá output) + (retry vì sai) + (overhead agents/MCP)

- Input tax: context bẩn (log 1000 dòng, 40 files) gánh mọi turn sau.
- Retry tax: prompt ẩu → sai → sửa 5 turns, mỗi turn đắt hơn turn trước (vì context to dần).
- Overhead tax: subagent/MCP/plugin dù không dùng vẫn tốn lúc startup.
```

→ Tiết kiệm = đánh cả 3 thuế cùng lúc, không phải chỉ "chọn model rẻ".

---

## 2. Hiểu tiền đi đâu: /cost + /usage đọc gì

### 2.1. `/cost`: session hiện tại tốn bao nhiêu

```bash
/cost
# → input/output tokens session này + quy $ (theo pricing model đang dùng)
```

Đọc gì:

- Session này bao nhiêu? So với hôm qua (cùng loại task) tăng/giảm?
- Turn nào vọt? (thường là turn paste log lớn hoặc fan-out 5 agents).
- Nếu 1 session >2x trung bình → xem lại: có gộp 3 việc 1 session không? ([Tips 01](./01-context-hygiene.md)).

### 2.2. `/usage`: breakdown ai ngốn + rate limits

```bash
/usage
# → breakdown skills / subagents / plugins / per-MCP-server + limits
```

Đọc gì (copy checklist):

```text
- Top 2 ngốn nhất là gì? (thường: 1 subagent explore rộng + 1 MCP server nặng)
- Skill nào tốn mà 1 tháng không gọi? → tắt (skillOverrides) hoặc xóa.
- MCP server nào ngốn >10K mà tuần này không cần? → tắt tạm (/mcp).
- Subagent descriptions tổng bao nhiêu? (>15K → warning, rút gọn — xem Tips 01)
- Rate limit còn bao nhiêu? (để quyết định có nên /batch overnight hay để mai)
```

### 2.3. Ví dụ đọc `/usage` (minh họa)

```text
Session hôm nay: 180K input, 25K output
- subagent explorer-auth: 45K (25%) — explore không scope, đọc 40 files
- mcp github: 30K (17%) — bật sẵn nhưng tuần này chỉ làm local
- skill heavy-report: 20K (11%) — auto-fire sai 2 lần
→ Hành động: scope explorer hẹp lại, tắt mcp github, disable-model-invocation cho heavy-report.
→ Dự kiến tiết kiệm ~50% ngày mai.
```

---

## 3. Route model theo việc (đừng Opus mọi thứ)

| Việc | Model | Vì sao |
|---|---|---|
| Research/explore rộng, classify, rewrite đơn giản | Haiku | Rẻ, nhanh, đủ — sai thì retry rẻ |
| Implement feature, refactor, debug thường | Sonnet | Cân bằng chất lượng/giá, default hàng ngày |
| Kiến trúc khó, security review, bug hiểm production | Opus | Đáng tiền — sai ở đây đắt gấp 100 lần |
| Cần Opus mà muốn nhanh (fast mode) | `/fast` + `/extra-usage` (Opus 4.6加速) | Khi deadline dí, chấp nhận trả thêm cho tốc độ |

Đổi giữa session và chỉnh effort:

```bash
/model
# → picker: haiku / sonnet / opus

/effort low|medium|high|xhigh|max|auto
# → low: trả lời nhanh gọn; max: suy nghĩ sâu (đắt); auto: để Claude tự chọn
```

Subagent route riêng (frontmatter agent):

```markdown
---
name: explorer-payments
model: haiku
---
---
name: reviewer-security
model: opus
---
```

- Explorer/tester → haiku (đọc + chạy, ít cần suy luận sâu).
- Reviewer/security/arch → opus (cần judgment, bắt lỗi hiểm).
- Implement thường → sonnet.

### Bảng route nhanh (dán vào CLAUDE.md team)

```markdown
## Route model
- Explore/classify/rewrite đơn giản → haiku.
- Implement/refactor/debug thường → sonnet (default).
- Security/arch/bug tiền → opus + reviewer fresh.
- Đổi: `/model`, effort: `/effort medium` (thường), `high` (khó).
```

---

## 4. Ví dụ copy-paste: route cho 3 repo mẫu

### Ví dụ 1 — Repo side-project (tiền ít, việc vừa)

```bash
/model sonnet
/effort medium
# Default mọi việc. Chỉ lên opus khi: bug 2 lần chưa ra + đã rewind.
# Explorer/tester subagents: model haiku (frontmatter).
```

```text
Prompt mẫu: "Dùng haiku explorer đọc src/utils/*.ts, trả summary 10 bullet. Main (sonnet) quyết định refactor."
```

### Ví dụ 2 — Repo SaaS có khách trả tiền (cân bằng)

```bash
/model sonnet
/effort medium
# Implement: sonnet. Reviewer payments/security: opus.
# /fast khi hotfix production (chấp nhận extra-usage cho tốc độ).
```

```text
"Implement bằng sonnet theo plan.md. Xong spawn reviewer opus fresh soi diff
payments (finding = bug/security/test-gap). Không opus cho explore."
```

### Ví dụ 3 — Repo fintech/auth (sai là mất tiền)

```bash
/model opus
/effort high
# Không tiết kiệm ở: security review, migrate, refund. Tiết kiệm ở: explore (haiku), lint (hook 0 tokens).
```

```text
"Explore bằng haiku subagents (rẻ). Plan + implement + review bằng opus.
Mọi PR qua reviewer opus fresh + /verify chạy thật. Cost-cap hook bật (xem Tips 06)."
```

---

## 5. Mười chiêu tiết kiệm cụ thể

1. **CLAUDE.md <200 dòng; procedures → skills.** Thuế mọi turn → trả khi dùng. Front-load rule hay sai nhất, còn lại `@import`.
2. **1 task 1 session `/clear`; đừng nuôi conversation 200 turns.** Rác turn 10 gánh tới turn 200. Đổi task là đổi session ([Tips 01](./01-context-hygiene.md)).
3. **Research ồn → subagent (main chỉ nhận summary).** 30K raw reads → 1.5K summary. Prompt hẹp + output contract ([Tips 05](./05-parallel-agents.md)).
4. **`/compact` sớm (khi ~70–80%), kèm focus.** Đừng đợi auto-compact 90% tóm tắt mất decisions. Focus giữ plan + decisions, bỏ log.
5. **`disable-model-invocation: true` cho skills nặng chỉ gọi tay.** Deploy/ship/report nặng mà auto-fire 2 lần/tuần = đốt tiền. Gọi tay khi cần ([Tips 07](./07-thiet-ke-skills.md)).
6. **MCP ≤6 servers thực dùng; prune hàng tuần.** Server 2 tuần không dùng → tắt. Check `/mcp` + `/usage` per-server.
7. **Subagent descriptions ngắn (tổng >15K bị warning).** Description 1–2 câu use-case; chi tiết vào body. Xóa agents không gọi 1 tháng.
8. **`/goal` + Stop-gate cho runs dài không giám sát (luôn maxTurns).** Tránh loop vô hạn đốt tiền: goal có maxTurns, Stop tối đa 8 blocks, sáng dậy reviewer check ([Tips 04](./04-verification-done-that.md)).
9. **Cost-cap hook (Stop → ledger → Slack khi quá cap).** Code đầy đủ ở [Tips 06](./06-hooks-recipes.md). Bảo hiểm rẻ nhất, add sớm.
10. **`/doctor` hàng tháng: audit unused skills/MCP/plugins + hooks chậm + version mới.** Xóa cái không dùng, tối ưu hook >5s, update Claude.

---

## 6. Walkthrough: giảm 50% bill 1 tuần

**Thứ Hai — Đo (15 phút):**

```bash
/usage
# → ghi: tổng tuần trước, top 3 ngốn (vd explorer 40%, github-mcp 20%, heavy-skill 15%)
/doctor
# → ghi: 2 skills unused, 1 hook chậm 8s, có version mới
/cost
# → baseline session hôm nay
```

**Thứ Ba — Cắt 3 nhát nhanh (30 phút):**

```bash
# 1. Tắt github-mcp (tuần này local only)
/mcp
# → disable github

# 2. Khóa skill nặng auto-fire
# settings.json: "skillOverrides": {"heavy-report": {"enabled": false}}

# 3. Rút gọn CLAUDE.md 450 → 150 dòng (procedures → skills)
# + rút gọn 3 subagent descriptions dài nhất còn 2 câu mỗi cái
```

**Thứ Tư–Sáu — Đổi thói quen (0 setup, chỉ discipline):**

```text
- Mọi explore >3 files → haiku subagent (không main đọc trực tiếp).
- /compact ở 70% (kèm focus), /clear giữa task (1 task 1 session).
- Prompt nào cũng có verify 1 dòng (đỡ retry 5 turns).
- Loop/goal nào cũng có maxTurns.
```

**Chủ Nhật — Đo lại:**

```bash
/usage
# → so với Thứ Hai: tổng giảm? top 3 còn là ai? Có kẻ ngốn mới không?
# Ghi vào file team (vd docs/cost-log.md): tuần này làm gì, tiết kiệm bao nhiêu, giữ gìn gì tuần sau.
```

Kết quả điển hình team 3 người: **-40–60% input tokens**, retry giảm một nửa, tốc độ trả lời nhanh hơn (context gọn).

---

## 7. Bảng so sánh: tốn nhiều vs tốn ít

| Thói quen tốn | Thói quen rẻ | Tiết kiệm |
|---|---|---|
| Opus mọi thứ (kể cả explore) | Haiku explore, Sonnet implement, Opus review khó | 50–70% cho explore |
| 1 session 200 turns 5 việc | 1 task 1 session + `/clear` | ~95% rác (mục 1.2 Tips 01) |
| Main đọc 40 files trực tiếp | Subagent đọc, main nhận summary | ~90% input explore |
| CLAUDE.md 600 dòng | <200 dòng + skills | Thuế mọi turn giảm 3–4x |
| 12 MCP servers bật sẵn | ≤6 servers, tắt khi không cần | 10–30K mỗi session |
| Loop không giới hạn | maxTurns + Stop 8 blocks | Tránh bill "trên trời" overnight |
| Prompt ẩu → retry 5 turns | Prompt có scope + verify (đỡ retry) | Mỗi retry tránh được = 1–2x turn |
| Skill nặng auto-fire | Gọi tay (`disable-model-invocation`) | 10–20K mỗi lần fire oan |

---

## 8. Khi nào ĐỪNG tiết kiệm

- **Review bảo mật, quyết định kiến trúc, debug production → Opus + reviewer fresh.** Tiết kiệm ở đây đắt hơn gấp 100 lần khi sự cố (mất tiền, lộ secret, sập prod).
- **Verification (`/verify`, test-gate) không bao giờ cắt để "đỡ tốn".** Test-gate 0 tokens LLM (chạy CPU), `/verify` là runtime thật — cắt là mù.
- **Migrate/schema/refund (đụng tiền) → full levels L1–L6 ([Tips 04](./04-verification-done-that.md)).** Đắt 1 lần còn hơn đền 100 lần.
- **Onboarding/plan-first ([Tips 03](./03-plan-first-workflow.md)):** 1 turn plan Opus rẻ hơn 10 turns code sai Sonnet.

> Quy tắc: **tiết kiệm ở explore/lặp vặt, chi ở quyết định khó + verify.** Đừng làm ngược.

---

## 9. Checklist + pitfalls

**Checklist hàng ngày:**

- [ ] Default model đúng việc hôm nay (sonnet thường, opus khi khó)?
- [ ] Explorer/tester đang là haiku?
- [ ] 1 task 1 session, `/clear` giữa việc?
- [ ] `/compact` ở 70% (có focus)?
- [ ] Mọi loop/goal có maxTurns?
- [ ] Không paste log 1000 dòng vào main (ghi file + subagent tóm)?

**Checklist hàng tuần/tháng:**

- [ ] `/usage`: top ngốn là ai? Có tắt được không?
- [ ] `/doctor`: unused skills/MCP/hooks chậm?
- [ ] CLAUDE.md còn <200 dòng? Descriptions còn gọn?
- [ ] Cost-cap ledger có vượt cap ngày nào? Vì sao?

**Pitfalls:**

| Pitfall | Fix |
|---|---|
| Haiku cho việc cần Opus (arch/security) → sai hiểm | Route đúng bảng mục 3; đừng "rẻ" ở chỗ hiểm |
| Opus cho explore rộng → bill vọt | Haiku explore, Opus quyết định |
| Quên maxTurns overnight | Mọi goal/loop đều có giới hạn + reviewer sáng sau |
| Tắt verify để đỡ tốn | Không bao giờ cắt test-gate/`/verify` |
| Prune MCP quá tay → thiếu tool lúc cần | Tắt tạm (disable), không xóa hẳn; bật lại 10 giây |
| Skill nặng auto-fire | `disable-model-invocation: true`, gọi tay |
| Nuôi session 200 turns "cho tiện" | `/clear` + plan.md (rẻ hơn nhiều) |

---

## 10. Bài tập

**Bài 1 (15 phút — đọc bill):**

1. Chạy `/cost` + `/usage` + `/doctor` trong repo hay làm nhất.
2. Ghi top 3 ngốn + 1 thứ tắt ngay được (MCP/skill/agent).
3. Đặt `DAILY_CAP_USD` cho mình (bằng 1.2x trung bình ngày thường) + gắn cost-cap hook ([Tips 06](./06-hooks-recipes.md)).

**Bài 2 (20 phút — route lại models):**

1. Liệt kê 5 việc hay làm, gán Haiku/Sonnet/Opus theo bảng mục 3.
2. Sửa frontmatter 2 subagents (explorer/tester → haiku, reviewer → opus/sonnet).
3. Chạy thử 1 explore haiku + 1 review opus, so bill với trước.

**Bài 3 (30 phút — 10 chiêu):**

1. Áp 3 chiêu rẻ nhất (CLAUDE.md gọn, 1 task 1 session, compact sớm) trong 3 ngày.
2. Đo `/cost` trung bình/ngày trước/sau. Ghi vào `docs/cost-log.md`.
3. Chọn thêm 2 chiêu (prune MCP, khóa skill nặng) tuần sau.

> Đạt: sau 2 tuần, bill/ngày giảm 30–50% mà số retry + rewind không tăng (tiết kiệm đúng chỗ).

---

## 11. Tham khảo chéo

- Lệnh cost/model:
  - [../01-huong-dan-su-dung/commands/session-context/cost/README.md](../01-huong-dan-su-dung/commands/session-context/cost/README.md) — session này tốn bao nhiêu
  - [../01-huong-dan-su-dung/commands/session-context/usage/README.md](../01-huong-dan-su-dung/commands/session-context/usage/README.md) — breakdown ai ngốn
  - [../01-huong-dan-su-dung/commands/model-mode/model/README.md](../01-huong-dan-su-dung/commands/model-mode/model/README.md) (nếu có) — đổi model
  - [../01-huong-dan-su-dung/commands/model-mode/effort/README.md](../01-huong-dan-su-dung/commands/model-mode/effort/README.md) (nếu có) — low/medium/high/max
  - [../01-huong-dan-su-dung/commands/model-mode/fast/README.md](../01-huong-dan-su-dung/commands/model-mode/fast/README.md) (nếu có) — fast mode
  - [../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/doctor/README.md) — audit setup
  - [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — prune servers
  - [../01-huong-dan-su-dung/commands/session-context/compact/README.md](../01-huong-dan-su-dung/commands/session-context/compact/README.md) — compact sớm
  - [../01-huong-dan-su-dung/commands/session-context/clear/README.md](../01-huong-dan-su-dung/commands/session-context/clear/README.md) — 1 task 1 session
- Bài tips liên quan:
  - [Tips 01](./01-context-hygiene.md) — trần context + session sạch
  - [Tips 05](./05-parallel-agents.md) — overhead subagents + route model
  - [Tips 06](./06-hooks-recipes.md) — cost-cap code đầy đủ
  - [Tips 07](./07-thiet-ke-skills.md) — skills gọn + disable auto

> Mẹo 1 dòng: _Haiku khi đủ, Sonnet khi cần, Opus khi đáng — và không bao giờ cắt tiền verify._
