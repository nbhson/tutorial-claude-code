# 05 — Skills và custom commands cho quy trình lặp lại

> **Bài này cho ai:** bạn có việc lặp lại hằng tháng (deploy, review PR, thêm bảng, ship) và muốn gói lại thành 1 lệnh, thay vì dán prompt dài mỗi lần.
> **Cần gì trước:** đã cài và đăng nhập (bài 01); nên đọc [04-slash-commands-toan-tap.md](./04-slash-commands-toan-tap.md) để phân biệt skill với lệnh built-in.
> **Đọc xong bạn làm được:** viết 1 `SKILL.md` từ 0 theo 5 bước; chọn đúng chế độ tự kích hoạt hay chỉ gọi tay; cài 3 mẫu hoàn chỉnh chạy được ngay; dùng 2 kỹ thuật nâng cao (inject data thật, fork); tránh 7 bẫy thường gặp.
> **Thời gian:** ~35 phút

## Thuật ngữ

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| Skill | Công thức nấu ăn cất sẵn trong repo — cần là lấy ra | `.claude/skills/deploy/SKILL.md`, gõ `/deploy staging` |
| `SKILL.md` | File bắt buộc duy nhất: frontmatter + các bước | frontmatter `name`/`description`, rồi `## Steps` |
| Trigger | Claude tự nhận "việc này đúng skill kia" và nạp skill | Bạn nói "deploy" → skill deploy tự nạp |
| File hỗ trợ | Mẫu, script, ví dụ output kèm skill | `templates/migration.sql`, `scripts/smoke.sh` |
| Fork (`context: fork`) | Chạy trong worker riêng, không dính lịch sử chat chính | Skill research chạy nền, trả tóm tắt |
| Bundled skill | Skill đi sẵn với Claude Code | `/code-review`, `/verify`, `/skill-doctor` |

## Mục lục

1. [Skill là gì và vì sao đáng viết](#1-skill-là-gì-và-vì-sao-đáng-viết)
2. [Giải phẫu SKILL.md](#2-giải-phẫu-skillmd)
3. [3 SKILL.md mẫu hoàn chỉnh](#3-3-skillmd-mẫu-hoàn-chỉnh)
4. [Kỹ thuật nâng cao](#4-kỹ-thuật-nâng-cao)
5. [Tạo skill từ 0 (5 bước) + bundled skills](#5-tạo-skill-từ-0-5-bước--bundled-skills)
6. [Hiểu nhầm, bẫy, checklist, bài tập, link](#6-hiểu-nhầm-bẫy-checklist-bài-tập-link)

---

## 1. Skill là gì và vì sao đáng viết

**Nôm na 1 câu:** Skill là *công thức nấu ăn dán trên tủ lạnh* — thay vì mỗi lần nấu gọi điện hỏi mẹ (paste checklist dài), bạn dán sẵn 1 tờ, ai vào bếp cũng nấu đúng vị.

**Ví dụ kỹ thuật copy-paste (khung tối thiểu chạy được):**

```bash
mkdir -p .claude/skills/deploy
cat > .claude/skills/deploy/SKILL.md <<'EOF'
---
name: deploy
description: Deploy staging/prod với checklist migrate + smoke test. Dùng khi user nói deploy/release/ship.
---
# Deploy
Nhận `$ARGUMENTS` (vd `/deploy staging`).
1. `git status --short` phải sạch.
2. Chạy `${CLAUDE_SKILL_DIR}/scripts/migrate.sh --dry-run $ARGUMENTS`
EOF
```

Cơ chế: Claude so ngữ cảnh với `description` (câu đầu là trường hợp dùng chính) → khớp thì nạp phần thân, không khớp thì bỏ qua. Startup chỉ tốn ~100 tokens/skill (tên + description); phần thân chỉ nạp khi được gọi → rẻ.

- Skill = **cách làm đóng gói**: không tự chạy, không kết nối ra ngoài (khác MCP/hook/subagent). Muốn chạy lịch → Routines `/schedule` (bài 12).
- Theo **Agent Skills open standard** (Anthropic 12/2025): ~40 tool hỗ trợ (Codex CLI, Gemini CLI, Copilot...) — viết 1 lần chạy nhiều nơi.
- **Hot-reload từ v2.1.0 (01/2026)**: sửa SKILL.md trong session là có hiệu lực, không cần restart.
- 3 vị trí: `~/.claude/skills/` (personal) · `.claude/skills/` (project, commit) · `<plugin>/skills/` (namespaced `/plugin:skill`).
- Lệnh `.claude/commands/*.md` kiểu cũ vẫn chạy, nên chuyển sang skill để được kích hoạt theo ngữ cảnh.

So với các thứ khác: checklist chỉ cần lúc deploy → skill rẻ hơn CLAUDE.md; hook bắt "phải làm", skill dạy "làm thế nào"; subagent là *người dùng* kiến thức, skill là kiến thức; skill chứa *cách dùng* MCP (schema, format) — cặp bài trùng với MCP.

---

## 2. Giải phẫu SKILL.md

```markdown
---
name: deploy              # plugin skill: segment cuối của /plugin:name; skill thường: command lấy từ tên thư mục
description: Deploy staging/prod với checklist migrate + smoke test. Dùng khi user nói deploy/release/ship.
user-invocable: false     # false = CHỈ Claude tự gọi khi ngữ cảnh khớp (mặc định true)
disable-model-invocation: true   # true = chỉ chạy khi gõ tay /deploy (quy trình muốn kiểm soát)
argument-hint: <staging|prod>    # gợi ý hiện trong menu /skills + autocomplete
arguments: staging prod          # danh sách args hợp lệ
allowed-tools: Bash, Read        # pre-approve tools trong lượt gọi skill (hết lượt thu hồi)
context: fork                     # fork = chạy trong subagent cô lập (không thấy history)
background: false                # false = chờ fork xong trong turn (mặc định fork chạy background từ v2.1.218)
agent: Explore                    # (kèm fork) agent type thực thi
model: sonnet                     # ép model cho skill
paths: ["apps/api/**", "db/migrations/**"]  # chỉ tự kích hoạt khi task chạm các path này
---
# Deploy
Nhận `$ARGUMENTS` (vd `/deploy staging` → `$0` = `staging`).
## Steps
1. `git status --short` phải sạch, nếu không dừng và báo.
2. Migration dry-run: `${CLAUDE_SKILL_DIR}/scripts/migrate.sh --dry-run $ARGUMENTS`
3. Smoke test endpoints trong `references/endpoints.md`.
4. Ghi kết quả theo `examples/output.md`.
```

Biến dùng được: `${CLAUDE_SKILL_DIR}` (folder skill), `${CLAUDE_PROJECT_DIR}` (repo root). Args: `$0`/`$1` positional hoặc `$ARGUMENTS[0]` — **breaking từ v2.1.19** thay `$ARGUMENTS.0` cũ (skill cũ phải sửa + test lại).

Field quan trọng nhất là **`description`**: tổng mô tả mọi skill chiếm ~1% context — giữ mỗi description 1-2 câu mở đầu bằng "Dùng khi...", chi tiết dồn vào phần thân. Ma trận ai được gọi:

|  | `user-invocable: true` (mặc định) | `user-invocable: false` |
|---|---|---|
| `disable-model-invocation: false` (mặc định) | Cả 2 được gọi (tự kích hoạt + gọi tay) | Chỉ Claude gọi (skill nội bộ, user gõ `/ten` không thấy) |
| `disable-model-invocation: true` | Chỉ user gọi tay `/ten` (ship/deploy) | Không ai gọi được (khóa hẳn) |

Settings-level: `skillOverrides` (tắt tự kích hoạt skill của người khác), `disableBundledSkills` (tắt skills đi kèm theo máy).

Cấu trúc folder chuẩn:

```text
.claude/skills/review-pr/
  SKILL.md                  # bắt buộc: frontmatter + steps (<100 dòng, là mục lục)
  references/checklist.md   # NHỚ trỏ từ SKILL.md kẻo không được nạp
  examples/output.md        # output mẫu (Claude bắt chước format)
  scripts/*.sh  templates/*.md
```

---

## 3. 3 SKILL.md mẫu hoàn chỉnh

### 3.1. Mẫu 1 — `review-pr` (tự kích hoạt, dùng Opus)

```markdown
---
name: review-pr
description: Review pull request tìm bug, security, test thiếu. Dùng khi user nói review PR/diff/code, hoặc mở PR mới.
model: opus
allowed-tools: Read, Grep, Glob, Bash
---
# Review PR
Nhận `$ARGUMENTS` (PR number, branch, hoặc trống = diff hiện tại).
## Steps
1. Xác định phạm vi: `$ARGUMENTS` là số → `gh pr diff 123`; là branch → `git diff main...$ARGUMENTS`; trống → `git diff main...HEAD`
2. Đọc từng file đổi (Read, không đoán qua diff 1 dòng).
3. Check theo `references/checklist.md` (bug, security, test, perf, style).
4. Chạy focused tests liên quan; ghi pass/fail vào báo cáo.
5. Xuất báo cáo theo `examples/output.md`. Tối đa 10 findings xếp theo severity.

## Rules
- Chỉ đánh dấu lỗi thực sự, không thổi phồng; mỗi finding: `[SEVERITY] file:line — mô tả — gợi ý fix`.
- Không sửa code trong skill này (chỉ đọc).
```

`references/checklist.md`: Bug (null paths, race, unhandled rejection, migration thiếu rollback) · Security (injection, XSS, authZ, secret hardcode, SSRF) · Test (edge cases, mock ở boundary) · Perf (N+1, đọc file trong loop). `examples/output.md`: mỗi finding 1 dòng + kết quả test + verdict Approve/Request changes.

### 3.2. Mẫu 2 — `add-table` (quy trình migrate DB)

```markdown
---
name: add-table
description: Thêm table/column mới với migration + model + seed. Dùng khi user nói thêm bảng/cột, migrate DB, schema change.
allowed-tools: Read, Write, Edit, Bash
---
# Add Table
## Steps
1. Đọc migration mới nhất (`ls db/migrations/ | tail -5`) học naming.
2. Tạo migration `YYYYMMDD_<mo-ta>.sql` từ `templates/migration.sql`. 1 migration/PR.
3. Viết SQL + rollback note trong header comment.
4. Update model (Prisma/Drizzle/SQLAlchemy — xem `references/orm.md`) + seed nếu cần.
5. Chạy migration local → focused test → ghi theo `examples/output.md`.

## Rules
- NEVER sửa migration đã merge; ALWAYS migration local pass trước khi báo xong.

## Dynamic context
- Branch hiện tại: !`git branch --show-current`
- Migrations gần nhất: !`ls -t db/migrations/ | head -5`
```

### 3.3. Mẫu 3 — `ship` (chỉ gọi tay, nhiều gate)

```markdown
---
name: ship
description: Ship code an toàn: merge base, test, review diff, bump version, changelog, commit, push, PR.
disable-model-invocation: true
allowed-tools: Read, Bash
---
# Ship (chỉ chạy khi gõ tay /ship — không tự kích hoạt)
## Gates (dừng ngay khi gate fail, không cố đi tiếp)
1. Clean tree: `git status --short` trống.
2. Sync base: `git fetch origin && git rebase origin/main` — conflict → dừng.
3. Test: focused test từ CLAUDE.md — fail → in failures.
4. Review: self-review `git diff main...HEAD` theo `references/ship-checklist.md`.
5. Version: bump + CHANGELOG entry (template `templates/changelog.md`).
6. Commit + push + `gh pr create --fill`. KHÔNG merge.
```

---

## 4. Kỹ thuật nâng cao

### 4.1. Chèn kết quả lệnh thật vào prompt

Dòng `` !`command` `` — Claude chạy shell trước, thay output thật vào prompt:

```markdown
Branch hiện tại: !`git branch --show-current`
Diff stat: !`git diff --stat main...HEAD`
```

Dùng khi thông tin đổi mỗi lần gọi (branch, diff, migrations). Không dùng khi command chậm (>2s) hoặc chứa secrets (output inject vào context, log được).

### 4.2. Fork skill (`context: fork`)

Từ v2.1.218 fork skill chạy **background mặc định** (không block turn). Muốn chờ kết quả trong turn: `background: false`. Kill/check: `/tasks` + `Ctrl+X Ctrl+K ×2`.

```markdown
---
name: deep-research
description: Nghiên cứu codebase rộng, trả tóm tắt. Dùng khi user nói research/tìm hiểu module X.
context: fork
agent: Explore
model: sonnet
---
# Skill chạy trong worker riêng (không thấy lịch sử luồng chính).
# Agent Explore/Plan bỏ qua CLAUDE.md + git status để giữ context nhỏ.
```

| Khi nào fork? | Khi nào KHÔNG? |
|---|---|
| Research ồn (đọc 50 files, trả 10 dòng) | Task cần full history (sửa tiếp việc đang làm) |
| Cô lập thất bại (research sai không làm bẩn main) | Task 1-2 bước (chi phí fork không đáng) |

### 4.3. Quyền, tìm skill trong monorepo, ngân sách mô tả

- `allowed-tools` chỉ nới trong lượt gọi; baseline vẫn theo permission settings (bài 10). Muốn chặn thật → hook + deny rules.
- Plugin skill có `hooks` frontmatter **bị bỏ qua**; plugin subagents không hỗ trợ `hooks`/`mcpServers`/`permissionMode` (copy ra `.claude/agents/` nếu cần).
- Tìm skill lồng trong monorepo: `.claude/skills/` ở repo root + các thư mục cha tới repo root đều được quét; nằm sâu chỉ nạp khi task chạm `paths`.
- Script máy làm tốt hơn người (smoke test, migrate dry-run) đặt trong `scripts/` + trỏ từ SKILL.md.

---

## 5. Tạo skill từ 0 (5 bước) + bundled skills

**5 bước ~40 phút:**

1. **Đặt tên + description (5'):** tên = động từ + đối tượng (`deploy`, `review-pr`); description mở đầu bằng "Dùng khi...".

```bash
mkdir -p .claude/skills/my-skill
cat > .claude/skills/my-skill/SKILL.md <<'EOF'
---
name: my-skill
description: Làm X cho Y. Dùng khi user nói <từ khóa 1>, <từ khóa 2>.
---
# My Skill
EOF
```

2. **Viết steps checklist (10'):** mỗi step có lệnh/check cụ thể + output mẫu. Dùng 3 mẫu mục 3 làm khung.
3. **Chọn tự kích hoạt hay chỉ gọi tay (2'):** mặc định tự kích hoạt; chỉ thêm `disable-model-invocation: true` cho deploy/ship.
4. **Thêm example + script (10'):** 1 example input/output + 1 script nếu có bước máy làm tốt hơn.
5. **Test 3 lần (10'):** `/ten-skill` với 3 inputs khác nhau; chỗ nào Claude hỏi 2 lần giống nhau → viết vào SKILL.md.

Mẫu team hay viết: `/issues` (biến ý tưởng thành issue chuẩn), `/plan`, `/review`, `/ship`. Mẫu copy-paste: `templates/.claude/skills/deploy/SKILL.md` trong repo này.

**Bundled skills dùng ngay, khỏi viết:** `/doctor`, `/code-review` + `/ultrareview`, `/batch`, `/debug`, `/loop`, `/verify`, `/simplify`, `/insights`, `/claude-api [migrate|managed-agents-onboard]`. Xem/gọi bằng menu `/skills`; tắt cái ế bằng `disableBundledSkills` (settings) hoặc dọn bằng `/skill-doctor` (≥2.1.252).

---

## 6. Hiểu nhầm, bẫy, checklist, bài tập, link

### Hiểu nhầm thường gặp

| Hiểu nhầm | Sự thật |
|---|---|
| "Skill tự chạy như cron" | Skill bị động — gọi tay hoặc tự kích hoạt khi ngữ cảnh khớp. Muốn lịch → `/schedule` (bài 12) |
| "Nhét hết 300 dòng vào SKILL.md cho chắc" | SKILL.md là mục lục <100 dòng; checklist/template/script ra file riêng + trỏ từ SKILL.md |
| "`allowed-tools: Bash` cho phép mọi lệnh" | Chỉ nới trong lượt gọi, baseline vẫn theo settings. Chặn thật → hook + deny rules |
| "Skill thay MCP/hook được" | Skill dạy *cách làm*, MCP cho *tay vươn ra*, hook là *luật*. Thiếu hook là rule vẫn bị quên |
| "Description viết dài cho chi tiết" | Tổng mô tả ~1% context — 1-2 câu "Dùng khi...", chi tiết vào phần thân |

### Bẫy thường gặp + fix

| Bẫy | Fix |
|---|---|
| Description mơ hồ → skill không bao giờ kích hoạt | Mở đầu "Dùng khi user nói X, Y, Z" + từ khóa thật |
| Quên trỏ file hỗ trợ → Claude không nạp | Mọi file kèm phải được nhắc tên trong SKILL.md |
| `disable-model-invocation: true` cho skill nên tự kích hoạt | Chỉ gọi tay cho deploy/ship; còn lại tự kích hoạt |
| `allowed-tools` quá rộng (`Bash` không giới hạn) | Giới hạn hẹp (`Bash(pnpm test:*)`) |
| Test 1 lần rồi chia sẻ | Test 3 inputs khác nhau trước khi commit |
| Nhét secrets vào skill | Secrets qua env (bài 08), không vào SKILL.md |
| Skill cũ dùng `$ARGUMENTS.0` | Sửa thành `$0`/`$ARGUMENTS[0]` (v2.1.19+) |

### Checklist skill khỏe

- [ ] Tên = động từ + đối tượng; description mở đầu bằng khi nào dùng (1-2 câu).
- [ ] Steps <100 dòng; có 1 example output; file hỗ trợ được trỏ từ SKILL.md.
- [ ] Test 3 lần với inputs khác nhau; `disable-model-invocation` đúng ý; không secrets.
- [ ] Skill "ế" → dọn bằng `/skill-doctor` (≥2.1.252).

### Bài tập

1. (20') Cài mẫu `review-pr`, chạy trên diff thật; so với review tay — bổ sung checklist.
2. (20') Viết skill `add-table` cho ORM team; test thêm 1 column thật lên DB dev + rollback note.
3. (20') Viết skill `ship` chỉ gọi tay; chạy `/ship` lên branch test — gate nào fail đầu tiên, có dừng đúng không?
4. (15', nâng cao) Thêm `` !`git branch --show-current` `` vào 1 skill có sẵn; thêm `context: fork` vào 1 skill research, so sánh context luồng chính trước/sau.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: skill vs CLAUDE.md/hook/subagent/MCP; **[03 — CLAUDE.md](./03-claude-md-memory-rules.md)**: tách checklist khỏi CLAUDE.md, AGENTS.md chéo tool.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: custom commands đã gộp vào skills; **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: fork skill, subagent nạp sẵn skill.
- **[07 — Hooks](./07-hooks-tu-dong-hoa.md)**: skill = lời khuyên, hook = luật; **[08 — MCP](./08-mcp-ket-noi-cong-cu-ngoai.md)**: cặp skill+MCP; **[09 — Plugins](./09-plugins-marketplaces.md)**: đóng gói skills share team; **[10 — Permissions](./10-permissions-modes-availability.md)**: `allowed-tools` vs baseline; **[12 — SDK/CI](./12-agent-sdk-ci-cd-automation.md)**: routines + skill cho jobs định kỳ.
