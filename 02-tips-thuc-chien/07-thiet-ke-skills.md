# Tips 07 — Thiết kế skills đáng tiền: chuẩn SOP, không phải ghi chép

> **Bài này cho ai:** dev đã viết skill cho Claude Code nhưng kết quả hay là "ghi chép không ai gọi", hoặc tech lead muốn chuẩn hóa skill cho team.
> **Cần gì trước:** đã cài và đăng nhập Claude Code ([bài 01](../01-huong-dan-su-dung/01-cai-dat-va-xac-thuc.md)); nên đọc [bài 05 — Skills](../01-huong-dan-su-dung/05-skills-custom-commands.md) trước vì bài đó nói skill sống ở đâu, còn bài này nói viết skill nào đáng tiền.
> **Đọc xong bạn làm được:**
> - Đặt tên + viết description đúng cách — 2 thứ quyết định 50% skill có được Claude gọi hay không.
> - Tự viết SKILL.md theo khung chuẩn team, chép được 3 skills mẫu (`/plan`, `/deploy`, `/issues`) và bộ 5 skills mọi team nên có.
> - Nhận diện skill hỏng dần (skill-rot) và dọn định kỳ bằng `/usage`, `/doctor`, `/skill-doctor`.
> **Thời gian:** ~40 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Skill | Quy trình chuẩn (SOP) viết cho Claude: mở ra 30 giây là biết khi nào dùng, làm bước nào, check gì | `.claude/skills/deploy/SKILL.md` |
| SKILL.md | File khai báo 1 skill: khối `---` config ở đầu + phần thân hướng dẫn (frontmatter: `name`, `description`, `tools`) | `skills/deploy/SKILL.md` |
| Description | 1–2 câu mô tả — thứ quyết định Claude có tự gọi skill hay không | `Dùng khi user nói deploy/release/ship.` |
| Trigger (từ kích hoạt) | Từ khóa trong description khiến Claude khớp ngữ cảnh rồi gọi skill | `deploy`, `ship`, `plan` |
| references / scripts | File phụ skill chỉ đọc khi cần / script chạy thay việc máy làm tốt hơn | `references/migrate-checklist.md`, `scripts/migrate-dry-run.sh` |
| `disable-model-invocation` | Cờ frontmatter: `true` = chỉ gọi tay, Claude không tự fire | deploy/ship/release |
| Skill-rot | Skill hỏng dần: không ai gọi hoặc Claude gọi sai lúc | Skill 1 tháng không ai mở |

---

## 1. Vì sao skills? (cơ chế load)

- **Rẻ lúc start, đắt khi cần mới trả:** startup chỉ load tên + description (~100 tokens/skill → 20 skills ≈ 2K); khi user nói "deploy" hoặc Claude thấy khớp use-case mới load body + references/scripts. So với nhét tất cả vào `CLAUDE.md` (trả thuế mọi turn), skills **trả tiền khi dùng** ([Tips 01](./01-context-hygiene.md), [Tips 08](./08-tiet-kiem-cost-token.md)).
- **Agent Skills standard:** cùng file `SKILL.md` chạy được ở nhiều tool (đổi tool không phải viết lại). Cấu trúc: `SKILL.md` + `references/*.md` + `scripts/*.sh` + `examples/`.
- **Hot-reload:** sửa SKILL.md trên đĩa, session đang mở nhận bản mới trong vài giây (từ 2.1.0) — không cần restart; tạo thư mục skill mới thì restart 1 lần.
- **Khi nào skill là đáp án đúng:** quy trình lặp lại ≥3 lần/tháng, cần người phán đoán (deploy, review, ship, tạo issue); phân phối team bằng plugin ([Tips 09](./09-teamwork-chuan-hoa.md)). Không phải đáp án khi: rule máy check được 100% → hook ([Tips 06](./06-hooks-recipes.md)); việc 1 lần → prompt ([Tips 02](./02-prompt-engineering.md)).

---

## 2. Quy tắc 30 giây: SOP 4 mảnh

Skill tốt = SOP mà người mới (hoặc Claude fresh) đọc 30 giây là làm theo được:

1. **Khi nào dùng** (trigger): "Dùng khi user nói deploy/release/ship. Không dùng cho ...".
2. **Steps nào** (đánh số, mỗi step có lệnh + check): Preconditions → Migrate dry-run → Deploy → Smoke → Rollback nếu fail.
3. **Check gì** (constraints): NEVER... / ALWAYS... (vd NEVER deploy khi test đỏ, ALWAYS dry-run migrate).
4. **Output mẫu nào** (copy từ `examples/output.md`): checklist đã tick, changelog, PR link.

Thiếu 1 trong 4 → skill yếu: hoặc không ai gọi (thiếu 1), hoặc gọi xong vẫn sai (thiếu 2/3), hoặc output mỗi lần 1 kiểu (thiếu 4).

---

## 3. Đặt tên + description (50% skill có được dùng)

### 3.1. Đặt tên: động từ + đối tượng

- Tên tốt: `deploy`, `add-table`, `review-pr`. Thư mục = command (`/deploy` gọi skill `deploy`).
- Tên tệ: `helper`, `utils`, `my-skill-v2`, `stuff` (không ai biết khi nào gọi, Claude cũng không trigger được).

### 3.2. Description: câu đầu = use case chính

```markdown
---
name: deploy
description: Deploy staging/prod với checklist migrate, smoke, rollback. Dùng khi user nói deploy/release/ship. Không dùng cho local dev.
---
```

```text
TỆ: "Skill hỗ trợ nhiều việc liên quan tới dự án, có thể dùng khi cần." → không trigger từ nào, không bao giờ được gọi.
TỐT: "Sinh implementation plan chuẩn (deps, steps, verify). Dùng khi user nói plan/lên kế hoạch. Không dùng cho bug 1 dòng." → 3 trigger + 1 loại trừ.
```

- **Listing (VD: gõ `/` để xem danh sách skill) truncate ~1.536 ký tự** (docs xác nhận: description + when_to_use) — dồn quan trọng lên đầu, câu 1 = use case + từ trigger.
- Mặc định để Claude tự trigger. Chỉ thêm `disable-model-invocation: true` khi muốn gọi tay (deploy/ship/release — việc nguy hiểm).

### 3.3. Frontmatter đủ dùng (copy-paste)

```markdown
---
name: review-pr
description: Multi-layer review (correctness, security, arch drift, edge, tests). Dùng khi user nói review PR/check diff/duyệt code.
tools: Read, Bash, Grep, Glob
---
```

- `tools`: khai báo hẹp (reviewer không cần `Write`, planner không cần đụng source) — xem [Tips 05](./05-parallel-agents.md).

---

## 4. Cấu trúc SKILL.md chuẩn team (copy-paste)

````markdown
# <Tên> — 1 dòng mục đích, nhận $ARGUMENTS gì

> Dùng $ARGUMENTS thế nào: `/deploy staging` → $ARGUMENTS = "staging".

## Khi nào dùng / không dùng
- Dùng khi: ...
- Không dùng khi: ... (gọi skill X thay thế)

## Steps (numbered, mỗi step có lệnh + check)
1. Preconditions: `...` — check: ...
2. Thực hiện: `...` — check: ...
3. Verify: `...` — evidence: ...

## Constraints (NEVER... / ALWAYS...)
- NEVER ...
- ALWAYS ...

## Output mẫu (copy từ examples/output.md)
<dán 1 output đã duyệt, để Claude bắt chước format>

## Tham khảo (references/*.md, scripts/*.sh với ${CLAUDE_SKILL_DIR})
- Chi tiết: `references/<ten>.md` (chỉ đọc khi cần)
- Script: `${CLAUDE_SKILL_DIR}/scripts/<ten>.sh` (máy làm tốt hơn)
- Data tươi: `` !`git branch --show-current` ``
````

Kèm trong thư mục skill: `SKILL.md` + `references/` + `scripts/` + `examples/output.md` (1 example input/output thật đã duyệt — không bịa; 1 script cho bước máy làm tốt hơn, `chmod +x`).

---

## 5. Ba skills mẫu đầy đủ

### Ví dụ 1 — `/plan` (sinh plan chuẩn)

````markdown
---
name: plan
description: Sinh implementation plan chuẩn (deps, steps, verify). Dùng khi user nói plan/lên kế hoạch/chuẩn bị feature. Không dùng cho fix 1 dòng.
tools: Read, Grep, Glob, Write
---

# Plan — sinh plan cho $ARGUMENTS, chờ duyệt mới implement

## Khi nào dùng / không dùng
- Dùng: feature/refactor >1 file hoặc >2 steps. Không dùng: typo, đổi text (làm luôn).

## Steps
1. Đọc files user chỉ định + `docs/architecture.md` — check: liệt kê đường dẫn đã đọc.
2. Sinh plan theo khung: files sửa | steps | risks | KHÔNG đụng | verify từng phase + gate.
3. Lưu `plan.md`, hỏi duyệt. Không code trong skill này.

## Constraints
- NEVER code khi chưa duyệt. NEVER plan 15 steps không gate (chia ≤4 phases).
- ALWAYS có verify lệnh + diff scope mỗi phase.

## Output mẫu
# Plan: refund payments
| File | Việc |
|---|---|
| `src/payments/service.ts` | refund() idempotent |
Phase 1 — ... — verify: `pnpm --filter payments test` xanh mới sang Phase 2
````

### Ví dụ 2 — `/deploy` (checklist + rollback, gọi tay)

```markdown
---
name: deploy
description: Deploy staging/prod với checklist migrate, smoke, rollback. Dùng khi user nói deploy/release/ship. Không dùng cho local dev.
disable-model-invocation: true
tools: Read, Bash
---

# Deploy $ARGUMENTS (staging|prod) — gọi tay, chờ bạn duyệt từng bước

## Steps
1. Preconditions: `git status` sạch + test xanh `${CLAUDE_SKILL_DIR}/scripts/preflight.sh $ARGUMENTS`.
2. Migrate dry-run: `${CLAUDE_SKILL_DIR}/scripts/migrate-dry-run.sh $ARGUMENTS` — check "DRY-RUN OK".
3. Deploy: `...` — check: version mới hiện trong `/health`.
4. Smoke: `${CLAUDE_SKILL_DIR}/scripts/smoke.sh $ARGUMENTS` — 5 checks phải pass.
5. Fail bước nào → rollback plan trong `references/rollback.md`, không cố tiến.

## Constraints
- NEVER deploy prod khi staging chưa pass. NEVER `disable-model-invocation: false` cho skill này.
- ALWAYS dry-run migrate + smoke có evidence. Output mẫu: `examples/output.md`.
```

### Ví dụ 3 — `/issues` (biến ý thô thành ticket chuẩn, tóm tắt)

Steps: hỏi thiếu (repro? scope? acceptance?) → sinh ticket `Tiêu đề | Repro | Scope | Acceptance | Risks` → lưu `issues/<slug>.md`, hỏi duyệt trước khi post. Constraints: NEVER post tracker khi chưa duyệt; ALWAYS acceptance check được bằng lệnh/số. Frontmatter: `tools: Read, Write`.

**Kiểm tra nhanh:** tạo đủ 3 thư mục skill, gõ `/` trong session → tìm `/plan`, `/deploy`, `/issues`. Không thấy → kiểm tra tên thư mục (thư mục = command) + frontmatter `name`/`description`.

---

## 6. Bộ 5 skills mọi team nên có

| Skill | Nội dung | Gọi khi nào |
|---|---|---|
| `/plan` | Sinh implementation plan chuẩn (deps, steps, verify) | Trước mọi feature đủ lớn |
| `/review` | Review nhiều lớp: correctness, security, arch drift, edge, tests | Mọi PR quan trọng |
| `/deploy` | Checklist: preconditions → migrate dry-run → deploy → smoke → rollback | Ship staging/prod (gọi tay) |
| `/ship` | End-to-end: test → review diff → bump version → changelog → commit → PR | Đóng feature thành PR |
| `/issues` | Biến ý thô thành ticket chuẩn (repro, scope, acceptance) | Log bug, ghi backlog |

Đừng gộp 5 thành 1 "super-skill" (trigger loạn, body phình). Khung `/review`: 1 correctness → 2 security → 3 arch drift → 4 edge → 5 tests; trả `[SEVERITY] file:line — mô tả — fix` + verdict PASS/NEEDS-FIX.

---

## 7. So sánh: skill vs hook vs subagent vs CLAUDE.md

| Cơ chế | Trigger | Tốn tokens | Dùng khi nào |
|---|---|---|---|
| `CLAUDE.md` | Mọi turn | Mọi turn (đắt nếu dài) | Luật chung <200 dòng, lệnh hay dùng |
| Skill | User nói / Claude thấy khớp | ~100 lúc start, body khi gọi | Quy trình cần người quyết, lặp lại |
| Hook | Event (Pre/Post/Stop/Start) | 0 (chạy ngoài model) | Rule máy check được, phải đúng 100% |
| Subagent | Main spawn | ~20K overhead/con | Việc hẹp độc lập, cần fresh context |

> Viết sai chỗ là tốn: quy trình trong `CLAUDE.md` (thuế mọi turn), việc cần người quyết đặt vào hook (máy không quyết được), skill cho việc 1 lần (setup đắt hơn lợi).

---

## 8. Chống skill hỏng dần (skill-rot)

Skill-rot = skills đống thành rác: không ai gọi, gọi sai lúc, description lỗi thời.

1. **Skill 1 tháng không ai gọi → xóa hoặc merge.** Check bằng `/usage` (breakdown per-skill, w21/2026) và `/skill-doctor` (w36/2026 — xem chi phí context + usage từng skill); `/doctor` (alias `/checkup`) báo skill cấu hình lỗi.
2. **Skill load sai lúc → hẹp description/`when_to_use`:** thêm loại trừ ("Không dùng cho ..."), bớt từ trigger chung chung.
3. **Review định kỳ hàng tháng:** cả team lướt list skills — giữ/gộp/xóa. Ghi version Claude đã test (tools schema đổi theo version).
4. **Test đổi tool:** cùng file chạy được tool khác → tránh syntax Claude-only; script dùng `${CLAUDE_SKILL_DIR}` / relative path, không hardcode.

---

## 9. Checklist + pitfalls

**Checklist skill mới:** 30 giây đọc xong biết khi nào/steps/check/output? Tên động từ + đối tượng? Description câu đầu = use case + trigger + loại trừ? Steps có lệnh + check? Constraints NEVER/ALWAYS? Example thật + script `${CLAUDE_SKILL_DIR}`? `tools:` hẹp + `disable-model-invocation` đúng (nguy hiểm → true)? Test 3 ca: fire đúng / đồng nghĩa / KHÔNG fire khi loại trừ?

| Pitfall | Fix |
|---|---|
| Skill như ghi chép (văn xuôi dài, không steps) | Viết lại 4 mảnh (mục 2) + steps có lệnh+check |
| Description chung chung | Câu đầu use case + từ trigger + loại trừ (mục 3) |
| Body phình (200 dòng trong SKILL.md) | Tách references/scripts, SKILL.md giữ khung + link |
| Super-skill 5 trong 1 | Tách 5 skills (mục 6), mỗi cái 1 việc |
| Skill nguy hiểm auto-fire | `disable-model-invocation: true` (deploy/ship) |
| Script hardcode path | `${CLAUDE_SKILL_DIR}` + relative |

---

## 10. Bài tập

- **Bài 1 (15 phút):** chạy `/usage` + `/skill-doctor`, liệt kê skills 1 tháng chưa gọi; lấy 1 skill hay fire sai, viết lại description theo mục 3, test 3 ca.
- **Bài 2 (25 phút):** lấy 1 file docs quy trình 50+ dòng, biến thành skill theo khung mục 4 (dùng Ví dụ 2 làm base); nhờ 1 đồng nghiệp chưa biết quy trình dùng thử.
- **Bài 3 (20 phút):** đối chiếu team với bảng mục 6, viết khung skill thiếu nhất; lên kế hoạch plugin phân phối ([Tips 09](./09-teamwork-chuan-hoa.md)).

---

## 11. Tham khảo chéo

- [../01-huong-dan-su-dung/05-skills-custom-commands.md](../01-huong-dan-su-dung/05-skills-custom-commands.md) — quản lý skills · [../01-huong-dan-su-dung/commands/knowledge-system/skill-doctor/README.md](../01-huong-dan-su-dung/commands/knowledge-system/skill-doctor/README.md) — audit skills
- [../01-huong-dan-su-dung/commands/knowledge-system/plugin/README.md](../01-huong-dan-su-dung/commands/knowledge-system/plugin/README.md) — đóng plugin phân phối · [../01-huong-dan-su-dung/commands/session-context/usage/README.md](../01-huong-dan-su-dung/commands/session-context/usage/README.md) — per-skill cost
- [Tips 01](./01-context-hygiene.md) — procedures vào skills, không CLAUDE.md · [Tips 06](./06-hooks-recipes.md) — skill vs hook · [Tips 08](./08-tiet-kiem-cost-token.md) — route model · [Tips 09](./09-teamwork-chuan-hoa.md) — plugin + commit skills team

> Mẹo 1 dòng: _skill tốt là SOP 30 giây: mở ra biết khi nào dùng, làm steps nào, check gì, output trông thế nào._
