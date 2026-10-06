# Project: <Ten> — one-liner mô tả
<!-- SỬA DÒNG TRÊN ĐẦU TIÊN: tên repo + 1 câu repo này làm gì. VD: Project: shop-api — API bán hàng Node+Postgres -->

## Tech Stack
<!-- LIỆT KÊ NGẮN GỌN, model đọc để chọn lệnh + lib đúng. Chỉ ghi thứ đang dùng thật. -->
- <Framework>, <Lang + version>, <DB>, <lib chính>

## Commands (VERIFIED — chỉ ghi lệnh đã chạy thử)
<!-- QUAN TRỌNG NHẤT: 4 lệnh dưới phải chạy tay thành công rồi mới ghi. Sai 1 chữ là model chạy sai cả tháng. -->
- Dev: `pnpm dev`
- Build: `pnpm build`
- Test (focused): `pnpm --filter @acme/auth test`
- Full check: `pnpm lint && pnpm test && pnpm build`

## Architecture
<!-- BẢN ĐỒ 3-5 DÒNG: ai sở hữu gì, routes/models/tests nằm đâu. Đừng paste cả cây thư mục. -->
- `apps/api/` owns HTTP transport; `packages/domain/` không phụ thuộc framework
- Routes ở ..., models/types ở ..., tests ở ...

## Code Style (cụ thể, check được)
<!-- MỖI RULE PHẢI CHECK ĐƯỢC BẰNG MẮT HOẶC LINT. Rule chung chung ("code sạch") thì xóa. -->
- TypeScript strict, không `any` trừ khi có comment ép kiểu
- API errors shape `{ code, message, requestId }`
- File >300 dòng thì tách

## Rules
<!-- LUẬT CỨNG 3-5 DÒNG. Rule nào hay bị miss 2 lần thì nâng thành hook trong .claude/settings.json -->
- ALWAYS chạy focused tests sau khi sửa
- NEVER commit trực tiếp main, NEVER sửa `src/generated/`
- DB change → bắt buộc migration trong `db/migrations/`

---
<!-- GIỮ FILE NÀY <200 DÒNG. Procedures dài → .claude/skills/. Rules theo path → .claude/rules/. -->
Giữ file này <200 dòng. Procedures dài → `.claude/skills/`. Rules theo path → `.claude/rules/`.
Rule hay bị miss → nâng thành hook trong `.claude/settings.json`.
