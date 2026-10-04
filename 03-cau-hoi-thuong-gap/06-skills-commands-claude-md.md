# FAQ 06 — Skills, Commands & CLAUDE.md

> Nhóm Tri thức & Mở rộng · 11 câu hỏi deep-dive · Đọc xong phân biệt command/skill/CLAUDE.md, viết skill auto-trigger đúng, giữ CLAUDE.md <200 dòng

Mỗi câu có giải thích + config/lệnh copy-paste + ví dụ + khi nào áp dụng.

---

## Bảng tổng hợp: CLAUDE.md vs rules vs skills vs commands vs hooks

| Nơi | Load khi nào | Tốn bao nhiêu | Chứa gì |
|---|---|---|---|
| CLAUDE.md (<200 dòng) | Mọi turn | Đắt nhất (trả mãi mãi) | Always-on facts: stack, lệnh, cấu trúc, quy ước bất di bất dịch |
| `.claude/rules/` + `paths` | Khi chạm path khớp | Rẻ (chỉ khi cần) | Luật theo thư mục (`api/**`, `web/**`) |
| Skills (auto-trigger) | Khi description khớp task | ~100 tokens idle, body khi gọi | Procedures/reference dài |
| Custom commands (gọi tay `/x`) | Khi bạn gõ | 0 khi không gọi | Tác vụ gọi tay, Mens |
| Hooks | Khi event lửa | 0 model tokens | Luật bắt buộc (model hay miss) |
| `/memory` | Theo user | Nhẹ | Sở thích cá nhân, không phải luật team |

Quy tắc 1 dòng: **facts → CLAUDE.md, path hẹp → rules, procedures → skills, gọi tay → commands, hay miss → hooks.**

---

## 1. Custom command vs skill — nay là một?

**Giải thích.** Đúng: `.claude/commands/x.md` ≡ `.claude/skills/x/SKILL.md` → cùng ra `/x`. File commands cũ vẫn chạy (không vỡ), nhưng viết mới thì viết **skills** vì skills thêm được: frontmatter giàu, support files (scripts/references), **auto-trigger** (model tự gọi khi description khớp, không cần bạn gõ).

```text
.claude/commands/deploy.md       → /deploy (gọi tay, cũ, vẫn chạy)
.claude/skills/deploy/SKILL.md   → /deploy (gọi tay + auto-trigger, mới, nên dùng)
```

**Khi nào áp dụng:** file cũ để yên. Mới → skills. Muốn gộp dần thì move content sang `SKILL.md`, giữ tên → `/x` không đổi, user không cần học lại.

---

## 2. Skill đặt ở đâu? (3 vị trí: personal / project / plugin)

**Giải thích.** 3 vị trí, scope khác nhau:

| Vị trí | Đường dẫn | Ai thấy | Dùng khi nào |
|---|---|---|---|
| Personal | `~/.claude/skills/<tên>/` | Mọi project của bạn | Workflow cá nhân (review style của bạn) |
| Project | `.claude/skills/<tên>/` | Cả team (commit) | Chuẩn team (deploy, migrate, triage) |
| Plugin | `<plugin>/skills/<tên>/` | Ai cài plugin | Phân phối rộng, gọi namespaced `/plugin:skill` |

```bash
ls ~/.claude/skills/
ls .claude/skills/
```

**Ví dụ:** skill `deploy` team dùng chung → project. Skill `my-review-style` chỉ bạn thích → personal. Skill kèm plugin bán cho nhiều team → plugin + namespace.

**Khi nào áp dụng:** viết skill mới → hỏi "ai dùng" trước khi chọn chỗ.

---

## 3. Frontmatter skill gồm gì? (full table)

**Giải thích.** Frontmatter là "mặt tiền" model đọc để quyết định gọi. Full bảng:

| Field | Ý nghĩa | Ví dụ |
|---|---|---|
| `name` | Tên skill (= `/tên`) | `deploy` |
| `description` | Khi nào gọi. **Câu đầu = use case**, truncate ~1536 ký tự | `Deploy staging/prod đúng chuẩn. Dùng khi release, rollback...` |
| `when_to_use` | Bổ sung trigger (1 số bản) | `Khi user nói "lên staging"` |
| `disable-model-invocation` | `true` = chỉ gọi tay, model không tự trigger (từ 2.1.196 cũng chặn scheduled fire) | `true` cho skill nguy hiểm |
| `allowed-tools` | Pre-approve tools trong lượt gọi | `Bash(npm run deploy:*)` |
| `context: fork` | Chạy cô lập trong subagent (không thấy history) | Skill research ồn |
| `agent:` / `model:` (kèm fork) | Ép agent/model khi fork | `model: haiku` cho rẻ |

**Template copy-paste:**

```markdown
---
name: deploy
description: Deploy staging/prod đúng chuẩn team (migrate + smoke + rollback). Dùng khi release, lên staging, rollback prod.
allowed-tools: Bash(npm run deploy:*), Bash(npm run migrate:*), Read
---
# Deploy
1. Chạy migrate trước (`npm run migrate`).
2. Deploy (`npm run deploy <env> $ARGUMENTS`).
3. Smoke test 3 endpoints. Đỏ → rollback ngay, không fix tiếp.
```

**Khi nào áp dụng:** mọi skill mới — điền đủ 3 cái `name/description/allowed-tools` trước, còn lại thêm khi cần.

---

## 4. `$ARGUMENTS`, `!cmd` (dynamic inject), `${VARS} dùng sao?

**Giải thích.** 3 cơ chế đưa input động vào skill:

- **`$ARGUMENTS`:** input khi gọi (`/deploy staging` → `$ARGUMENTS` = `staging`).
- **`` !`cmd` ``:** chạy shell TRƯỚC, thay output thật vào prompt (dynamic inject). VD: nhét `git status` hiện tại vào.
- **`${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}`:** đường dẫn tuyệt đối, dùng trong content + `allowed-tools` (skill đặt đâu cũng chạy).

**Ví dụ copy-paste:**

```markdown
---
name: deploy
description: Deploy đúng chuẩn. Dùng khi release.
---
# Deploy $ARGUMENTS
Env: $ARGUMENTS (VD: staging, prod).
Trạng thái hiện tại: !`git status --short`
Script: ${CLAUDE_SKILL_DIR}/scripts/smoke.sh
```

```bash
/deploy staging
# → $ARGUMENTS=staging, git status thật được nhét vào, smoke.sh chạy đúng path
```

**Khi nào áp dụng:** skill nào cũng nên có `$ARGUMENTS` (linh hoạt) + `` !`cmd` `` cho context tươi (tránh model đoán).

---

## 5. Skill không auto-trigger — debug sao? (description / disable / overrides)

**Giải thích.** 3 nguyên nhân theo thứ tự:

1. **`description`/`when_to_use` không khớp cách bạn diễn đạt:** model match theo ngữ nghĩa. Bạn nói "lên hàng staging" mà description ghi "production release orchestration" → không khớp.
2. **`disable-model-invocation: true`:** bạn (hoặc ai đó) chặn model tự gọi → chỉ gọi tay được.
3. **`skillOverrides` tắt:** settings tắt skill đó → không trigger dù description đẹp.

**Fix copy-paste:**

```markdown
---  # ❌ MỜ: buzzwords, không ai nói thế
description: Orchestrate synergistic deployment workflows leveraging best practices.
---
---  # ✅ RÕ: khớp cách user nói + use case đầu câu
description: Deploy staging/prod và rollback. Dùng khi user nói "deploy", "lên staging", "rollback", "release".
when_to_use: Khi user nhắc deploy/staging/prod/release/rollback.
---
```

```bash
# Check 2 cái còn lại:
git grep -n 'disable-model-invocation' -- .claude/skills/<tên>/
git grep -n 'skillOverrides' -- .claude/settings*.json
```

**Ví dụ:** skill `triage` không bao giờ tự gọi → sửa description từ "Issue management optimization" thành "Lấy ticket Linear/Jira về tóm tắt + tạo branch. Dùng khi bắt đầu task từ ticket" → trigger ngay.

**Khi nào áp dụng:** skill mới viết mà 1 tuần không tự lửa lần nào → debug 3 bước này.

---

## 6. Bundled skills nào đáng dùng? (list + khi nào)

**Giải thích.** Skills đi kèm (bundled), khỏi cài:

| Skill | Việc | Khi nào gọi |
|---|---|---|
| `/doctor` | Khám sức khoẻ repo/setup | Mỗi tháng, repo mới |
| `/code-review` | Review thường | Mọi PR vừa-tầm |
| `/ultrareview` | Review sâu (sandbox) | PR lớn, security-critical |
| `/batch` | Chia change lớn thành 5–30 worktree-subagents | Epic, migrate lớn |
| `/debug` | Chẩn đoán session lạ | Đang làm mà sai sai |
| `/loop` | Lặp task tới khi xanh | Flaky fix, migrate từng phần |
| `/claude-api [migrate\|managed-agents-onboard]` | Migrate/onboard agents | Đổi provider, onboard team |
| `/verify` | Chạy app thật kiểm chứng | Sau khi code xong (thay vì tin model nói) |
| `/simplify` | Rút gọn code | Sau implement, trước review |
| `/insights` | Thói quen team (HTML) | Cuối sprint |

```bash
/doctor
/code-review
/verify
```

**Khi nào áp dụng:** mới onboard → thử `/doctor` + `/verify` trước. PR lớn → `/code-review`, thấy chưa đủ sâu → `/ultrareview`.

---

## 7. CLAUDE.md vs skill — ranh giới ở đâu? (<200 dòng)

**Giải thích.** CLAUDE.md load mọi turn → chỉ giữ always-on facts (<200 dòng). Còn lại:

- Procedures dài, reference, checklist → **skill** (load khi cần).
- Luật chỉ đúng cho 1 thư mục → **`.claude/rules/` + `paths`** (VD: `api/**` dùng ESM, `migrations/**` không sửa tay).
- Luật nhắc 3 lần vẫn miss → **hook** (bắt buộc, 0 tokens).

**Test:** dòng nào trong CLAUDE.md mà 10 turns gần nhất không dùng → chuyển ra skill/rules.

```bash
wc -l CLAUDE.md
/doctor claude-md
```

**Ví dụ:** CLAUDE.md có 80 dòng "quy trình deploy 12 bước" → chuyển sang skill `deploy`, CLAUDE.md giữ 1 dòng "deploy → /deploy". Tiết kiệm ~800 tokens/session.

**Khi nào áp dụng:** mỗi tháng `wc -l` + `/doctor claude-md` 1 lần.

---

## 8. `/init` vs viết tay CLAUDE.md? (có code → init, trống → template)

**Giải thích.**

- **Có sẵn codebase → `/init`:** quét code thật, sinh CLAUDE.md từ thực tế. Thử `CLAUDE_CODE_NEW_INIT=1` cho flow interactive (hỏi từng phần). Xong → **xóa 50%** (nó sinh thừa) + thêm verified commands (lệnh đã chạy thật).
- **Project mới (trống) → template:** copy `templates/CLAUDE.md` rồi sửa (xem FAQ 01 câu 9). Không có gì để init quét.

```bash
# Có code:
/init
# Xong: đọc lại, xóa nửa, chạy thử từng lệnh trong file, giữ cái xanh

# Trống:
cp templates/CLAUDE.md ./CLAUDE.md
```

**Khi nào áp dụng:** repo chưa có CLAUDE.md. Đã có mà phình → không init lại, mà tách (câu 7).

---

## 9. `context: fork` là gì? (skill chạy cô lập, khi nào dùng)

**Giải thích.** Skill `context: fork` chạy trong subagent cô lập — không thấy history main. Agent `Explore`/`Plan` khi fork còn skip CLAUDE.md + git status để gọn. Hợp cho skill research ồn (quét 50 files, chỉ trả tóm tắt). Không hợp cho skill cần history (VD: tiếp tục implement đang dở).

```markdown
---
name: explore-auth
description: Quét auth flow trả tóm tắt. Dùng khi cần hiểu auth mà không muốn loãng context.
context: fork
agent: Explore
model: haiku
---
```

**Khi nào áp dụng:** skill đọc nhiều + trả ít (research, audit, quét) → fork. Skill viết/sửa tiếp mạch đang làm → không fork.

---

## 10. `allowed-tools` trong skill để làm gì? (pre-approve trong lượt gọi)

**Giải thích.** `allowed-tools` pre-approve sẵn tools skill cần → trong lượt gọi skill, model đỡ bị hỏi/deny. Không phải bypass org — deny/managed vẫn thắng.

```markdown
---
name: triage
description: Lấy ticket về tóm tắt + tạo branch.
allowed-tools: Read, Glob, Grep, Bash(git checkout:*), Bash(gh issue:*)
---
```

**Ví dụ:** skill deploy cần `npm run migrate` mà không pre-approve → headless deny (xem FAQ 03 câu 6). Thêm `allowed-tools` đúng → chạy mượt.

**Khi nào áp dụng:** skill nào chạy `-p`/background → điền `allowed-tools` hẹp-đúng, test 1 lần.

---

## 11. `${CLAUDE_SKILL_DIR}` để làm gì? (skill mang theo scripts)

**Giải thích.** Skill có thể mang support files: `scripts/`, `references/`, `templates/`. `${CLAUDE_SKILL_DIR}` trỏ đúng folder skill dù nó đặt ở personal/project/plugin → scripts chạy đúng chỗ.

```text
.claude/skills/deploy/
  SKILL.md
  scripts/smoke.sh
  references/runbook.md
```

```markdown
Smoke: `${CLAUDE_SKILL_DIR}/scripts/smoke.sh $ARGUMENTS`
Chi tiết: xem `${CLAUDE_SKILL_DIR}/references/runbook.md`
```

**Khi nào áp dụng:** skill có script/checklist dùng lại → đóng gói chung, đừng để script lang thang ngoài repo.

---

## Vẫn lỗi thì sao? (skills/commands)

1. Skill không hiện `/x` → check tên folder + `name` + file `SKILL.md` đúng chỗ (câu 2).
2. Không auto-trigger → description → `disable-model-invocation` → `skillOverrides` (câu 5).
3. Headless deny → `allowed-tools` + test `-p` (câu 10).
4. CLAUDE.md phình → `/doctor claude-md` → tách (câu 7).
5. `/debug` → chẩn đoán session; `/bug` nếu nghi core.

```bash
ls .claude/skills/
git grep -n 'disable-model-invocation' -- .claude/skills/
wc -l CLAUDE.md
```

---

## Tham khảo chéo

- Lệnh liên quan:
  - [../01-huong-dan-su-dung/commands/doctor/README.md](../01-huong-dan-su-dung/commands/doctor/README.md) — khám CLAUDE.md phình
  - [../01-huong-dan-su-dung/commands/init/README.md](../01-huong-dan-su-dung/commands/init/README.md) — sinh CLAUDE.md từ code
  - [../01-huong-dan-su-dung/commands/memory/README.md](../01-huong-dan-su-dung/commands/memory/README.md) — tách sở thích cá nhân
  - [../01-huong-dan-su-dung/commands/rules/README.md](../01-huong-dan-su-dung/commands/rules/README.md) — luật theo path
  - [../01-huong-dan-su-dung/commands/verify/README.md](../01-huong-dan-su-dung/commands/verify/README.md) — kiểm chứng sau code
  - [../01-huong-dan-su-dung/commands/debug/README.md](../01-huong-dan-su-dung/commands/debug/README.md) — skill không trigger?
- Bài tổng quan:
  - [../01-huong-dan-su-dung/03-claude-md-memory-rules.md](../01-huong-dan-su-dung/03-claude-md-memory-rules.md) — ranh giới md/memory/rules
  - [../01-huong-dan-su-dung/05-skills-custom-commands.md](../01-huong-dan-su-dung/05-skills-custom-commands.md) — viết skill chuẩn
  - [../02-tips-thuc-chien/07-thiet-ke-skills.md](../02-tips-thuc-chien/07-thiet-ke-skills.md) — thiết kế skill auto-trigger
  - [../02-tips-thuc-chien/01-context-hygiene.md](../02-tips-thuc-chien/01-context-hygiene.md) — giữ context gọn
- FAQ liên quan: [FAQ 02](02-model-context-token.md) (token), [FAQ 05](05-hooks-faq.md) (rule hay miss → hook), [FAQ 07](07-subagents-teams-workflows.md) (fork skill).

> Mẹo 1 dòng: _facts vào CLAUDE.md, procedures vào skills, và description viết bằng chính từ bạn sẽ nói._
