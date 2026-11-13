# 03 — CLAUDE.md, memory & rules (file quan trọng nhất)

> **Bài này cho ai:** dev viết `CLAUDE.md` cho repo — file quyết định 50% chất lượng agent; người mới viết lần đầu, người cũ đang bị file phình quá 200 dòng mà agent vẫn sai.
> **Cần gì trước:** đã cài và mở được 1 session (bài 01).
> **Đọc xong bạn làm được:** viết `CLAUDE.md` <200 dòng với commands đã chạy thật + rules ALWAYS/NEVER check được; tách rules theo path vào `.claude/rules/`; phân biệt CLAUDE.md vs rules vs settings.json; viết `AGENTS.md` portable; quản lý auto-memory bằng `/memory`.
> **Thời gian:** ~30 phút

## Thuật ngữ dùng trong bài này

Mục này là "bảng từ điển" của cả bài: trước khi vào nội dung, nhìn qua 1 lần để sau này đọc không bị lạc thuật ngữ.

| Thuật ngữ | Hiểu nôm na là gì | Ví dụ thấy ngay |
|---|---|---|
| CLAUDE.md (gốc repo) | Tờ dặn dò Claude đọc đầu mỗi session, giữ suốt | `ALWAYS chạy pnpm --filter @acme/api test sau khi sửa` — commit git, <200 dòng |
| Nested CLAUDE.md | Giấy note từng phòng | `apps/mobile/CLAUDE.md` chỉ đọc khi sửa mobile |
| `.claude/rules/*.md` | Nội quy từng phòng, chìa khóa `paths` | `paths: ["apps/api/**"]` — chỉ load khi task chạm path đó; xem bằng `/rules` |
| `settings.json` | Ổ khóa: allow/ask/deny | `"deny": ["Bash(rm -rf:*)"]` — xem merged bằng `/permissions` |
| Import `@path` | Trỏ tới file khác thay vì copy | `@docs/architecture.md` — root giữ <60 dòng |
| AGENTS.md | Nội quy chung mọi hãng agent (Claude đọc trực tiếp từ w34/2026) | AGENTS.md chi tiết + CLAUDE.md 10 dòng trỏ sang |
| Auto-memory | Claude tự ghi learnings cross-session | Entry `repo dùng pnpm` tự save; xem/xóa bằng `/memory` |

> **Cách đọc bảng này:** cột giữa là cách hiểu đời thường của từng thuật ngữ; khi đọc mục nào mà quên từ, quay lại bảng này tra.

> **Tóm gọn 1 câu:** Nhớ đúng 6 từ khóa: CLAUDE.md (dặn chung), nested CLAUDE.md (dặn từng thư mục), rules (dặn theo path), settings.json (khóa cứng), `@path` (trỏ file khác), AGENTS.md (dùng chung nhiều tool).

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

Mục này trả lời câu hỏi "tại sao file này lại quyết định nửa chất lượng agent" — hiểu cái này bạn mới chịu cắt gọt file của mình.

Mọi session đều nạp CLAUDE.md **đầu tiên, giữ suốt, nạp lại mỗi turn** — "bộ nhớ dài hạn" duy nhất bạn kiểm soát được. Hãy hình dung: đó là tờ giấy dán trước mặt Claude suốt cả ngày làm việc, nhìn vào mỗi khi bắt đầu việc gì mới. Skill/subagent/hook đều load có điều kiện; CLAUDE.md load vô điều kiện. Mỗi subagent mặc định cũng đọc project CLAUDE.md (trừ agent `Explore`/`Plan` skip để giữ context nhỏ — bài 06): 1 dòng sai trong CLAUDE.md nhân bản ra mọi worker.

> Quy tắc 200 dòng là token economics (bài 00 mục 4): 150 dòng ≈ 2.500 tokens × N turns. Viết tệ (500 dòng wiki) → mọi task trả tiền cho rác mà agent vẫn sai chỗ quan trọng.

Tưởng như bảng giá cước taxi: dòng nào dài hơn là khách trả thêm tiền cho đúng đoạn đó, dù có cần hay không. 500 dòng wiki = trả tiền đọc sách mỗi turn, trong khi chỉ cần tờ cheat sheet 1 trang.

> **Tóm gọn 1 câu:** CLAUDE.md là bộ nhớ dài hạn được nạp mọi turn cho mọi subagent — ngắn, đúng và sai một dòng thì tốn kém nhân nhiều lần.

---

## 2. Đặt ở đâu, load theo thứ tự nào, phân biệt 3 loại

Mục này chỉ chỗ "dán tờ giấy" và thứ tự ai thắng ai khi có nhiều tờ cùng dặn một việc.

Thứ tự load (merge từ ngoài vào trong):

```text
~/.claude/CLAUDE.md            (personal, mọi project)
→ ./CLAUDE.md hoặc ./.claude/CLAUDE.md   (project, commit git cho team)
→ /etc/claude-code/CLAUDE.md   (system, nếu có)
→ nested CLAUDE.md ở subdirs   (lazy-load khi làm việc trong đó)
→ --add-dir dirs               (CHỈ khi CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1)
```

Precedence khi xung đột: `system < personal < project < nested < rules (paths-scoped)` — nested và rules thắng vì cụ thể hơn. `/doctor` (≥2.1.206) phát hiện dedupe local vs checked-in. Quy tắc team: personal chỉ để preferences cá nhân; mọi thứ team dùng chung vào project CLAUDE.md + commit.

> 📄 **Code ví dụ:** [`examples/01-2-at-o-au-load-theo-thu-tu.sh`](examples/01-2-at-o-au-load-theo-thu-tu.sh)

Phân biệt 3 loại — hay nhầm nhất:

Ba "điểm đựng dặn dò" dưới đây hay bị lộn vào nhau; bảng này là bản phân định:

| Loại | Ở đâu | Ví dụ nội dung | Khi nào dùng |
|---|---|---|---|
| **CLAUDE.md** | `./CLAUDE.md`, commit | `ALWAYS chạy pnpm --filter @acme/api test sau khi sửa apps/api/` | Dặn chung mọi task: lệnh build/test/lint, kiến trúc, style. Load luôn → <200 dòng |
| **`.claude/rules/*.md`** | `.claude/rules/api.md` + frontmatter `paths:` | `paths: ["apps/api/**"]` + `Mọi route mới phải có zod + test 401/422` | Dặn riêng từng folder; sửa mobile không tốn token đọc api rules |
| **`settings.json`** | `.claude/settings.json` (team, commit) + `.claude/settings.local.json` (personal) | `"deny": ["Bash(rm -rf:*)", "Write(.env*)"]` | Khóa allow/ask/deny — harness enforce (0 token). Xem bằng `/permissions` |

> **Cách đọc bảng này:** nhìn cột "Khi nào dùng" để chọn chỗ đúng — dặn chung vào CLAUDE.md, dặn theo folder vào rules, dặn cứng kiểu cấm/khóa vào settings.json.

> **Tóm gọn 1 câu:** Load từ ngoài vào trong, chỗ cụ thể hơn thắng, và ba loại (CLAUDE.md / rules / settings.json) phục vụ ba mục đích khác nhau.

---

## 3. 3 CLAUDE.md mẫu (copy-paste)

Mục này cho 3 mẫu dùng ngay cho 3 loại dự án phổ biến; lấy về sửa tên là xong phần khung.

> Mỗi mẫu <100 dòng, commands đã verify, rules check được. Thay `<...>` bằng project bạn.

### 3.1. Mẫu A — Web app (Next.js + Postgres + pnpm)

Mẫu cho web app Next.js — vùng lệnh chia nhỏ để đỡ tốn thời gian chạy test full:

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

> **Tóm gọn 1 câu:** Mẫu A đánh debts vào 3 chỗ: Commands ghi rõ lệnh focused (đỡ chạy test full), Rules ALWAYS/NEVER check được, Architecture ghi chốt boundary nào không được phá.

### 3.2. Mẫu B — Monorepo (pnpm workspaces)

Mẫu cho monorepo — trọng tâm là đừng chạy test cả repo khi chỉ sửa một package:

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

> **Tóm gọn 1 câu:** Điểm sống còn của mẫu B là `--filter` — không cho agent chạy test cả repo, và chặn import chéo vào `packages/domain/`.

### 3.3. Mẫu C — Mobile (Expo React Native)

Mẫu cho mobile app — E2E chậm nên được xếp chạy muộn nhất:

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

> **Tóm gọn 1 câu:** Mẫu C xếp E2E chạy muộn nhất vì chậm — unit focused chạy sau mỗi lần sửa, Maestro chỉ chạy khi PR.

---

## 4. Rules theo path + patterns

Mục này dạy cách "chia phòng": dặn dò cho từng thư mục, chỉ nạp khi làm đúng thư mục đó — đỡ tốn token.

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

Hãy nghĩ như phân loại đồ trong nhà: đồ dùng hằng ngày để ngay cửa (root), đồ phòng bếp để bếp (rules theo path), đồ ít dùng cất kho (skill lazy-load), đồ nguy hiểm khóa tủ (settings/hook).

> **Tóm gọn 1 câu:** Dặn dò nào dùng cho thư mục nào thì tách vào rules với `paths`, để CLAUDE.md root gọn và tiết kiệm token.

---

## 5. AGENTS.md portability

Mục này giải quyết bài toán team xài nhiều công cụ AI cùng lúc: viết một lần, nhiều agent đều đọc.

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

> **Tóm gọn 1 câu:** AGENTS.md là một nguồn nội quy dùng chung cho mọi agent tool; giữ 1 file gốc và để file kia trỏ sang, đừng copy hai bản.

---

## 6. Import & tách nhỏ

Mục này chỉ cách để root file luôn gọn: chi tiết để ở file khác, khi cần thì "mượn" qua `@path`.

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

`@path` giống việc để tờ ghi chú "chi tiết xem cuốn sổ A trang 3" thay vì chép nguyên cuốn sổ vào tờ giấy của mình.

> **Tóm gọn 1 câu:** Dùng `@path` để trỏ sang file chi tiết thay vì chép dài vào root — root >200 dòng là bắt buộc phải tách.

---

## 7. Auto-memory + `/memory`

Mục này bàn về trí nhớ "tự ghi chép" của Claude: tiện nhưng cần dọn định kỳ như dọn tủ lạnh.

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

> **Cách đọc bảng này:** cột trái là hoàn cảnh của bạn, cột phải là quyết định bật/tắt tương ứng — tìm đúng dòng của mình là xong.

Định kỳ (2 tuần/lần, 10 phút): `/memory` → dọn Entries → `/doctor` trim CLAUDE.md >200 dòng + dedupe. Team drift → tắt auto-memory project-scope, giữ rules trong committed files làm source of truth.

> **Tóm gọn 1 câu:** Auto-memory tiện cho solo dev nhưng dễ tạo "hai sự thật" khi làm team — bật có chọn lọc và dọn 2 tuần một lần.

---

## 8. Viết CLAUDE.md từ 0 (5 bước)

Mục này là công thức từng bước có bấm giờ, làm theo là ra file chất lượng mà không phải đoán.

**Bước 1 — Sinh nháp (3'):**

> 📄 **Code ví dụ:** [`examples/02-8-viet-claude-md-tu-0-5-buoc.sh`](examples/02-8-viet-claude-md-tu-0-5-buoc.sh)

**Bước 2 — Cắt 50% (5'):** xóa mọi dòng thuộc 3 loại: directory layout (Claude tự `ls` được), dependency list copy từ package.json (Claude tự `Read` được), architecture overview dài không có rationale (giữ boundaries + pitfalls, xóa mô tả).

**Bước 3 — Thêm verified commands (5'):** chạy THẬT từng lệnh trên máy, chỉ ghi lệnh pass + ghi chú (cần `.env`? cần DB chạy?):

> 📄 **Code ví dụ:** [`examples/03-8-viet-claude-md-tu-0-5-buoc.sh`](examples/03-8-viet-claude-md-tu-0-5-buoc.sh)

**Bước 4 — Viết 5 rules ALWAYS/NEVER (5'):** mỗi rule cụ thể + check được:

```markdown
- ALWAYS chạy `pnpm --filter @acme/api test` sau khi sửa apps/api/
- NEVER commit trực tiếp main (luôn branch feat/* + PR)
- NEVER sửa `src/generated/`; DB change → migration trong `db/migrations/`, 1 migration/PR
- File >300 dòng → tách trước khi thêm code mới
```

**Bước 5 — Verify (2'):** `wc -l CLAUDE.md` phải <200 (lý tưởng <100); session mới `/memory` xác nhận load; giao task nhỏ xem Claude dùng đúng lệnh/rules không.

> **Tóm gọn 1 câu:** Sinh nháp → cắt 50% → thêm lệnh đã chạy thật → viết 5 rules ALWAYS/NEVER → verify bằng số dòng và task thử.

---

## 9. Hiểu nhầm, anti-patterns, checklist, bài tập, link

Mục chốt bài: gom những hiểu lầm hay gặp, checklist review và bài tập để tự thực hành.

### Hiểu nhầm + anti-patterns (gộp)

| Sai | Đúng | Vì sao |
|---|---|---|
| CLAUDE.md càng dài càng tốt | <200 dòng, rule hay sai nhất lên đầu | 600 dòng ≈ 10k tokens × N turns; Claude đọc đầu file kỹ hơn |
| Ghi "chạy test" / "Write clean code" chung chung | Ghi lệnh focused chính xác + error shape cụ thể | Vague = rác; "chạy test" → Claude chạy full 10 phút hoặc sai package |
| Nhét mọi thứ vào root cho chắc | Path-scoped → `rules/`; checklist dài → skill; luật cấm → settings/hook | Rules là advisory (tốn token khi load); settings là enforce (0 token) — không phải một |
| AGENTS.md + CLAUDE.md copy nhau | 1 source of truth, file kia `@` trỏ sang | Drift sau 2 tuần thành 2 sự thật mâu thuẫn |
| Auto-memory bật là khỏi viết file | Team 3+ → tắt project-scope; committed file mới là truth | Memory mỗi máy drift khác nhau |
| Rule bị ignore hoài vẫn để trong CLAUDE.md | Nâng thành hook Pre/PostToolUse (bài 07) | Advisory bị quên; law enforce được |

> **Cách đọc bảng này:** cột trái là cách làm sai hay gặp, cột giữa là cách làm đúng, cột cuối giải thích vì sao — dùng khi review file của mình.

### Checklist CLAUDE.md khỏe (paste vào PR review)

Danh sách này như giấy khám sức khỏe định kỳ cho file — dán vào PR review để người khác cùng soi:

- [ ] <200 dòng (`wc -l`); commands đã chạy thật (có ngày verify nếu toolchain hay đổi).
- [ ] Rules ALWAYS/NEVER cụ thể + check được; không có layout/dependency list copy.
- [ ] Path-scoped tách ra `.claude/rules/`; checklist dài thành skill; rule hay miss thành hook.
- [ ] `/doctor` không báo dedupe/trim.

> **Tóm gọn 1 câu:** CLAUDE.md khỏe là: ngắn dưới 200 dòng, lệnh thật, rules check được, đã tách path-scoped và `/doctor` sạch.

### Bài tập

Năm bài dưới đây dùng chính repo của bạn làm "đối tượng thực hành":

1. (15') `/init` → xóa 50% theo mục 8 Bước 2, đếm dòng trước/sau.
2. (10') Thêm 3 verified commands (dev/test/lint) đã chạy thật + ghi chú điều kiện.
3. (10') Viết 5 rules ALWAYS/NEVER; giao task nhỏ kiểm tra Claude tuân thủ cả 5.
4. (15') Chạy `/doctor`, tách 1 mục dài thành `rules/` hoặc skill; `wc -l` giảm mà task vẫn pass.
5. (15', nâng cao) Setup AGENTS.md theo Option 1; mở repo bằng Cursor/Copilot kiểm tra đọc được.

> **Tóm gọn 1 câu:** Làm đủ 5 bài là bạn đã cắt gọt, xác minh và tách rules của chính repo mình theo chuẩn của bài này.

### Link chéo

Mục này là bản đồ sang các bài liền đề tài, xem nhanh khi cần đi sâu:

- **[00 — Tổng quan](./00-tong-quan-claude-code.md)**: token economics, bảng chọn extension; **[02 — Bề mặt](./02-cac-be-mat-terminal-ide-web-desktop.md)**: config nào lên cloud.
- **[04 — Slash commands](./04-slash-commands-toan-tap.md)**: `/memory /rules /doctor /compact`; **[05 — Skills](./05-skills-custom-commands.md)**: tách checklist thành skill lazy-load.
- **[06 — Subagents](./06-subagents-agent-teams-parallel.md)**: Explore/Plan skip CLAUDE.md; **[07 — Hooks](./07-hooks-tu-dong-hoa.md)**: nâng rule hay miss thành law; **[10 — Permissions](./10-permissions-modes-availability.md)**: settings.json allow/ask/deny.

> **Tóm gọn 1 câu:** Bài này là trung tâm; đi sâu thêm thì sang bài 04 (lệnh), 05 (skills), 07 (hooks) và 10 (permissions).
