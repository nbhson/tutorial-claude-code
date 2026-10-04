# 03 — CLAUDE.md, Memory & Rules (File Quan Trọng Nhất)

## 1. CLAUDE.md là gì và đặt ở đâu

Markdown Claude đọc **đầu mỗi session**, giữ suốt session. Chứa: project là gì, build/test/lint
lệnh nào, kiến trúc, code style, rules "luôn/không bao giờ".

Thứ tự load (merge từ ngoài vào trong):

```
~/.claude/CLAUDE.md          (personal, mọi project)
→ ./CLAUDE.md hoặc ./.claude/CLAUDE.md  (project, commit git cho team)
/etc/claude-code/CLAUDE.md   (system, nếu có)
→ nested CLAUDE.md ở subdirs (lazy-load khi làm việc trong đó)
→ --add-dir dirs (CHỈ khi CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1)
```

Xem thực tế đang load gì: `/memory`. Sửa: `/memory` (edit files, bật/tắt auto-memory, xem entries).

## 2. Template chuẩn (<200 dòng!)

```markdown
# Project: <Name> — one-liner mô tả

## Tech Stack
- <Framework>, <Lang + version>, <DB>, <lib chính>

## Commands (VERIFIED — chỉ ghi lệnh đã chạy thử)
- Dev: `pnpm dev`
- Build: `pnpm build`
- Test (focused): `pnpm --filter @acme/auth test`
- Full check: `pnpm lint && pnpm test && pnpm build`

## Architecture
- `apps/api/` owns HTTP transport; `packages/domain/` không phụ thuộc framework
- Routes ở ..., models/types ở ..., tests ở ...

## Code Style (cụ thể, check được)
- TypeScript strict, không `any` trừ khi ép kiểu có comment
- API errors shape `{ code, message, requestId }`
- File >300 dòng thì tách

## Rules (ngắn, mệnh lệnh)
- ALWAYS chạy focused tests sau khi sửa
- NEVER commit trực tiếp main, NEVER sửa `src/generated/`
- DB change → bắt buộc migration trong `db/migrations/`
```

Nguyên tắc của official memory guide:

- **<200 dòng** — đây là context budget, không phải target trang trí.
- Xóa mọi thứ Claude tự suy ra được (directory layout, dependency list, architecture overview dài).
- Giữ: **pitfalls, rationale, conventions khác default** của tool.
- Viết cụ thể, check được. "Write clean code" = rác. "API errors dùng `{code,message,requestId}`" = vàng.
- Commands phải **verified** (đã chạy thật), không ghi bừa.

## 3. Import & tách nhỏ (đừng phình file)

```markdown
@path/to/architecture.md
@docs/conventions.md
```

- Project lớn: tách thành `.claude/rules/*.md` với `paths` frontmatter (rule chỉ load khi chạm path đó):

```markdown
---
paths: ["apps/mobile/**", "*.swift"]
---
- UI dùng SwiftUI, không UIKit trừ khi cần perf...
```

- Xem/quản lý: `/rules`. Cross-tool portability: giữ rules chung ở `AGENTS.md`, CLAUDE.md ngắn trỏ sang.

## 4. Auto-memory (Claude tự học) + `/memory`

Claude tự save learnings (build commands, debugging insights) cross-session — bạn không cần viết tay.
Dùng `/memory` để xem entries, xóa cái sai, tắt auto-memory nếu team không muốn drift.
Định kỳ chạy `/doctor`: nó dedupe local vs checked-in CLAUDE.md và đề xuất migrate guidance
always-loaded còn lại thành skills + nested CLAUDE.md load-on-demand.

## 5. Anti-patterns (lỗi phổ biến người Việt hay mắc)

| Sai | Đúng |
|---|---|
| CLAUDE.md 500 dòng copy wiki | <200 dòng, front-load rule hay sai nhất lên đầu |
| Ghi "chạy test" chung chung | Ghi lệnh focused test chính xác |
| Ghi conventions của framework mặc định | Chỉ ghi cái **khác** default + lý do |
| Nhét deployment checklist dài vào CLAUDE.md | Tách thành skill `/deploy` (load khi cần) |
| Rule bị ignore hoài vẫn để trong CLAUDE.md | Nâng thành **hook** (Pre/PostToolUse) — xem bài 07 |

## 6. Bài tập

1. Chạy `/init` (hoặc `CLAUDE_CODE_NEW_INIT=1 /init` cho flow interactive), đọc file sinh ra, xóa 50%.
2. Thêm 3 verified commands (dev/test/lint) đã chạy thử trên máy.
3. Viết 5 rules ALWAYS/NEVER cụ thể của team bạn.
4. Chạy `/doctor`, làm theo mục CLAUDE.md trim.
