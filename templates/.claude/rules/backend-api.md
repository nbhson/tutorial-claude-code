---
paths: ["apps/api/**"]
---

# Backend API rules (áp dụng mọi file dưới `apps/api/`)

- Error shape thống nhất `{ code, message, requestId }`. Ví dụ:
  ```ts
  // Luôn trả shape này, không trả string trần hay stack trace ra client
  return res.status(400).json({ code: "VALIDATION_ERROR", message: "email sai định dạng", requestId: req.id });
  ```
- Controller/handler mỏng: chỉ validate input → gọi service trong `packages/domain/` → map lỗi sang HTTP.
  Không query DB trực tiếp, không chứa if-else nghiệp vụ dài trong controller.
- Mỗi handler mới bắt buộc có test: 1 case happy + 1 case lỗi (401/403/400).
  Đặt cạnh source: `apps/api/src/routes/<ten>.test.ts`.
- Validate input ở boundary bằng schema (vd zod): handler nào thiếu `schema.parse(req.body)` là FAIL review.
- AuthZ trước logic: check `req.user` + quyền owner/role ngay đầu handler, trước mọi read/write.
- Không log secret/PII (`password`, `token`, `authorization` header). Log chỉ ghi `userId`, `requestId`, `code`.
- File handler >150 dòng thì tách service ra `packages/domain/src/<feature>.ts`.
