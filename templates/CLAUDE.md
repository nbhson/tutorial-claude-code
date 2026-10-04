# Project: <Ten> — one-liner mô tả

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
- TypeScript strict, không `any` trừ khi có comment ép kiểu
- API errors shape `{ code, message, requestId }`
- File >300 dòng thì tách

## Rules
- ALWAYS chạy focused tests sau khi sửa
- NEVER commit trực tiếp main, NEVER sửa `src/generated/`
- DB change → bắt buộc migration trong `db/migrations/`

---
Giữ file này <200 dòng. Procedures dài → `.claude/skills/`. Rules theo path → `.claude/rules/`.
Rule hay bị miss → nâng thành hook trong `.claude/settings.json`.
