# Tips 08 — Tiết kiệm cost & token (dùng Opus khi đáng, Haiku khi đủ)

> **Bài này cho ai:** dev muốn đọc được `/cost` + `/usage`, route model theo việc và cắt bill Claude Code mà không cắt verify; tech lead chuẩn hóa cách tiết kiệm token cho team.
> **Cần gì trước:** đã cài và đăng nhập ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [Tips 01 — Vệ sinh context](./01-context-hygiene.md) trước vì 3 thuế ở mục 1 chính là hóa đơn của context bẩn.
> **Đọc xong bạn làm được:**
> - Đọc đúng `/cost` + `/usage`: biết session tốn bao nhiêu, ai ngốn nhất và tắt gì ngay hôm nay.
> - Route model theo việc (haiku/sonnet/opus) kể cả khi gán model cho subagent trong frontmatter.
> - Áp 10 chiêu tiết kiệm + walkthrough 1 tuần để giảm 30–50% bill mà retry/rewind không tăng.
> - Chỉ ra 4 chỗ ĐỪNG tiết kiệm (verify, bảo mật, migrate, plan) để không cắt nhầm.
> **Thời gian:** ~40 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Token | Đơn vị đo văn bản model đọc và ghi, tính tiền theo triệu token | Session 180K input + 25K output |
| Cost | Tiền của session hiện tại, xem bằng lệnh `/cost` | `/cost` → session này tốn bao nhiêu đô |
| Input / output token | Input là cái model đọc (context, file, kết quả tool), output là cái model viết | Input gánh lại mọi turn sau |
| Cache (đọc lại) | Token cũ model đọc lại với giá rẻ hơn nhiều lần so với giá input | `CLAUDE.md` nạp lại mỗi turn nhưng trả giá cache |
| `/usage` | Bảng phân bổ token theo skill / subagent / MCP kèm hạn mức còn lại | `/usage` → explorer 45K (25%) |
| Route model | Chọn model đúng việc: rẻ khi đủ, đắt khi đáng | Explore → haiku, review khó → opus |
| `/clear` | Xóa hội thoại, token về gần 0, file trên đĩa giữ nguyên | 1 task 1 session |
| `/compact` | Nén hội thoại, dặn model giữ gì bỏ gì | `/compact Giữ plan + decisions, bỏ log` |
| maxTurns | Trần số turn của 1 goal/loop, hết là tự dừng — chống loop đốt tiền qua đêm | Goal với `maxTurns 30` |
| Effort | Mức suy nghĩ của model: `low` nhanh gọn, `xhigh`/`max` sâu nhưng đắt | `/effort medium` cho việc hằng ngày |

---

## 1. Vì sao cost phình?

### 1.1. Bốn kẻ ngốn nhất (theo thứ tự thường gặp)

1. **CLAUDE.md phình** — trả thuế mọi turn. 600 dòng × 100 turns = 60K tokens chỉ để "nhớ luật".
2. **Subagents spawn bừa** — ~20K tokens overhead mỗi con (ước tính cộng đồng). 5 con/ngày × 20 ngày = 2M tokens/tháng overhead.
3. **Multi-agent ×3–4 thay vì single-thread** — việc 1 người làm được mà giao 4 agents verify chéo.
4. **MCP tools visible quá nhiều** — chọn sai tool → retry 2–3 vòng, mỗi vòng gánh thêm context.

### 1.2. Cơ chế: 3 loại thuế

```text
Bill = (input × giá input) + (output × giá output) + (retry vì sai) + (overhead agents/MCP)
- Thuế input: context bẩn (log 1000 dòng, 40 files) gánh mọi turn sau.
- Thuế retry: prompt ẩu → sai → sửa 5 turns, mỗi turn đắt hơn turn trước (context to dần).
- Thuế overhead: subagent/MCP/plugin dù không dùng vẫn tốn lúc startup.
```

→ Tiết kiệm = đánh cả 3 thuế cùng lúc, không phải chỉ "chọn model rẻ".

### 1.3. Model hiện tại (2026) — làm căn cứ route

| Model | Context | Ghi chú |
|---|---|---|
| Claude Opus 5.5 | 1M | Default hiện hành; giá $4/$20 per MTok; **fast mode $8/$40** — gấp đôi giá thường, đổi ~2.5× tốc độ |
| Claude Sonnet 5.5 | 1M | Default cho Pro/Team Standard/Enterprise seats; $2/$10 per MTok; adaptive thinking on |
| Claude Fable 5.1 | 1M | Mạnh nhất (w36/2026) |
| Claude Haiku 5.5 | 1M | Nhanh, rẻ ($0.10/$0.50 per MTok) — cho explore/tester/fan-out; prompt >100K: $0.50/$2.50 |

- Thế hệ trước (Opus 5, Sonnet 5, Haiku 4.5, Opus 4.8 + fast mode preview) vẫn còn chọn được qua `/model` khi cần.

- Giá input/output/cache từng model tra nguồn chính thức trước khi tính tiền: platform.claude.com/docs (pricing) — giá thay thường xuyên, đừng hardcode số cũ vào script/hook (xem cost-cap ở [Tips 06](./06-hooks-recipes.md)).
- Gói subscription (Pro/Max/Team...) xem claude.com/pricing; hạn mức tính theo phiên 5 giờ cuộn + hạn tuần; hết hạn mức → chờ reset, nâng gói, hoặc bật usage credits (trả theo giá API).

---

## 2. Hiểu tiền đi đâu: /cost + /usage

### 2.1. `/cost`: session hiện tại tốn bao nhiêu

```bash
/cost
# → input/output tokens session này + quy ra đô (theo giá model đang dùng)
```

Đọc gì: so với hôm qua cùng loại task tăng/giảm? Turn nào vọt (thường là turn paste log lớn hoặc fan-out 5 agents)? Session >2x trung bình → xem lại có gộp 3 việc 1 session không ([Tips 01](./01-context-hygiene.md)).

### 2.2. `/usage`: ai đang ngốn token + hạn mức còn bao nhiêu

```bash
/usage
# → phân bổ theo skill / subagent / plugin / từng MCP server + hạn mức
```

```text
- Top 2 ngốn nhất là gì? (thường: 1 subagent explore rộng + 1 MCP server nặng)
- Skill nào tốn mà 1 tháng không gọi? → xóa/disable.
- MCP server nào ngốn >10K mà tuần này không cần? → tắt tạm (/mcp).
- Subagent descriptions tổng bao nhiêu? (>15K → warning, rút gọn — xem Tips 01)
- Hạn mức còn bao nhiêu? (để quyết định có nên /batch overnight hay để mai)
```

### 2.3. Ví dụ đọc `/usage` (minh họa)

```text
Session hôm nay: 180K input, 25K output
- subagent explorer-auth: 45K (25%) — explore không scope, đọc 40 files
- mcp github: 30K (17%) — bật sẵn nhưng tuần này chỉ làm local
- skill heavy-report: 20K (11%) — tự chạy sai 2 lần
→ Hành động: scope explorer hẹp lại, tắt mcp github, disable-model-invocation cho heavy-report.
→ Dự kiến tiết kiệm ~50% ngày mai.
```

---

## 3. Route model theo việc (đừng Opus mọi thứ)

### 3.1. Bảng chọn model theo việc

| Việc | Model | Vì sao |
|---|---|---|
| Research/explore rộng, phân loại, viết lại đơn giản | haiku | Rẻ nhất, nhanh, đủ — sai thì retry rẻ |
| Implement feature, refactor, debug thường | sonnet (mặc định) | Cân bằng chất lượng/giá |
| Kiến trúc khó, security review, bug hiểm production | opus | Đáng tiền — sai ở đây đắt gấp 100 lần |
| Cần opus mà muốn nhanh | fast mode ($10/$50 per MTok, ~2.5× nhanh) | Deadline dí, chấp nhận trả thêm cho tốc độ |

### 3.2. Đổi model + effort trong session

```bash
/model
# → picker: haiku / sonnet / opus / fable

/effort low|medium|high|xhigh|max|auto
# → low: nhanh gọn; xhigh/max: suy nghĩ sâu (đắt); auto: để Claude tự chọn
```

### 3.3. Route model cho subagent (frontmatter)

Trong `.claude/agents/explorer-payments.md`: frontmatter `name: explorer-payments` + `model: haiku`. Trong `.claude/agents/reviewer-security.md`: `model: opus`.

- Explorer/tester → haiku (đọc + chạy, ít cần suy luận sâu). Reviewer/security/kiến trúc → opus. Implement thường → sonnet.

### 3.4. Bảng route nhanh (dán vào CLAUDE.md team)

```markdown
## Route model
- Explore/phân loại/viết lại đơn giản → haiku.
- Implement/refactor/debug thường → sonnet (mặc định).
- Security/kiến trúc/bug đụng tiền → opus + reviewer fresh.
- Đổi: `/model`, effort: `/effort medium` (thường), `high` (khó).
```

---

## 4. Ví dụ copy-paste: route cho 3 repo mẫu

| Repo | `/model` | `/effort` | Cụ thể |
|---|---|---|---|
| Side-project (tiền ít) | sonnet | medium | Default mọi việc; chỉ lên opus khi bug 2 lần chưa ra + đã rewind; explorer/tester → haiku |
| SaaS có khách trả tiền | sonnet | medium | Implement sonnet theo plan.md; reviewer payments/security → opus fresh soi diff; fast mode khi hotfix prod |
| Fintech/auth (sai là mất tiền) | opus | high | Explore haiku subagents (rẻ); plan + implement + review opus; mọi PR qua reviewer opus fresh + `/verify` chạy thật; cost-cap hook bật |

**Kiểm tra nhanh:** chạy 1 trong 3 setup → `/cost` khớp kỳ vọng loại repo đó; `/usage` → subagent explore hiện model haiku, reviewer hiện opus/sonnet đúng frontmatter.

---

## 5. Mười chiêu tiết kiệm cụ thể

1. **CLAUDE.md <200 dòng; quy trình → skills.** Thuế mọi turn → trả khi dùng. Rule hay sai nhất lên đầu, còn lại `@import`.
2. **1 task 1 session `/clear`; đừng nuôi conversation 200 turns.** Rác turn 10 gánh tới turn 200 ([Tips 01](./01-context-hygiene.md)).
3. **Nghiên cứu ồn ào → subagent (main chỉ nhận tóm tắt).** 30K kết quả đọc thô → 1.5K tóm tắt ([Tips 05](./05-parallel-agents.md)).
4. **`/compact` sớm (khi ~70–80%), kèm focus.** Đừng đợi auto-compact 90% tóm tắt mất quyết định.
5. **`disable-model-invocation: true` cho skills nặng chỉ gọi tay.** Deploy/ship/report nặng tự chạy 2 lần/tuần = đốt tiền ([Tips 07](./07-thiet-ke-skills.md)).
6. **MCP ≤6 servers thực dùng; prune hàng tuần.** Server 2 tuần không dùng → tắt. Check `/mcp` + `/usage` theo từng server.
7. **Subagent descriptions ngắn (tổng >15K bị warning).** Chi tiết vào system prompt; xóa agents không gọi 1 tháng.
8. **`/goal` + Stop-gate cho runs dài không giám sát (luôn maxTurns).** Tránh loop vô hạn đốt tiền qua đêm ([Tips 04](./04-verification-done-that.md)).
9. **Cost-cap hook (Stop → ledger → cảnh báo khi quá cap).** Code đầy đủ ở [Tips 06](./06-hooks-recipes.md). Bảo hiểm rẻ nhất, cài sớm.
10. **`/doctor` (alias `/checkup`) hàng tháng:** rà skill/MCP/plugin không dùng + hooks chậm + version mới.

---

## 6. Walkthrough: giảm 50% bill 1 tuần

**Thứ Hai — Đo (15 phút):** chạy `/usage` + `/doctor` + `/cost` — ghi tổng tuần trước, top 3 ngốn, skills unused, hooks chậm.

**Thứ Ba — Cắt 3 nhát nhanh (30 phút):**

```bash
/mcp          # 1. tắt server tuần này không dùng (github → local only)
# 2. khóa skill nặng tự chạy: disable-model-invocation: true (xem Tips 07)
# 3. rút gọn CLAUDE.md 450 → 150 dòng (quy trình → skills)
#    + rút gọn 3 subagent descriptions dài nhất còn 2 câu mỗi cái
```

**Thứ Tư–Sáu — Đổi thói quen (0 cấu hình, chỉ kỷ luật):** mọi explore >3 files → haiku subagent; `/compact` ở 70% (kèm focus), `/clear` giữa task; prompt nào cũng có verify 1 dòng (đỡ retry 5 turns); loop/goal nào cũng có maxTurns.

**Chủ Nhật — Đo lại:** `/usage` so với Thứ Hai; ghi vào `docs/cost-log.md`: tuần này làm gì, tiết kiệm bao nhiêu.

Kết quả điển hình team 3 người: **-40–60% input tokens**, retry giảm một nửa, trả lời nhanh hơn (context gọn).

---

## 7. Bảng so sánh: tốn nhiều vs tốn ít

| Thói quen tốn | Thói quen rẻ | Tiết kiệm |
|---|---|---|
| Opus mọi thứ (kể cả explore) | Haiku explore, Sonnet implement, Opus review khó | 50–70% cho explore |
| 1 session 200 turns 5 việc | 1 task 1 session + `/clear` | ~95% rác |
| Main đọc 40 files trực tiếp | Subagent đọc, main nhận summary | ~90% input explore |
| CLAUDE.md 600 dòng | <200 dòng + skills | Thuế mọi turn giảm 3–4x |
| 12 MCP servers bật sẵn | ≤6 servers, tắt khi không cần | 10–30K mỗi session |
| Loop không giới hạn | maxTurns + Stop 8 blocks | Tránh bill "trên trời" overnight |
| Prompt ẩu → retry 5 turns | Prompt có scope + verify | Mỗi retry tránh được = 1–2x turn |

---

## 8. Khi nào ĐỪNG tiết kiệm

- **Review bảo mật, kiến trúc, debug production → Opus + reviewer fresh.** Tiết kiệm ở đây đắt hơn gấp 100 lần khi sự cố.
- **Verification (`/verify`, test-gate) không bao giờ cắt.** Test-gate 0 tokens LLM, `/verify` là runtime thật — cắt là mù.
- **Migrate/schema/refund (đụng tiền) → full levels L1–L6 ([Tips 04](./04-verification-done-that.md)).** Đắt 1 lần còn hơn đền 100 lần.
- **Onboarding/plan-first ([Tips 03](./03-plan-first-workflow.md)):** 1 turn plan Opus rẻ hơn 10 turns code sai Sonnet.

> Quy tắc: **tiết kiệm ở explore/lặp vặt, chi ở quyết định khó + verify.** Đừng làm ngược.

---

## 9. Checklist + pitfalls

**Hằng ngày:** model mặc định đúng việc hôm nay? Explorer/tester đang haiku? 1 task 1 session? `/compact` ở 70%? Mọi loop/goal có maxTurns? Không paste log 1000 dòng vào main?

**Hằng tuần/tháng:** `/usage` top ngốn là ai, tắt được không? `/doctor`: unused skills/MCP/hooks chậm? CLAUDE.md còn <200 dòng? Cost-cap ledger có vượt cap ngày nào?

| Pitfall | Fix |
|---|---|
| Haiku cho việc cần Opus (kiến trúc/bảo mật) → sai hiểm | Route đúng bảng mục 3; đừng "rẻ" ở chỗ hiểm |
| Opus cho explore rộng → bill vọt | Haiku explore, Opus quyết định |
| Quên maxTurns overnight | Mọi goal/loop đều có giới hạn + reviewer sáng sau |
| Tắt verify để đỡ tốn | Không bao giờ cắt test-gate/`/verify` |
| Prune MCP quá tay → thiếu tool lúc cần | Tắt tạm (disable), không xóa; bật lại 10 giây |
| Nuôi session 200 turns "cho tiện" | `/clear` + plan.md (rẻ hơn nhiều) |

---

## 10. Bài tập

- **Bài 1 (15 phút):** chạy `/cost` + `/usage` + `/doctor`, ghi top 3 ngốn + 1 thứ tắt ngay; đặt `DAILY_CAP_USD` (1.2x trung bình ngày thường) + gắn cost-cap hook ([Tips 06](./06-hooks-recipes.md)).
- **Bài 2 (20 phút):** liệt kê 5 việc hay làm, gán haiku/sonnet/opus theo bảng mục 3; sửa frontmatter 2 subagents; chạy thử 1 explore haiku + 1 review opus, so bill.
- **Bài 3 (30 phút):** áp 3 chiêu rẻ nhất (CLAUDE.md gọn, 1 task 1 session, compact sớm) trong 3 ngày, đo `/cost` trước/sau, ghi `docs/cost-log.md`.

> Sau 2 tuần: bill/ngày giảm 30–50% mà số retry + rewind không tăng → tiết kiệm đúng chỗ; retry/rewind tăng là cắt nhầm chỗ.

---

## 11. Tham khảo chéo

- [../01-huong-dan-su-dung/commands/session-context/cost/README.md](../01-huong-dan-su-dung/commands/session-context/cost/README.md) — session này tốn bao nhiêu · [../01-huong-dan-su-dung/commands/session-context/usage/README.md](../01-huong-dan-su-dung/commands/session-context/usage/README.md) — phân bổ ai ngốn
- [../01-huong-dan-su-dung/commands/model-mode/effort/README.md](../01-huong-dan-su-dung/commands/model-mode/effort/README.md) — low/medium/high/max · [../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md](../01-huong-dan-su-dung/commands/knowledge-system/mcp/README.md) — prune servers
- [Tips 01](./01-context-hygiene.md) — trần context + session sạch · [Tips 05](./05-parallel-agents.md) — overhead subagents · [Tips 06](./06-hooks-recipes.md) — cost-cap code · [Tips 07](./07-thiet-ke-skills.md) — skills gọn + disable auto

> Mẹo 1 dòng: _Haiku khi đủ, Sonnet khi cần, Opus khi đáng — và không bao giờ cắt tiền verify._
