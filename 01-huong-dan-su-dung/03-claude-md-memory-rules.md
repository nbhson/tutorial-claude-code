# 03 — CLAUDE.md, memory & rules (file quan trọng nhất)

> **Bài này cho ai:** dev viết `CLAUDE.md` cho repo — file quyết định 50% chất lượng agent; người mới viết lần đầu, người cũ đang bị file phình quá 200 dòng mà agent vẫn sai.
> **Cần gì trước:** đã cài và mở được 1 session (bài 01).
> **Đọc xong bạn làm được:** viết `CLAUDE.md` <200 dòng với commands đã chạy thật + rules ALWAYS/NEVER check được; tách rules theo path vào `.claude/rules/`; phân biệt CLAUDE.md vs rules vs settings.json; viết `AGENTS.md` portable; quản lý auto-memory bằng `/memory`.
> **Thời gian:** ~30 phút

## Thuật ngữ dùng trong bài này

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| CLAUDE.md (gốc repo) | Tờ dặn dò Claude đọc đầu mỗi session, giữ suốt | `ALWAYS chạy pnpm --filter @acme/api test sau khi sửa` — commit git, <200 dòng |
| Nested CLAUDE.md | Giấy note từng phòng | `apps/mobile/CLAUDE.md` chỉ đọc khi sửa mobile |
| `.claude/rules/*.md` | Nội quy từng phòng, chìa khóa `paths` | `paths: ["apps/api/**"]` — chỉ load khi task chạm path đó; xem bằng `/rules` |
| `settings.json` | Ổ khóa: allow/ask/deny | `"deny": ["Bash(rm -rf:*)"]` — xem merged bằng `/permissions` |
| Import `@path` | Trỏ tới file khác thay vì copy | `@docs/architecture.md` — root giữ <60 dòng |
| AGENTS.md | Nội quy chung mọi hãng agent (Claude đọc trực tiếp từ w34/2026) | AGENTS.md chi tiết + CLAUDE.md 10 dòng trỏ sang |
| Auto-memory | Claude tự ghi learnings cross-session | Entry `repo dùng pnpm` tự save; xem/xóa bằng `/memory` |

## Mục lục

1. [Vì sao CLAUDE.md quan trọng nhất?](#1-vì-sao-claudemd-quan-trọng-nhất)
2. [Đặt ở đâu, load theo thứ tự nào, phân biệt 3 loại](#2-đặt-ở-đâu-load-theo-thứ-tự-nào-phân-biệt-3-loại)
3. [3 CLAUDE.md mẫu (copy-paste)](#3-3-claudemd-mẫu-copy-paste)
4. [Rules theo path + patterns](#4-rules-theo-path--patterns)
5. [AGENTS.md portability](#5-agentsmd-portability)
6. [Import & tách nhỏ](#6-import--tách-nhỏ)
7. [Auto-memory + `/memory`](#7-auto-memory--memory)
8. [Viết CLAUDE.md từ 0 (5 bước)](#8-viết-claudemd-từ-0-5-bước)
9. [Hiểu nhầm, anti-patterns, checklist, bài tập, link](#9-hiểu-nhầm-anti-patterns-checklist-bài-tập-link)

---

## 1. Vì sao CLAUDE.md quan trọng nhất?

Mọi session đều nạp CLAUDE.md **đầu tiên, giữ suốt, nạp lại mỗi turn** — "bộ nhớ dài hạn" duy nhất bạn kiểm soát được. Skill/subagent/hook đều load có điều kiện; CLAUDE.md load vô điều kiện. Mỗi subagent mặc định cũng đọc project CLAUDE.md (trừ agent `Explore`/`Plan` skip để giữ context nhỏ — bài 06): 1 dòng sai trong CLAUDE.md nhân bản ra mọi worker.

> Quy tắc 200 dòng là token economics (bài 00 mục 4): 150 dòng ≈ 2.500 tokens × N turns. Viết tệ (500 dòng wiki) → mọi task trả tiền cho rác mà agent vẫn sai chỗ quan trọng.

---

## 2. Đặt ở đâu, load theo thứ tự nào, phân biệt 3 loại

Thứ tự load (merge từ ngoài vào trong):

```text
~/.claude/CLAUDE.md            (personal, mọi project)
→ ./CLAUDE.md hoặc ./.claude/CLAUDE.md   (project, commit git cho team)
→ /etc/claude-code/CLAUDE.md   (system, nếu có)
→ nested CLAUDE.md ở subdirs   (lazy-load khi làm việc trong đó)
→ --add-dir dirs               (CHỈ khi CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1)
```

Precedence khi xung đột: `system < personal < project < nested < rules (paths-scoped)` — nested và rules thắng vì cụ thể hơn. `/doctor` (≥2.1.206) phát hiện dedupe local vs checked-in. Quy tắc team: personal chỉ để preferences cá nhân; mọi thứ team dùng chung vào project CLAUDE.md + commit.

```bash
wc -l CLAUDE.md .claude/CLAUDE.md ~/.claude/CLAUDE.md 2>/dev/null   # project file phải <200
# Trong session: /memory → liệt kê từng file + entries đang load; thấy rule trùng 2 files → xóa 1.
```

Phân biệt 3 loại — hay nhầm nhất:

| Loại | Ở đâu | Ví dụ nội dung | Khi nào dùng |
|---|---|---|---|
| **CLAUDE.md** | `./CLAUDE.md`, commit | `ALWAYS chạy pnpm --filter @acme/api test sau khi sửa apps/api/` | Dặn chung mọi task: lệnh build/test/lint, kiến trúc, style. Load luôn → <200 dòng |
| **`.claude/rules/*.md`** | `.claude/rules/api.md` + frontmatter `paths:` | `paths: ["apps/api/**"]` + `Mọi route mới phải có zod + test 401/422` | Dặn riêng từng folder; sửa mobile không tốn token đọc api rules |
| **`settings.json`** | `.claude/settings.json` (team, commit) + `.claude/settings.local.json` (personal) | `"deny": ["Bash(rm -rf:*)", "Write(.env*)"]` | Khóa allow/ask/deny — harness enforce (0 token). Xem bằng `/permissions` |

---

## 3. 3 CLAUDE.md mẫu (copy-paste)

> Mỗi mẫu <100 dòng, commands đã verify, rules check được. Thay `<...>` bằng project bạn.

### 3.1. Mẫu A — Web app (Next.js + Postgres + pnpm)

```markdown
# Project: Acme Shop Web — Next.js 15 storefront + API routes
## Tech Stack
- Next.js 15 (App Router), TypeScript strict, Tailwind, Prisma + Postgres 16
- Auth: NextAuth v5. Tests: Vitest + Playwright
## Commands (VERIFIED 2026-09 — chạy lại nếu đổi toolchain)
- Dev: `pnpm dev` (web :3000, cần `.env.local`); DB migrate: `pnpm prisma migrate dev`
- Test focused: `pnpm vitest run apps/web/src/app/login/` (không chạy full khi chỉ sửa 1 file)
- Full check trước PR: `pnpm lint && pnpm test && pnpm build`
## Architecture
- `apps/web/src/app/` routes (server components mặc định; "use client" chỉ khi cần)
- `apps/web/src/server/` owns DB access; client components KHÔNG import prisma trực tiếp
- `packages/contracts/` zod schemas dùng chung client/server
## Code Style
- API errors shape `{ code, message, requestId }`, HTTP status đúng
- Server actions validate bằng zod từ `packages/contracts/`, không validate tay
- Không `any`; ép kiểu phải có comment `// why: ...`
## Rules
- ALWAYS chạy focused test sau khi sửa; paste output vào báo cáo
- ALWAYS `pnpm prisma migrate dev --name <ten>` khi đổi schema, KHÔNG sửa SQL tay
- NEVER commit trực tiếp main; NEVER sửa `src/generated/` và migration đã merge
```

### 3.2. Mẫu B — Monorepo (pnpm workspaces)

```markdown
# Project: Acme Platform — pnpm monorepo (apps/api, apps/worker, packages/*)
## Tech Stack
- Node 22, pnpm 9 workspaces; apps/api (Fastify), apps/worker (BullMQ),
  packages/domain (pure, không phụ thuộc framework)
## Commands (VERIFIED)
- Dev all: `pnpm dev` (turbo pipeline)
- Test focused (QUAN TRỌNG — không chạy root test khi sửa 1 package):
  `pnpm --filter @acme/api test src/routes/login.test.ts`
- Cross-package: `pnpm --filter @acme/api... test`; Full: `pnpm lint && pnpm test && pnpm build`
## Architecture
- `packages/domain/` KHÔNG import từ `apps/*` hay framework (vi phạm → tách lại)
- Routes ở `apps/api/src/routes/`, types ở `packages/contracts/`, tests cạnh source
## Rules
- ALWAYS chạy `--filter` focused trước, chỉ chạy full khi PR
- NEVER import chéo `apps/*` vào `packages/domain/` (check `pnpm deps:check`)
- NEVER bump major dep mà không mở PR riêng; migration 1 cái/PR, tên `YYYYMMDD_<mo-ta>.sql`
```

### 3.3. Mẫu C — Mobile (Expo React Native)

```markdown
# Project: Acme Go — Expo React Native app (iOS + Android)
## Tech Stack
- Expo SDK 52, RN 0.76, TS strict, Zustand + React Query. Unit: Jest; E2E: Maestro
## Commands (VERIFIED)
- Dev: `pnpm start` / `pnpm ios` / `pnpm android`; Unit focused: `pnpm jest src/screens/Login/`
- E2E 1 flow: `maestro test flows/login.yaml`; Full: `pnpm lint && pnpm jest && maestro test flows/`
## Architecture
- `src/screens/` (1 folder/screen); `src/api/` owns network — screens KHÔNG fetch trực tiếp
- Mọi user-visible string qua `src/i18n/` (vi + en), không hardcode tiếng Việt trong JSX
## Rules
- ALWAYS chạy Jest focused sau sửa; E2E chỉ khi PR (chậm)
- NEVER commit khi `maestro test flows/login.yaml` fail
- NEVER thêm native module mà không ghi vào đây + update `app.json` plugin list
```

---

## 4. Rules theo path + patterns

Rule không nhét vào CLAUDE.md root thì tách `.claude/rules/*.md` với `paths` frontmatter (chỉ load khi task chạm path đó):

```markdown
---
paths: ["apps/api/**"]
---
# API rules (chỉ load khi sửa apps/api/)
- Mọi route mới phải có: zod schema + test happy + test 401/422 + log requestId.
- Không trả stack trace ra client (log server, trả { code, message, requestId }).
```

```markdown
---
paths: ["db/migrations/**", "*.sql"]
---
# DB rules
- 1 migration/PR, tên `YYYYMMDD_<mo-ta>.sql`, không sửa migration đã merge.
- Mọi ALTER TABLE production phải có rollback note trong header.
```

Patterns khác: `["*.test.ts"]` (test đặt cạnh source, mock ở boundary); `["packages/domain/**"]` (không import framework — `pnpm deps:check` chặn); `[".github/workflows/**"]` (workflow mới phải có `timeout-minutes`, action critical pin SHA, secrets chỉ qua `secrets.*`). Xem/quản lý bằng `/rules`.

Khi nào dùng gì: lệnh cho mọi task → CLAUDE.md root; quy ước 1 subtree → rules (paths); checklist deploy 20 bước → skill `/deploy` (lazy-load); rule "không push main" bị ignore hoài → hook PreToolUse (bài 07); team dùng cả Cursor/Copilot → AGENTS.md (mục 5).

---

## 5. AGENTS.md portability

**AGENTS.md** là chuẩn mở nhiều agent tools đọc (Cursor, Copilot, Codex, Windsurf...). Từ w34/2026, Claude Code đọc **trực tiếp** cả `AGENTS.md` lẫn `CLAUDE.md` → team dùng nhiều tools giữ 1 source of truth:

```text
Option 1 (khuyến nghị multi-tool): AGENTS.md là chính + CLAUDE.md ~10 dòng "@AGENTS.md + Claude-only notes" + .claude/rules/ path-scoped
Option 2 (team thuần Claude): CLAUDE.md là chính; AGENTS.md symlink/trỏ sang
Option 3: 2 files copy nhau → drift sau 2 tuần → ĐỪNG
```

```markdown
# File: AGENTS.md (repo root, commit — tool-agnostic)
## Commands
- Dev: `pnpm dev` · Test focused: `pnpm --filter @acme/api test` · Lint: `pnpm lint`
## Style
- TS strict, no `any` without `// why:`; API errors `{ code, message, requestId }`
## Boundaries
- `packages/domain/` must not import frameworks; never commit to main; one migration per PR
```

```markdown
# File: CLAUDE.md (repo root — ngắn!)
@AGENTS.md
## Claude-only notes
- Skills: dùng `/deploy` khi deploy, `/review-pr` khi review (xem .claude/skills/)
- Test reports: paste focused-test output vào báo cáo; path-scoped: xem `.claude/rules/` (`/rules`)
```

Verify: `wc -l AGENTS.md CLAUDE.md` (CLAUDE.md <30 dòng); hỏi Claude "liệt kê rules mày load từ AGENTS.md + CLAUDE.md + .claude/rules/" — phải kể được cả 3 nguồn.

---

## 6. Import & tách nhỏ

Dùng `@path` để import (Claude đọc lazy khi cần) — source 1 nơi, sửa 1 nơi. Ngưỡng: root >100 dòng → bắt đầu tách; >200 dòng → bắt buộc tách.

```markdown
# CLAUDE.md root ngắn, chi tiết lazy:
## Commands (luôn giữ inline)
- Dev: `pnpm dev` · Test: `pnpm --filter @acme/api test` · Lint: `pnpm lint`
@docs/architecture.md
@docs/api-conventions.md
@docs/db-migrations.md
```

Cấu trúc khuyến nghị: `CLAUDE.md` root <60 dòng + `docs/*.md` (architecture, conventions, migrations) + `.claude/rules/<domain>.md` (path-scoped).

---

## 7. Auto-memory + `/memory`

Claude tự save learnings (build commands, debugging insights) cross-session. `/memory` gồm 3 tab cần biết:

```text
Tab Files    — CLAUDE.md files đang load: phát hiện trùng lặp.
Tab Entries  — learnings Claude tự save: xóa cái sai (học nhầm 1 lần rồi áp dụng mãi).
Tab Settings — bật/tắt auto-memory, chọn scope (personal/project).
```

| Tình huống | Quyết định |
|---|---|
| Solo dev, 1 repo | Bật — học preferences nhanh |
| Team 3+ người, 1 repo | Tắt project-scope, giữ personal — tránh drift chéo |
| Repo có committed CLAUDE.md chuẩn | Tắt — committed file là truth, memory chỉ gây nhiễu |
| Sau khi đổi toolchain (npm→pnpm) | Xóa entries cũ + bật lại — không để memory cũ đầu độc |

Định kỳ (2 tuần/lần, 10 phút): `/memory` → dọn Entries → `/doctor` trim CLAUDE.md >200 dòng + dedupe. Team drift → tắt auto-memory project-scope, giữ rules trong committed files làm source of truth.

---

## 8. Viết CLAUDE.md từ 0 (5 bước)

**Bước 1 — Sinh nháp (3'):**

```bash
cd /path/to/repo
CLAUDE_CODE_NEW_INIT=1 claude   # trong session gõ: /init
```

**Bước 2 — Cắt 50% (5'):** xóa mọi dòng thuộc 3 loại: directory layout (Claude tự `ls` được), dependency list copy từ package.json (Claude tự `Read` được), architecture overview dài không có rationale (giữ boundaries + pitfalls, xóa mô tả).

**Bước 3 — Thêm verified commands (5'):** chạy THẬT từng lệnh trên máy, chỉ ghi lệnh pass + ghi chú (cần `.env`? cần DB chạy?):

```bash
pnpm dev; pnpm --filter @acme/api test; pnpm lint
```

**Bước 4 — Viết 5 rules ALWAYS/NEVER (5'):** mỗi rule cụ thể + check được:

```markdown
- ALWAYS chạy `pnpm --filter @acme/api test` sau khi sửa apps/api/
- NEVER commit trực tiếp main (luôn branch feat/* + PR)
- NEVER sửa `src/generated/`; DB change → migration trong `db/migrations/`, 1 migration/PR
- File >300 dòng → tách trước khi thêm code mới
```

**Bước 5 — Verify (2'):** `wc -l CLAUDE.md` phải <200 (lý tưởng <100); session mới `/memory` xác nhận load; giao task nhỏ xem Claude dùng đúng lệnh/rules không.

---

## 9. Hiểu nhầm, anti-patterns, checklist, bài tập, link

### Hiểu nhầm + anti-patterns (gộp)

| Sai | Đúng | Vì sao |
|---|---|---|
| CLAUDE.md càng dài càng tốt | <200 dòng, rule hay sai nhất lên đầu | 600 dòng ≈ 10k tokens × N turns; Claude đọc đầu file kỹ hơn |
| Ghi "chạy test" / "Write clean code" chung chung | Ghi lệnh focused chính xác + error shape cụ thể | Vague = rác; "chạy test" → Claude chạy full 10 phút hoặc sai package |
| Nhét mọi thứ vào root cho chắc | Path-scoped → `rules/`; checklist dài → skill; luật cấm → settings/hook | Rules là advisory (tốn token khi load); settings là enforce (0 token) — không phải một |
| AGENTS.md + CLAUDE.md copy nhau | 1 source of truth, file kia `@` trỏ sang | Drift sau 2 tuần thành 2 sự thật mâu thuẫn |
| Auto-memory bật là khỏi viết file | Team 3+ → tắt project-scope; committed file mới là truth | Memory mỗi máy drift khác nhau |
| Rule bị ignore hoài vẫn để trong CLAUDE.md | Nâng thành hook Pre/PostToolUse (bài 07) | Advisory bị quên; law enforce được |

### Checklist CLAUDE.md khỏe (paste vào PR review)

- [ ] <200 dòng (`wc -l`); commands đã chạy thật (có ngày verify nếu toolchain hay đổi).
- [ ] Rules ALWAYS/NEVER cụ thể + check được; không có layout/dependency list copy.
- [ ] Path-scoped tách ra `.claude/rules/`; checklist dài thành skill; rule hay miss thành hook.
- [ ] `/doctor` không báo dedupe/trim.

### Bài tập

1. (15') `/init` → xóa 50% theo mục 8 Bước 2, đếm dòng trước/sau.
2. (10') Thêm 3 verified commands (dev/test/lint) đã chạy thật + ghi chú điều kiện.
3. (10') Viết 5 rules ALWAYS/NEVER; giao task nhỏ kiểm tra Claude tuân thủ cả 5.
4. (15') Chạy `/doctor`, tách 1 mục dài thành `rules/` hoặc skill; `wc -l` giảm mà task vẫn pass.
5. (15', nâng cao) Setup AGENTS.md theo Option 1; mở repo bằng Cursor/Copilot kiểm tra đọc được.

### Link chéo

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: token economics, bảng chọn extension; **[02 — Bề mặt](./02-cac-be-mat-terminal-ide-web-desktop.md)**: config nào lên cloud.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/memory /rules /doctor /compact`; **[05 — Skills](./05-skills-custom-commands.md)**: tách checklist thành skill lazy-load.
- **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: Explore/Plan skip CLAUDE.md; **[07 — Hooks](./07-hooks-tu-dong-hoa.md)**: nâng rule hay miss thành law; **[10 — Permissions](./10-permissions-modes-availability.md)**: settings.json allow/ask/deny.
