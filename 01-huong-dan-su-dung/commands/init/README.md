# /init — Quét codebase, sinh CLAUDE.md + settings chuẩn cho repo mới

> Loại Built-in · Nhóm Code & Repo · Nguy hiểm Không (chỉ đọc repo + sinh file docs/settings; có ghi file mới nhưng là file docs — review trước khi commit)

`/init` là "lễ nhập trạch" cho repo: Claude Code đi bộ toàn bộ codebase (cấu trúc thư mục, package.json, git history, docs), rồi sinh `CLAUDE.md` (luật dự án: lệnh build/test, convention, việc cấm) + gợi ý `settings.json` baseline. Từ đó mọi session sau khỏi hỏi lại "chạy test bằng gì?".

---

## Cú pháp & tham số

| Cú pháp | Tham số | Ý nghĩa |
|---|---|---|
| `/init` | _(không có)_ | Quét repo + sinh CLAUDE.md tương tác |
| `/init <gợi ý>` | text sau lệnh | Quét + ưu tiên gợi ý của bạn (VD stack, quy ước team) |
| `CLAUDE_CODE_NEW_INIT=1` | env var | Bật flow init interactive mới (hỏi sâu hơn, tùy bản) |

Ví dụ gọi từng dạng:

```bash
# Dạng 1: cơ bản — đứng ở root repo rồi gọi
/init
```

```bash
# Dạng 2: kèm gợi ý team (khuyên dùng)
/init Dự án Next.js + Postgres, dùng pnpm, test bằng vitest.
Quy ước: commit tiếng Việt, cấm force-push main, .env không bao giờ commit.
```

```bash
# Dạng 3: bật flow interactive mới (nếu bản hỗ trợ)
CLAUDE_CODE_NEW_INIT=1 claude
# rồi trong session:
/init
```

```bash
# Dạng 4: init cho monorepo — chỉ định scope
/init Chỉ quét packages/payments/ và apps/web/, bỏ qua legacy/ vì sắp xóa.
```

```bash
# Dạng 5: init lại sau 3 tháng (codebase đổi nhiều)
/init Codebase đã đổi nhiều từ lần init trước. Quét lại và cập nhật CLAUDE.md,
giữ lại quy ước team cũ trong file, chỉ sửa phần đã lỗi thời.
```

```bash
# Dạng 6: kiểm tra kết quả sau init
# Đọc file sinh ra:
# CLAUDE.md (root) + .claude/settings.json (gợi ý)
```

---

## Cách nó hoạt động

### Cơ chế sâu: /init phân tích codebase thế nào?

1. **Pha 1 — Discovery (đọc bao quát, ~2–5 phút):**
   - Liệt kê cây thư mục 2–3 tầng (`Glob`), đọc `package.json / pyproject.toml / go.mod / Cargo.toml` để biết stack + scripts.
   - Đọc `README.md`, `docs/*`, `.env.example` (không đọc `.env` thật), `Dockerfile`, `docker-compose.yml`, CI config (`.github/workflows/*`).
   - `git log --oneline -20` + `git status` để biết nhịp commit, branch chính (`main` hay `master`).
2. **Pha 2 — Deep read (đọc sâu file trụ cột):**
   - Entry points (`src/index.ts`, `main.py`, `app/layout.tsx`), config (`tsconfig`, `eslint`, `vite.config`), test setup (`vitest.config`, `pytest.ini`).
   - Đếm test files, phát hiện framework test (jest/vitest/pytest/go test), lệnh lint/format.
   - Ghi nhận convention: tabs/spaces, import order, ngôn ngữ commit, branch strategy.
3. **Pha 3 — Hỏi bạn (nhất là với CLAUDE_CODE_NEW_INIT=1):**
   - Interactive picker: "Lệnh test chính? Lệnh build? Có dùng docker không? Việc gì CẤM model làm?"
   - Câu trả lời của bạn được ghi thẳng vào CLAUDE.md — đây là phần quý nhất (máy không đoán được ý team).
4. **Pha 4 — Sinh artifacts:**
   - `CLAUDE.md` ở root: gồm project overview, lệnh copy-paste (dev/build/test/lint), cấu trúc thư mục, convention, danh sách CẤM, cách verify.
   - Gợi ý `.claude/settings.json` baseline (allow test/lint, ask push, deny rm/.env — xem bài permissions).
   - Tùy bản: thêm `.claude/commands/*` custom mẫu hoặc `docs/ONBOARDING.md`.
5. **CLAUDE.md được nạp khi nào?**
   - Mỗi session mới (và sau `/clear`), Claude Code tự đọc `CLAUDE.md` root + `~/.claude/CLAUDE.md` vào system prompt. Nghĩa là 1 lần init → mọi session sau đều "biết luật".
6. **Khi nào init lại?**
   - Đổi stack (npm→pnpm, jest→vitest), đổi cấu trúc lớn, hoặc CLAUDE.md > 3 tháng. Init lại với ghi chú "giữ quy ước cũ" để không mất ý team.

### Sơ đồ pha

```text
[/init] → Discovery (cây thư mục + package + git + docs)
       → Deep read (entry + config + test setup)
       → Hỏi bạn (test cmd? cấm gì?) [kỹ nhất khi NEW_INIT=1]
       → Sinh CLAUDE.md + settings baseline
       → Bạn review → commit
       → Mọi session sau tự nạp luật
```

### Khác gì với lệnh dễ nhầm?

| Lệnh | Sinh gì? | Khi nào? |
|---|---|---|
| `/init` | CLAUDE.md + settings cho cả repo | 1 lần lúc onboard / refresh định kỳ |
| Viết CLAUDE.md tay | Cùng file, nhưng bạn tự viết | Repo đặc thù, bạn đã rõ luật |
| `/plan` | Plan cho 1 task cụ thể | Mỗi task lớn |
| `/permissions` | Chỉ bảng quyền | Khi chỉnh phanh |

> Quy tắc ngón tay cái:
>
> - **Repo chưa có CLAUDE.md → `/init` ngay, đừng để mỗi session hỏi lại "test bằng gì?".**

---

## Ví dụ thực tế

### Kịch bản 1: Onboard repo Next.js lạ trong 10 phút

Bạn vừa join team, repo 300 file chưa từng thấy.

```bash
# Bước 1: đứng root, init kèm gợi ý sơ bộ từ README
/init Tôi là người mới. Quét repo, sinh CLAUDE.md gồm: lệnh dev/build/test,
cấu trúc thư mục, và 5 việc cấm làm (nếu phát hiện được từ config).
```

> Kết quả CLAUDE.md mẫu sinh ra:

```markdown
# Dự án shop-web (Next.js 15 + Postgres)

## Lệnh
- Dev: pnpm dev
- Build: pnpm build
- Test: pnpm vitest run
- Lint: pnpm eslint . --fix

## Cấu trúc
- app/ — routes (App Router)
- src/payments/ — Stripe (đừng đụng khi chưa có plan)
- tests/ — vitest

## Cấm
- Không force-push main
- Không commit .env
- Không sửa migration đã apply production
```

```bash
# Bước 2: review + commit để cả team hưởng
# git add CLAUDE.md .claude/settings.json && git commit -m "chore: init CLAUDE.md"
```

### Kịch bản 2: Monorepo Python — init có scope để khỏi rác

```bash
/init Repo monorepo: services/api (FastAPI) + services/worker (Celery) + legacy/ (sắp xóa, bỏ qua).
Sinh CLAUDE.md tập trung 2 services chính, ghi rõ lệnh test riêng từng service,
và note legacy/ không được sửa.
```

> Kết quả: CLAUDE.md gọn, không bị nhiễu bởi code legacy sắp chết.

### Kịch bản 3: Refresh sau 3 tháng — giữ ý team, sửa phần cũ

```bash
/init CLAUDE.md hiện tại đã 3 tháng. Quét lại: team vừa chuyển jest→vitest,
thêm service notifications/. Cập nhật 2 điểm này, giữ nguyên mọi quy ước cấm còn lại.
```

### Kịch bản 4: Interactive sâu với CLAUDE_CODE_NEW_INIT=1

```bash
# Terminal:
CLAUDE_CODE_NEW_INIT=1 claude
```

```bash
# Trong session:
/init
# → picker hỏi: test cmd? package manager? có docker? branch chính?
# → bạn chọn thay vì để model đoán
# → CLAUDE.md chính xác ngay lần đầu, khỏi sửa tay
```

---

## Rủi ro & lưu ý

### Tốn token?

- Init quét 20–100 file → 30–100K input tokens 1 lần (~$0.10–0.30 sonnet). Rẻ vì làm 1 lần, hưởng mọi session sau (mỗi session khỏi hỏi lại 5 câu × 2K tokens).
- Mẹo: init bằng `sonnet + medium` là đủ; không cần opus/max.

### Destructive?

- Ghi `CLAUDE.md` + `.claude/settings.json` — là file docs/config, không phải code. Nhưng vẫn review diff trước khi commit (model có thể đoán sai lệnh test).
- Không init ở nhầm thư mục (VD `~/` thay vì repo root) — sẽ sinh CLAUDE.md nhầm chỗ. Kiểm tra `pwd` trước.
- `.env` thật: init chuẩn không đọc `.env` (chỉ `.env.example`). Nếu thấy CLAUDE.md chứa secret → xóa ngay + rotate key (model đã đọc nhầm do bạn allow).

### Version floor

- `/init`: mọi bản v2.1.x.
- `CLAUDE_CODE_NEW_INIT=1` interactive: bản mới (nếu bật mà không khác gì, bản của bạn chưa có — dùng `/init` thường + gợi ý tay).

---

## Kết hợp trong workflow

| Combo | Khi nào dùng | Lệnh mẫu |
|---|---|---|
| `/init` → `/permissions` | Sinh luật + cài phanh cùng lúc | `/init` rồi `/permissions` baseline |
| `/init` → commit → team hưởng | 1 người init, cả team dùng | Commit `CLAUDE.md` + `settings.json` |
| `/init` → `/plan` | Hiểu repo rồi mới plan task lớn | `/init` (1 lần) → `/plan` (mỗi task) |
| `/init` → `/clear` | Nạp luật mới vào session | Sửa `CLAUDE.md` → `/clear` để nạp lại |

Workflow chuẩn "repo mới":

```bash
# 1. Init
/init Dự án FastAPI + Celery, test bằng pytest, cấm sửa migration cũ.

# 2. Review artifacts
# đọc CLAUDE.md + .claude/settings.json, sửa lệnh sai (nếu có)

# 3. Cài phanh
/permissions
# → allow pytest/ruff, deny rm/.env

# 4. Commit cho team
# git add CLAUDE.md .claude/settings.json && git commit -m "chore: onboard claude"

# 5. Từ nay mọi task đều nhanh hơn
/plan Thêm tính năng X...
```

---

## Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `/init` sinh lệnh test sai (`npm test` trong khi dùng pnpm) | Đoán từ package.json thiếu scripts, hoặc monorepo nhiều package | Sửa tay CLAUDE.md 1 dòng; lần sau `/init` kèm gợi ý rõ package manager |
| CLAUDE.md quá dài/dài dòng 200 dòng | Repo lớn + model verbose | Bảo "rút gọn còn 60 dòng, chỉ giữ lệnh + cấm + cấu trúc" |
| Init ở nhầm thư mục (sinh CLAUDE.md ở `~/`) | Quên `cd` vào repo | Xóa file nhầm, `cd` đúng repo, `/init` lại |
| `CLAUDE_CODE_NEW_INIT=1` không khác gì | Bản chưa hỗ trợ flow mới | Dùng `/init` + gợi ý tay chi tiết (tương đương) |
| Init xong session sau model vẫn hỏi "test bằng gì?" | CLAUDE.md nằm sai chỗ (không ở root) hoặc session chưa reload | Đặt `CLAUDE.md` ở root repo; `/clear` để nạp lại |
| CLAUDE.md chứa secret | Allow đọc `.env` thật / paste secret vào gợi ý | Xóa secret khỏi file, rotate key, thêm deny `Read(.env)` |
| Team không thấy CLAUDE.md của bạn | Quên commit / để ở `~/.claude/` (riêng bạn) | Commit `CLAUDE.md` root + `.claude/settings.json` lên git |

---

## Tham khảo

- Lệnh liên quan trực tiếp:
  - [../permissions/README.md](../permissions/README.md) — cài phanh ngay sau init
  - [../plan/README.md](../plan/README.md) — hiểu repo rồi mới plan
  - [../model/README.md](../model/README.md) — init bằng sonnet là đủ
  - [../diff/README.md](../diff/README.md) — review artifacts init sinh ra
- Bài tổng quan:
  - `../04-slash-commands-toan-tap.md`
  - `../06-subagents-agent-teams-parallel.md`
  - `../10-permissions-modes-availability.md`
  - `../11-git-worktrees-checkpoints.md`
  - `../12-agent-sdk-ci-cd-automation.md`

> Mẹo 1 dòng: _repo chưa có CLAUDE.md thì `/init` là việc đầu tiên — 10 phút hôm nay tiết kiệm 10 giờ hỏi lặp._
