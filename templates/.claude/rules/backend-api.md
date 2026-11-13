---
paths: ["apps/api/**"]
---

# Backend API rules (áp dụng mọi file dưới `apps/api/`)

Hãy coi các rule dưới đây như luật giao thông của khu `apps/api/`: ai đi ngang qua (mọi file handler, controller) đều phải theo, để cả khu cùng một nếp.

- Error shape thống nhất `{ code, message, requestId }`. Ví dụ:
  > 📄 **Code ví dụ:** [`examples/01-backend-api-rules-ap-dung-moi-file-duoi.ts`](examples/01-backend-api-rules-ap-dung-moi-file-duoi.ts)
- Controller/handler mỏng: chỉ validate input → gọi service trong `packages/domain/` → map lỗi sang HTTP.
  Không query DB trực tiếp, không chứa if-else nghiệp vụ dài trong controller.
- Mỗi handler mới bắt buộc có test: 1 case happy + 1 case lỗi (401/403/400).
  Đặt cạnh source: `apps/api/src/routes/<ten>.test.ts`.
- Validate input ở boundary (biên nhận dữ liệu vào hệ thống) bằng schema (vd zod): handler nào thiếu `schema.parse(req.body)` là FAIL review.
- AuthZ trước logic: check `req.user` + quyền owner/role ngay đầu handler, trước mọi read/write.
- Không log secret/PII (`password`, `token`, `authorization` header). Log chỉ ghi `userId`, `requestId`, `code`.
- File handler >150 dòng thì tách service ra `packages/domain/src/<feature>.ts`.

> **Tóm gọn 1 câu:** Controller mỏng như lễ tân — chỉ nhận việc và chuyển đi; validate ở cửa, kiểm quyền trước logic, test phải có, và secret không bao giờ được in ra log.
